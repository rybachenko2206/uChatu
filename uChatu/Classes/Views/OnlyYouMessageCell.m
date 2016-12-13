//
//  MessageCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/9/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//



#define TEXT_MAX_WIDTH 220
#define TEXT_FONT [UIFont fontWithName:@"HelveticaNeue" size:17.0f]
#define TOP_PADDING 17.0f


#import "NSString+Calculation.h"
#import "CDChatMessage.h"
#import "SharedDateFormatter.h"
#import "CDPhoto.h"
#import "AttachedImageView.h"
#import "uChatuMessage.h"
#import "UIImageView+WebCache.h"
#import "ImaginaryFriend.h"

#import "OnlyYouMessageCell.h"

@interface OnlyYouMessageCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addedPhotoWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addedPhotoHeightConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageImageView;
@property (weak, nonatomic) IBOutlet UIImageView *messageBubbleImageView;
@property (weak, nonatomic) IBOutlet AttachedImageView *attachedPhotoImageView;

@property (nonatomic, strong) CDChatMessage *chatMessage;

@end


@implementation OnlyYouMessageCell

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


- (void)setUchatuMessage:(UChatuMessage *)uchatuMessage {
    _uchatuMessage = uchatuMessage;
    
    NSURL *avaURL = [NSURL URLWithString:_uchatuMessage.ownerImaginaryFriend.avatar.url];
    [_avatarImageView sd_setImageWithURL:avaURL
                        placeholderImage:[UIImage imageNamed:@"cht_emptyAvatar_image"]];
    
    if (_uchatuMessage.cdChatMessage.thumbnailImageUrl) {
        _messageLabel.hidden = YES;
        _bubbleImageImageView.hidden = YES;
        _arrowImageView.hidden = YES;
        _attachedPhotoImageView.hidden = NO;
        [_attachedPhotoImageView sd_setImageWithURL:[NSURL URLWithString:_uchatuMessage.cdChatMessage.thumbnailImageUrl]
                                placeholderImage:[UIImage imageNamed:@"cht_bigPlaceholder_image"]];
        _addedPhotoHeightConstraint.constant = _uchatuMessage.thumbnailHeightInteger;
        _addedPhotoWidthConstraint.constant = _uchatuMessage.thumbnailWidthInteger;
    } else {
        _messageLabel.hidden = NO;
        _bubbleImageImageView.hidden = NO;
        _arrowImageView.hidden = NO;
        _attachedPhotoImageView.hidden = YES;
    }
    
    self.messageLabel.text = _uchatuMessage.cdChatMessage.messageText;
    self.createdAtLabel.text = [SharedDateFormatter stringCreatedAtFromDate:_uchatuMessage.cdChatMessage.createdAt];
}


#pragma mark - Interface methods

- (void)setContentWithCDChatMessage:(CDChatMessage*)message {
    self.chatMessage = message;
    if (message.photo) {
        _messageLabel.hidden = YES;
        _bubbleImageImageView.hidden = YES;
        _arrowImageView.hidden = YES;
        _attachedPhotoImageView.hidden = NO;
        _addedPhotoHeightConstraint.constant = [message.photo.thumbnailHeight floatValue];
        _addedPhotoWidthConstraint.constant = [message.photo.thumbnailWidth floatValue];
        _attachedPhotoImageView.image = [Utilities getImageWithName:message.photo.thumbnailPhotoName];
    } else {
        _messageLabel.hidden = NO;
        _bubbleImageImageView.hidden = NO;
        _arrowImageView.hidden = NO;
        _attachedPhotoImageView.hidden = YES;
        self.messageLabel.text = message.messageText;
        self.createdAtLabel.text = [SharedDateFormatter stringCreatedAtFromDate:message.createdAt];
    }
}


#pragma mark - Static methods

+(CGFloat) heightForCellWithMessage:(CDChatMessage *)message {
    CGFloat cellHeight = 0;
    if (message.photo) {
        cellHeight = [message.photo.thumbnailHeight floatValue] + TOP_PADDING;
    } else {
        CGFloat labelHeight = [self sizeForText:message.messageText].height;
        cellHeight = labelHeight + TOP_PADDING;
    }
    
    return cellHeight > DEFAULT_MESSAGE_CELL_HEIGHT ? cellHeight : DEFAULT_MESSAGE_CELL_HEIGHT;
}

+ (CGFloat)heightForCellWithUChatuMessage:(UChatuMessage *)message {
    CGFloat cellHeight = 0;
    if (message.cdChatMessage.thumbnailImageUrl) {
        cellHeight = message.thumbnailHeightInteger + TOP_PADDING;
    } else {
        CGFloat labelHeight = [self sizeForText:message.cdChatMessage.messageText].height;
        cellHeight = labelHeight + TOP_PADDING;
    }
    
    return cellHeight > DEFAULT_MESSAGE_CELL_HEIGHT ? cellHeight : DEFAULT_MESSAGE_CELL_HEIGHT;;
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


#pragma mark - Private methods

+(CGSize) sizeForText:(NSString *)text {
    CGSize size = [text usedSizeForMaxWidth:TEXT_MAX_WIDTH withFont:TEXT_FONT];
    size.height += 25;
    
    return size;
}


@end
