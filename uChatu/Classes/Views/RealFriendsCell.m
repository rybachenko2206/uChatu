//
//  RealFriendsCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "PFUser+Additions.h"
#import "UIImageView+WebCache.h"
#import "PrefixHeader.pch"

#import "RealFriendsCell.h"

@implementation RealFriendsCell

- (void)awakeFromNib {
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


#pragma mark - Setter methods

- (void)setIsOnline:(NSNumber *)isOnline {
    _isOnline = isOnline;
    switch ([_isOnline integerValue]) {
        case ChatOnlineStatusOnline:
            _onlineStatusImageView.image = [UIImage imageNamed:@"cht_onlinGreenPoint_image"];
            break;
        case ChatOnlineStatusOffline:
            _onlineStatusImageView.image = [UIImage imageNamed:@"rlf_offlineGrayPoint"];
            break;
        case ChatOnlineStatusBlocked:
            _onlineStatusImageView.image = [UIImage imageNamed:@"blocked_image"];
            break;
        default:
            break;
    }
}

- (void)setImaginaryFriend:(ImaginaryFriend *)imaginaryFriend {
    _imaginaryFriend = imaginaryFriend;
    
    _friendNameLabel.text = _imaginaryFriend.friendName;
    _realNameLabel.text = imaginaryFriend.realName;
    [_avatarImageView sd_setImageWithURL:[NSURL URLWithString:_imaginaryFriend.avatar.url]
                        placeholderImage:[UIImage imageNamed:@"cht_emptyAvatar_image"]];
}


-(void)setShouldHideUserName:(BOOL)shouldHideUserName {
    _shouldHideUserName = _realNameLabel.hidden = shouldHideUserName;
}

- (void)resetImaginaryFriend:(ImaginaryFriend *)imaginaryFriend {
    _imaginaryFriend = imaginaryFriend;
}

#pragma mark - Action methods

- (IBAction)infoButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(realFriendSCellInfoButtonWasPressed:)]) {
        [self.delegate realFriendSCellInfoButtonWasPressed:self];
    }
}


#pragma mark - Static methods

+ (CGFloat)heightForCell {
    return 75.0f;
}

@end
