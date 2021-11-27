//
//  View.h
//  MessageQueue
//
//  Created by cmw on 2020/9/23.
//  Copyright © 2020 com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface View : UIView

@property (nonatomic, strong) void (^clickSerial)(NSInteger);
@property (nonatomic, strong) void (^clickSerialWithAck)(NSInteger);
@property (nonatomic, strong) void (^clickConcurrent)(NSInteger);
@property (nonatomic, strong) void (^clickConcurrentWithAck)(NSInteger);

@end

NS_ASSUME_NONNULL_END
