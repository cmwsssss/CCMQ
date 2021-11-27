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

@property (nonatomic, strong) NSString *port;
@property (nonatomic, strong) void (^subscribe)(CCMQMessage *);

@end

NS_ASSUME_NONNULL_END
