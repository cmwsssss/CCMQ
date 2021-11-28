//
//  MessageSubscriber.h
//  MessageQueue
//
//  Created by cmw on 2020/9/18.
//  Copyright © 2020 com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCMQMessage.h"
NS_ASSUME_NONNULL_BEGIN

@interface CCMQMessageSubscriber : NSObject
/**
 @brief The subscriber's port, which is used as a unique identifier for the subscriber (订阅者的端口号，用来作为订阅者的唯一标识)
 */
@property (nonatomic, strong) NSString *port;
/**
 @brief A block used to receiving messages, which subscribers can receive messages (接收消息的闭包，订阅者可以通过该闭包接收消息)
 */
@property (nonatomic, strong) void (^subscribe)(CCMQMessage *);

@end

NS_ASSUME_NONNULL_END
