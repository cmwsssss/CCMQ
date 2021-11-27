//
//  MessageQueue.m
//  MessageQueue
//
//  Created by cmw on 2020/9/18.
//  Copyright © 2020 com. All rights reserved.
//

#import "CCMQMessageQueue.h"
#import <sys/mman.h>
#import "CCMQMMAPFileManager.h"
@interface CCMQMessageQueue ()

@property (nonatomic, strong) NSMutableDictionary *subscriberMap;
@property (nonatomic, strong) NSMutableDictionary *waitAckTimeMap;
@property (nonatomic, assign) CCMQMessageQueueType type;
@property (nonatomic, strong) NSThread *flushThread;
@property (nonatomic, strong) dispatch_semaphore_t mmapSemaphore;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_semaphore_t waitAckTimeMapSemaphore;
@property (nonatomic, strong) dispatch_source_t loopTimer;
@end

@implementation CCMQMessageQueue

- (NSThread *)flushThread {
    if (!_flushThread) {
        _flushThread = [[NSThread alloc] initWithTarget:self selector:@selector(createRunloop) object:nil];
        [_flushThread start];
    }
    
    return _flushThread;
}

- (void)createRunloop {
    CFRunLoopSourceContext context = {0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};
    CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorMalloc, 0, &context);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    
    BOOL runAlways = YES;
    while (runAlways) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, DISPATCH_TIME_FOREVER, true);
    }
    
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    CFRelease(source);
}

- (instancetype)initWithType:(CCMQMessageQueueType)type tag:(NSString *)tag {
    self = [super init];
    if (self) {
        self.waitAckTimeMap = [[NSMutableDictionary alloc] init];
        self.subscriberMap = [[NSMutableDictionary alloc] init];
        self.type = type;
        self.tag = tag;
        self.timeout = 1;
        self.maxConcurrentCount = 5;
        self.mmapSemaphore = dispatch_semaphore_create(1);
        self.waitAckTimeMapSemaphore = dispatch_semaphore_create(1);
        self.serialQueue = dispatch_queue_create(tag.UTF8String, DISPATCH_QUEUE_SERIAL);
        self.loopTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        dispatch_source_set_timer(self.loopTimer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(self.loopTimer, ^{
            [self performSelector:@selector(flushMessage) onThread:self.flushThread withObject:nil waitUntilDone:NO];
        });
        dispatch_resume(self.loopTimer);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flushNextMessage:) name:FLUSH_NEXT_MESSAGE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageDidRemoved:) name:MESSAGE_DID_REMOVED object:nil];
        [CCMQMMAPFileManager initializeWithQueue:self];
    }
    return self;
}

- (void)addSubscriber:(CCMQMessageSubscriber *)subscriber {
    [self.subscriberMap setObject:subscriber forKey:subscriber.port];
    [self performSelector:@selector(flushMessage) onThread:self.flushThread withObject:nil waitUntilDone:NO];
}

- (void)removeSubscriber:(CCMQMessageSubscriber *)subscriber {
    [self.subscriberMap removeObjectForKey:subscriber.port];
}

- (void)publish:(CCMQMessage *)message {
    message.uuid = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSMutableArray *ports = [[NSMutableArray alloc] init];
    [self.subscriberMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [ports addObject:key];
    }];
    message.ackPorts = [NSArray arrayWithArray:ports];
    [CCMQMMAPFileManager publishToMMAPFile:message queue:self];
    [self performSelector:@selector(flushMessage) onThread:self.flushThread withObject:nil waitUntilDone:NO];
}

- (void)flushNextMessage:(NSNotification *)noti {
    if (noti.object == self) {
        [self performSelector:@selector(flushMessage) onThread:self.flushThread withObject:nil waitUntilDone:NO];
    }
}

- (void)messageDidRemoved:(NSNotification *)noti {
    dispatch_async(self.serialQueue, ^{
        CCMQMessage *message = noti.object;
        dispatch_semaphore_wait(self.waitAckTimeMapSemaphore, DISPATCH_TIME_FOREVER);
        [self.waitAckTimeMap removeObjectForKey:message.uuid];
        dispatch_semaphore_signal(self.waitAckTimeMapSemaphore);
    });
}

- (void)flushMessageSerial {
    dispatch_async(self.serialQueue, ^{
        NSDate *now = [NSDate date];
        NSArray <CCMQMessage *> *needFlushMessages = [CCMQMMAPFileManager getMessageToIndex:1 queue:self];
        [needFlushMessages enumerateObjectsUsingBlock:^(CCMQMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableDictionary *waitAckTime = [self.waitAckTimeMap objectForKey:obj.uuid];
            if (!waitAckTime) {
                waitAckTime = [[NSMutableDictionary alloc] init];
                [self.waitAckTimeMap setObject:waitAckTime forKey:obj.uuid];
            }
            NSArray <NSString *> *needAckPorts = [CCMQMMAPFileManager portsNotReceviedAck:obj queue:self];
            [needAckPorts enumerateObjectsUsingBlock:^(NSString * _Nonnull port, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDate *date = [waitAckTime objectForKey:port];
                if ([now timeIntervalSinceDate:date] > self.timeout || !date) {
                    CCMQMessageSubscriber *subscriber = [self.subscriberMap objectForKey:port];
                    if (subscriber.subscribe) {
                        subscriber.subscribe(obj);
                    }
                    if (!self.needAck) {
                        [CCMQMMAPFileManager finishMessage:obj port:port queue:self];
                    }
                    [waitAckTime setObject:now forKey:port];
                }
            }];
        }];
    });
}

- (void)flushMessageConcurrent {
    dispatch_async(self.serialQueue, ^{
        NSDate *now = [NSDate date];
        NSArray <CCMQMessage *> *needFlushMessages = [CCMQMMAPFileManager getMessageToIndex:self.maxConcurrentCount queue:self];
        [needFlushMessages enumerateObjectsUsingBlock:^(CCMQMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                dispatch_semaphore_wait(self.waitAckTimeMapSemaphore, DISPATCH_TIME_FOREVER);
                NSMutableDictionary *waitAckTime = [self.waitAckTimeMap objectForKey:obj.uuid];
                if (!waitAckTime) {
                    waitAckTime = [[NSMutableDictionary alloc] init];
                    [self.waitAckTimeMap setObject:waitAckTime forKey:obj.uuid];
                }
                dispatch_semaphore_signal(self.waitAckTimeMapSemaphore);
                NSArray <NSString *> *needAckPorts = [CCMQMMAPFileManager portsNotReceviedAck:obj queue:self];
                [needAckPorts enumerateObjectsUsingBlock:^(NSString * _Nonnull port, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSDate *date = [waitAckTime objectForKey:port];
                    if ([now timeIntervalSinceDate:date] > self.timeout || !date) {
                        [waitAckTime setObject:now forKey:port];
                        CCMQMessageSubscriber *subscriber = [self.subscriberMap objectForKey:port];
                        if (subscriber.subscribe) {
                            subscriber.subscribe(obj);
                        }
                        if (!self.needAck) {
                            [CCMQMMAPFileManager finishMessage:obj port:port queue:self];
                        }
                    }
                }];
            });
        }];
    });
}

- (void)flushMessage {
    if (self.type == CCMQMessageQueueTypeSerial) {
        [self flushMessageSerial];
    } else  {
        [self flushMessageConcurrent];
    }
}

- (void)finishMessage:(CCMQMessage *)message port:(nonnull NSString *)port {
    [CCMQMMAPFileManager finishMessage:message port:port queue:self];
}

- (void)MMAPFileLockLock {
    dispatch_semaphore_wait(self.mmapSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)MMAPFileLockUnLock {
    dispatch_semaphore_signal(self.mmapSemaphore);
}

- (void)dealloc {
    dispatch_source_cancel(self.loopTimer);
    self.loopTimer = nil;
}

@end
