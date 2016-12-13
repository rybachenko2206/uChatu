//
//  FriendChatCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/10/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


@class CDChatMessage;
@class CDImaginaryFriend;
@class AttachedImageView;
@class UChatuMessage;

#import "RoundedImageView.h"
#import "PrefixHeader.pch"


@interface FriendMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *onlineImageView;
@property (weak, nonatomic) IBOutlet RoundedImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *messageTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *senderNameLabel;

@property (nonatomic, strong) UChatuMessage *uchatuMessage;
@property (nonatomic, strong) NSNumber *isOnline;

+ (CGFloat)heightForCellWithUChatuMessage:(UChatuMessage *)message;

+ (CGFloat)heightForCellWithMessage:(CDChatMessage *)message;
- (void)setContentWithCDChatMessage:(CDChatMessage *)message imaginaryFriend:(CDImaginaryFriend *)imFriend;

@end
