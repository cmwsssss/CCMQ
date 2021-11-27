//
//  MessageQueue.h
//  MessageQueue
//
//  Created by cmw on 2020/9/18.
//  Copyright © 2020 com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCMQMessageSubscriber.h"
#import "CCMQMessage.h"

#define FLUSH_NEXT_MESSAGE @"FLUSH_NEXT_MESSAGE"
#define MESSAGE_DID_REMOVED @"MESSAGE_DID_REMOVED"


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CCMQMessageQueueType) {
    CCMQMessageQueueTypeSerial,
    CCMQMessageQueueTypeConcurrent
};

@interface CCMQMessageQueue : NSObject

@property (nonatomic, assign)BOOL needAck;
@property (nonatomic, assign)NSInteger maxConcurrentCount;
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, assign) NSTimeInterval timeout;

- (void)MMAPFileLockLock;
- (void)MMAPFileLockUnLock;
- (instancetype)initWithType:(CCMQMessageQueueType)type tag:(NSString *)tag;
- (void)addSubscriber:(CCMQMessageSubscriber *)subscriber;
- (void)finishMessage:(CCMQMessage *)message port:(NSString *)port;
- (void)publish:(CCMQMessage *)message;
- (void)removeSubscriber:(CCMQMessageSubscriber *)subscriber;

@end

NS_ASSUME_NONNULL_END
