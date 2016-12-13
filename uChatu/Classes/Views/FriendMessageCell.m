//
//  FriendChatCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/10/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#define TEXT_MAX_WIDTH 210
#define TEXT_FONT [UIFont fontWithName:@"HelveticaNeue" size:17.0f]
#define TOP_PADDING 17.0f


#import "NSString+Calculation.h"
#import "SharedDateFormatter.h"
#import "CDChatMessage.h"
#import "CDImaginaryFriend.h"
#import "Utilities.h"
#import "AuthorizationManager.h"
#import "CDPhoto.h"
#import "AttachedImageView.h"
#import "uChatuMessage.h"
#import "ImaginaryFriend.h"
#import "UIImageView+WebCache.h"

#import "FriendMessageCell.h"


@interface FriendMessageCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachedPhotoWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachedPhotoHeightConstraint;

@property (weak, nonatomic) IBOutlet AttachedImageView *attachedPhotoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

@property (nonatomic, strong) CDChatMessage *chatMessage;

@end

@implementation FriendMessageCell

- (void)awakeFromNib {
    
    UITapGestureRecognizer *tapGesRec = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(imageWasTapped)];
    tapGesRec.numberOfTapsRequired = 1;
    tapGesRec.numberOfTouchesRequired = 1;
    [self.attachedPhotoImageView addGestureRecognizer:tapGesRec];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setUchatuMessage:(UChatuMessage *)uchatuMessage {
    _uchatuMessage = uchatuMessage;
    
    [_avatarImageView sd_setImageWithURL:[NSURL URLWithString:_uchatuMessage.ownerImaginaryFriend.avatar.url]
                        placeholderImage:[UIImage imageNamed:@"cht_emptyAvatar_image"]];
    self.messageTextLabel.text = _uchatuMessage.cdChatMessage.messageText;
    self.createdAtLabel.text = [SharedDateFormatter stringCreatedAtFromDate:_uchatuMessage.cdChatMessage.createdAt];
    self.senderNameLabel.text = _uchatuMessage.ownerImaginaryFriend.friendName;
    if (_uchatuMessage.cdChatMessage.thumbnailImageUrl) {
        _attachedPhotoImageView.hidden = NO;
        _messageTextLabel.hidden = YES;
        _arrowImageView.hidden = YES;
        _bubbleImageView.hidden = YES;
        [_attachedPhotoImageView sd_setImageWithURL:[NSURL URLWithString:_uchatuMessage.cdChatMessage.thumbnailImageUrl]
                                   placeholderImage:[UIImage imageNamed:@"cht_bigPlaceholder_image"]];
        _attachedPhotoHeightConstraint.constant = _uchatuMessage.thumbnailHeightInteger;
        _attachedPhotoWidthConstraint.constant = _uchatuMessage.thumbnailWidthInteger;
    } else {
        _messageTextLabel.hidden = NO;
        _bubbleImageView.hidden = NO;
        _arrowImageView.hidden = NO;
        _attachedPhotoImageView.hidden = YES;
    }
}

- (void)setIsOnline:(NSNumber *)isOnline {
    _isOnline = isOnline;
    _onlineImageView.image = [_isOnline boolValue] ? [UIImage imageNamed:@"cht_onlinGreenPoint_image"] : [UIImage imageNamed:@"rlf_offlineGrayPoint"];
}



#pragma mark - Interface methods

- (void)setContentWithCDChatMessage:(CDChatMessage *)message imaginaryFriend:(CDImaginaryFriend *)imFriend {
    self.chatMessage = message;
    CDUser *currUser = [AuthorizationManager sharedInstance].currentCDUser;
    if ([imFriend.lastOpenedChatAsUser boolValue]) {
        UIImage *image = [Utilities getImageWithName:imFriend.avatarImageName];
        if (!image) {
            image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
        }
        self.avatarImageView.image = image;
        
        if ([message.messageType integerValue] == MessageTypeFriendToUser) {
            self.senderNameLabel.text = imFriend.friendName;
        } else {
            self.senderNameLabel.text = currUser.userName.length ? currUser.userName : @"YOU";
        }
        
    } else {
        UIImage *image = [Utilities getImageWithName:currUser.avatarImageName];
        if (!image) {
            image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
        }
        self.avatarImageView.image = image;
        if ([message.messageType integerValue] == MessageTypeUserToFriend) {
            self.senderNameLabel.text = currUser.userName;
        } else {
            self.senderNameLabel.text = imFriend.friendName;
        }
    }
    
    if (message.photo) {
        _attachedPhotoImageView.hidden = NO;
        _messageTextLabel.hidden = YES;
        _arrowImageView.hidden = YES;
        _bubbleImageView.hidden = YES;
        _attachedPhotoImageView.image =  [Utilities getImageWithName:message.photo.thumbnailPhotoName];
        _attachedPhotoHeightConstraint.constant = [message.photo.thumbnailHeight floatValue];
        _attachedPhotoWidthConstraint.constant = [message.photo.thumbnailWidth floatValue];
    } else {
        _attachedPhotoImageView.hidden = YES;
        _messageTextLabel.hidden = NO;
        _arrowImageView.hidden = NO;
        _bubbleImageView.hidden = NO;
        self.messageTextLabel.text = message.messageText;
        self.createdAtLabel.text = [SharedDateFormatter stringCreatedAtFromDate:message.createdAt];
    }
}


#pragma mark - Action methods

- (void)imageWasTapped {
    if (self.chatMessage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAttachedImageWasTappedNotification
                                                            object:self.chatMessage.photo];
    }
    if (self.uchatuMessage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAttachedImageWasTappedNotification
                                                            object:self.uchatuMessage.cdChatMessage.fullImageUrl];
    }
}


#pragma mark - Static methods

+(CGFloat) heightForCellWithMessage:(CDChatMessage *)message {
    CGFloat cellHeight = 0;
    if (message.photo) {
        cellHeight = [message.photo.thumbnailHeight floatValue] + TOP_PADDING + 4;
    } else {
        CGFloat labelHeight = [self sizeForText:message.messageText].height;
        cellHeight = labelHeight + TOP_PADDING;
    }
    
    return cellHeight > DEFAULT_MESSAGE_CELL_HEIGHT ? cellHeight : DEFAULT_MESSAGE_CELL_HEIGHT;;
}

+ (CGFloat)heightForCellWithUChatuMessage:(UChatuMessage *)message {
    CGFloat cellHeight = 0;
    if (message.cdChatMessage.thumbnailImageUrl) {
        cellHeight = message.thumbnailHeightInteger + TOP_PADDING + 4;
    } else {
        CGFloat labelHeight = [self sizeForText:message.cdChatMessage.messageText].height;
        cellHeight = labelHeight + TOP_PADDING;
    }
    
    return cellHeight > DEFAULT_MESSAGE_CELL_HEIGHT ? cellHeight : DEFAULT_MESSAGE_CELL_HEIGHT;;
}


#pragma mark - Private methods

+(CGSize) sizeForText:(NSString *)text {
    if (!text || [text isEqual:[NSNull null]]) {
        return CGSizeZero;
    }
    CGSize size = [text usedSizeForMaxWidth:TEXT_MAX_WIDTH withFont:TEXT_FONT];
    size.height += 25;
    
    return size;
}

@end
