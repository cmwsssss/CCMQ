//
//  MMAPFileManager.h
//  MessageQueue
//
//  Created by cmw on 2020/9/21.
//  Copyright © 2020 com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCMQMessage.h"
#import "CCMQMessageQueue.h"
NS_ASSUME_NONNULL_BEGIN

@interface CCMQMMAPFileManager : NSObject

+ (void)initializeWithQueue:(CCMQMessageQueue *)queue;
+ (void)publishToMMAPFile:(CCMQMessage *)message queue:(CCMQMessageQueue *)queue;
+ (CCMQMessage *)getMessageWithUUID:(NSString *)uuid queue:(CCMQMessageQueue *)queue;
+ (NSArray <NSString *> *)portsNotReceviedAck:(CCMQMessage *)message queue:(CCMQMessageQueue *)queue;
+ (void)finishMessage:(CCMQMessage *)message port:(NSString *)port queue:(CCMQMessageQueue *)queue;
+ (NSArray <CCMQMessage*> *)getMessageToIndex:(NSInteger)index queue:(CCMQMessageQueue *)queue;
@end

NS_ASSUME_NONNULL_END
