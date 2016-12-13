//
//  ChatTitleView.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#define paddingNavBar 106
#define paddingOnlineView 20

#include "PrefixHeader.pch"
#import "NSString+Calculation.h"

#import "ChatTitleView.h"

@interface ChatTitleView ()

@property (weak, nonatomic) UIImageView *onlineView;
@property (strong, nonatomic) UILabel *titleLabel;

@end


@implementation ChatTitleView


#pragma mark Instance initialization

- (instancetype)initWithTitle:(NSString *)title isOnline:(BOOL)isOnline isBlocked:(BOOL)isBlocked {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    CGFloat labelWidth = [ChatTitleView labelWidthForText:title];
    CGRect labelFrame = CGRectMake(20, 5, labelWidth, 21);
    self.frame = CGRectMake(0, 0, labelWidth + paddingOnlineView, 21);
    
    self.titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [self.titleLabel setFont:NAVIGATION_BAR_TITLE_FONT];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.text = title;
    self.titleLabel.textColor = SAVE_BUTTON_ACTIVE_COLOR;
    [self addSubview:self.titleLabel];
    
    UIImageView *onlineView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 12, 10, 10)];
    onlineView.image = isOnline ? [UIImage imageNamed:@"cht_onlinGreenPoint_image"] : [UIImage imageNamed:@"rlf_offlineGrayPoint"];
    
    if (isBlocked) {
        onlineView.image = [UIImage imageNamed:@"blocked_image"];
    }
    
    [self addSubview:onlineView];
    
    
    return self;
}


#pragma mark - Private methods

+ (CGFloat)labelWidthForText:(NSString *)text {
    CGFloat maxWidth = SCREEN_SIZE.width - paddingNavBar - paddingOnlineView;
    
    CGSize size = [text usedSizeForMaxWidth:maxWidth
                                   withFont:NAVIGATION_BAR_TITLE_FONT];
    
    return size.width;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
