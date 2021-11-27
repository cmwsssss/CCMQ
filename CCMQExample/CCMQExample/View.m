//
//  View.m
//  MessageQueue
//
//  Created by cmw on 2020/9/23.
//  Copyright © 2020 com. All rights reserved.
//

#import "View.h"

@interface View ()


@property (nonatomic, strong) UIButton *buttonSerial;
@property (nonatomic, strong) UIButton *buttonSerialAck;
@property (nonatomic, strong) UIButton *buttonConcurrent;
@property (nonatomic, strong) UIButton *buttonConcurrentAck;
@property (nonatomic, strong) UITextField *textField;


@end

@implementation View

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 20, 200, 40)];
        _textField.placeholder = @"请输入发送的消息条数";
        _textField.keyboardType = UIKeyboardTypePhonePad;
        [self addSubview:_textField];
    }
    return _textField;
}

- (UIButton *)buttonSerial {
    if (!_buttonSerial) {
        _buttonSerial = [[UIButton alloc] init];
        [_buttonSerial setTitle:@"串行发送消息" forState:UIControlStateNormal];
        [_buttonSerial setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_buttonSerial sizeToFit];
        [_buttonSerial addTarget:self action:@selector(onClickButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_buttonSerial];
    }
    return _buttonSerial;
}

- (UIButton *)buttonSerialAck {
    if (!_buttonSerialAck) {
        _buttonSerialAck = [[UIButton alloc] init];
        [_buttonSerialAck setTitle:@"串行发送消息(回执时间0.5秒)" forState:UIControlStateNormal];
        [_buttonSerialAck setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_buttonSerialAck sizeToFit];
        [_buttonSerialAck addTarget:self action:@selector(onClickButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_buttonSerialAck];
    }
    return _buttonSerialAck;
}

- (UIButton *)buttonConcurrent {
    if (!_buttonConcurrent) {
        _buttonConcurrent = [[UIButton alloc] init];
        [_buttonConcurrent setTitle:@"并行发送消息" forState:UIControlStateNormal];
        [_buttonConcurrent setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_buttonConcurrent sizeToFit];
        [_buttonConcurrent addTarget:self action:@selector(onClickButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_buttonConcurrent];
    }
    return _buttonConcurrent;
}

- (UIButton *)buttonConcurrentAck {
    if (!_buttonConcurrentAck) {
        _buttonConcurrentAck = [[UIButton alloc] init];
        [_buttonConcurrentAck setTitle:@"并行发送消息(回执时间0.5秒)" forState:UIControlStateNormal];
        [_buttonConcurrentAck setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_buttonConcurrentAck sizeToFit];
        [_buttonConcurrentAck addTarget:self action:@selector(onClickButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_buttonConcurrentAck];
    }
    return _buttonConcurrentAck;
}

- (void)onClickButton:(UIButton *)button {
    NSInteger count = 1000;
    self.userInteractionEnabled = NO;
    if (self.textField.text.length > 0) {
        count = [self.textField.text integerValue];
    }
    if (button == self.buttonSerial) {
        self.clickSerial(count);
    } else if (button == self.buttonSerialAck) {
        self.clickSerialWithAck(count);
    } else if (button == self.buttonConcurrent) {
        self.clickConcurrent(count);
    } else if (button == self.buttonConcurrentAck) {
        self.clickConcurrentWithAck(count);
    }
}

- (void)layoutSubviews {
    self.backgroundColor = [UIColor whiteColor];
    self.textField.frame = CGRectMake(40, 40, 200, 40);
    self.buttonSerial.frame = CGRectMake(20, CGRectGetMaxY(self.textField.frame), 300, 40);
    self.buttonSerialAck.frame = CGRectMake(20, CGRectGetMaxY(self.buttonSerial.frame), 300, 40);
    self.buttonConcurrent.frame = CGRectMake(20, CGRectGetMaxY(self.buttonSerialAck.frame), 300, 40);
    self.buttonConcurrentAck.frame = CGRectMake(20, CGRectGetMaxY(self.buttonConcurrent.frame), 300, 40);
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
