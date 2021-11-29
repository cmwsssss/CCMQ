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

/**
 @brief Whether messages in this queue are automatically reply ACK (该队列的消息是否是自动ACK)
 @discussion If needAck == NO, Subscribers need to reply ACK Manually, and MQ will resend the message for ports that do not receive an ACK (手动ACK则需要订阅者自己进行ACK回调，MQ会对未收到ACK的port进行消息超时重发)
 */
@property (nonatomic, assign)BOOL needAck;
/**
 @brief Maximum number of concurrent messages in a concurrent queue (并行队列的最大并发消息数量)
 */
@property (nonatomic, assign)NSInteger maxConcurrentCount;
/**
 @brief Tag of MessageQueue (队列的标识符)
 */
@property (nonatomic, strong) NSString *tag;
/**
 @brief Timeout for message delivery, If no ACK is received after that time, the message will be automatically resend (消息发送的超时时间，超过该时间未收到ACK，则会自动进行消息重发)
 */
@property (nonatomic, assign) NSTimeInterval timeout;

- (void)MMAPFileLockLock;
- (void)MMAPFileLockUnLock;
/**
 
 @brief Initialization method of the queue (队列的初始化方法)
 @param type CCMQMessageQueueTypeSerial is serial, CCMQMessageQueueTypeConcurrent is concurrent (CCMQMessageQueueTypeSerial 为串行队列，CCMQMessageQueueTypeConcurrent 为串行队列)
 @param tag Tag of MessageQueue (队列的标识符)
 @return a CCMQMessageQueue object
 */
- (instancetype)initWithType:(CCMQMessageQueueType)type tag:(NSString *)tag;
/**
 @brief Add subscribers, which can receive messages sent by the queue (添加订阅者，订阅者可以收到队列发送的消息)
 @param subscriber a CCMQMessageSubscriber object, Can receive messages sent by the queue (CCMQMessageSubscriber对象，用于接收消息)
 */
- (void)addSubscriber:(CCMQMessageSubscriber *)subscriber;
/**
 @brief Manual reply ACK to incoming messages (对收到的消息进行手动ACK回复)
 @param message Messages received by subscribers (订阅者收到的消息)
 @param port Subscribers' port (订阅者的端口号)
 */
- (void)finishMessage:(CCMQMessage *)message port:(NSString *)port;
/**
 @brief Sending messages via message queue (通过消息队列发送消息)
 @param message Messages to be sent via message queue (需要通过MQ发送的消息)
 */
- (void)publish:(CCMQMessage *)message;
/**
 @brief remove subscriber from message queue(将订阅者从消息队列移除)
 @param subscriber a CCMQMessageSubscriber object (订阅者对象)
 */
- (void)removeSubscriber:(CCMQMessageSubscriber *)subscriber;

/**
 @brief Get CCMQMessageQueue object by tag (通过tag获取CCMQMessageQueue对象)
 @discussion If the queue does not exist, a queue will be created, and if it exists, an instance of the queue will be return (如果队列不存在，则会创建一个队列，如果存在，则会将获取该队列实例)
 @param tag Tag of MessageQueue (队列的标识符)
 @param type The type of the queue, if the queue does not exist, the queue will be created based on this type
 (队列的类型，如果队列不存在，则会根据该类型创建队列)
 @return a CCMQMessageQueue object
 */
+ (CCMQMessageQueue *)getQueueWithTag:(NSString *)tag type:(CCMQMessageQueueType)type;

@end

NS_ASSUME_NONNULL_END
