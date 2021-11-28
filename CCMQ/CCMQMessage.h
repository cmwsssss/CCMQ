//
//  CCMQMessage.h
//  CCMQ
//
//  Created by cmw on 2021/11/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCMQMessage : NSObject
/**
 @brief Message that need to be sent, subscribers will receive this message (需要发送的消息，订阅者会收到消息)
 */
@property (nonatomic, strong) NSString *message;
/**
 @brief The Unique id of the message (消息的唯一id)
 */
@property (nonatomic, strong) NSString *uuid;
/**
 @brief Wait ack ports (该条消息需要ACK的端口)
 
 @discussion The message is sent successfully only after all ports have sent ACK, otherwise the message queue will send the message again to the port that has not senddt ACK after the timeout. (端口全部ACK之后才代表该条消息发送成功，否则MQ会在超时之后向尚未ACK的端口再次发送消息)
 */
@property (nonatomic, strong) NSArray <NSString *> *ackPorts;

@end

NS_ASSUME_NONNULL_END
