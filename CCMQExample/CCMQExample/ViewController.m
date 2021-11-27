//
//  ViewController.m
//  CCMQExample
//
//  Created by cmw on 2021/11/27.
//

#import "ViewController.h"
#import "View.h"
#import <CCMQ.h>
@interface ViewController ()

@property (nonatomic, strong) CCMQMessageQueue *serialQueue;
@property (nonatomic, strong) CCMQMessageQueue *concurrentQueue;
@property (nonatomic, strong) View *view;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) BOOL testAck;

@end

@implementation ViewController

- (void)loadView {
    self.view = [[View alloc] init];
}

- (CCMQMessageQueue *)serialQueue {
    if (!_serialQueue) {
        _serialQueue = [[CCMQMessageQueue alloc] initWithType:CCMQMessageQueueTypeSerial tag:@"serial"];
    }
    return _serialQueue;
}

- (CCMQMessageQueue *)concurrentQueue {
    if (!_concurrentQueue) {
        _concurrentQueue = [[CCMQMessageQueue alloc] initWithType:CCMQMessageQueueTypeConcurrent tag:@"concurrent"];
        _concurrentQueue.maxConcurrentCount = 5;
    }
    return _concurrentQueue;
}

- (void)publishSerialMessage:(NSInteger)count {
    self.count = count;
    for (NSInteger i = 1; i <= count; i++) {
        CCMQMessage *message = [[CCMQMessage alloc] init];
        message.message = [NSString stringWithFormat:@"%ld", i];
        [self.serialQueue publish:message];
    }
}

- (void)publishConcurrentMessage:(NSInteger)count {
    self.count = count;
    for (NSInteger i = 1; i <= count; i++) {
        CCMQMessage *message = [[CCMQMessage alloc] init];
        message.message = [NSString stringWithFormat:@"%ld", i];
        [self.concurrentQueue publish:message];
    }
}

- (void)onSubscribe {
    __weak typeof(self) weakSelf = self;
    CCMQMessageSubscriber *subSerial = [[CCMQMessageSubscriber alloc] init];
    subSerial.port = @"sub1";
    subSerial.subscribe = ^(CCMQMessage * _Nonnull message) {
        if(weakSelf.testAck) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (message.message.integerValue == self.count) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.view.userInteractionEnabled = YES;
                    });
                }
                NSLog(@"串行队列ack第%@条消息", message.message);
                [weakSelf.serialQueue finishMessage:message port:@"sub1"];
            });
        } else {
            if (message.message.integerValue == self.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.view.userInteractionEnabled = YES;
                });
            }
            NSLog(@"串行队列第%@条消息", message.message);
        }
    };
    [self.serialQueue addSubscriber:subSerial];
    
    CCMQMessageSubscriber *subConcurrent = [[CCMQMessageSubscriber alloc] init];
    subConcurrent.port = @"sub2";
    subConcurrent.subscribe = ^(CCMQMessage * _Nonnull message) {
        if(weakSelf.testAck) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (message.message.integerValue == self.count) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.view.userInteractionEnabled = YES;
                    });
                }
                NSLog(@"并行队列ack第%@条消息", message.message);
                [weakSelf.concurrentQueue finishMessage:message port:@"sub2"];
            });
        } else {
            if (message.message.integerValue == self.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.view.userInteractionEnabled = YES;
                });
            }
            NSLog(@"并行队列第%@条消息", message.message);
        }
    };
    [self.concurrentQueue addSubscriber:subConcurrent];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    self.view.clickSerial = ^(NSInteger count) {
        weakSelf.serialQueue.needAck = NO;
        weakSelf.testAck = NO;
        [weakSelf publishSerialMessage:count];
    };
    self.view.clickSerialWithAck = ^(NSInteger count) {
        weakSelf.serialQueue.needAck = YES;
        weakSelf.testAck = YES;
        [weakSelf publishSerialMessage:count];
    };
    self.view.clickConcurrent = ^(NSInteger count) {
        weakSelf.concurrentQueue.needAck = NO;
        weakSelf.testAck = NO;
        [weakSelf publishConcurrentMessage:count];
    };
    self.view.clickConcurrentWithAck = ^(NSInteger count) {
        weakSelf.concurrentQueue.needAck = YES;
        weakSelf.testAck = YES;
        [weakSelf publishConcurrentMessage:count];
    };
    
    [self onSubscribe];
    
    
    // Do any additional setup after loading the view.
}



@end
