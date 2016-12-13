//
//  MessageCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/9/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


@class CDChatMessage;
@class AttachedImageView;
@class UChatuMessage;

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RoundedImageView.h"

@interface OnlyYouMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkmarkRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageBubbleImageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageBubbleImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdAtLabel;
@property (weak, nonatomic) IBOutlet RoundedImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *onlineImageView;

@property (nonatomic, strong) UChatuMessage *uchatuMessage;

+ (CGFloat)heightForCellWithUChatuMessage:(UChatuMessage *)message;
+ (CGFloat)heightForCellWithMessage:(CDChatMessage *)message;
- (void)setContentWithCDChatMessage:(CDChatMessage*)message;


@end
