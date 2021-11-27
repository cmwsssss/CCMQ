//
//  CCMQMessage.h
//  CCMQ
//
//  Created by cmw on 2021/11/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCMQMessage : NSObject

@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSArray <NSString *> *ackPorts;

@end

NS_ASSUME_NONNULL_END
