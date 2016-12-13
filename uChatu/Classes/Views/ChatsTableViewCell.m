//
//  ChatsTableViewCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/1/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import "Utilities.h"
#import "AuthorizationManager.h"
#import "UIImageView+WebCache.h"

#import "ChatsTableViewCell.h"


@implementation ChatsTableViewCell

- (void)awakeFromNib {
    NSNotificationCenter *nCenter = [NSNotificationCenter defaultCenter];
    
    [nCenter addObserver:self
                selector:@selector(shouldShowLeftAccessoryButton:)
                    name:kChatsTableViewCellShouldShowLeftAccessoryButtonsNotification
                  object:nil];
    
    [nCenter addObserver:self
                selector:@selector(shouldHideLeftAccessoryButton:)
                    name:kChatsTableViewCellShouldHideLeftAccessoryButtonsNotification
                  object:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setIsOnline:(NSNumber *)isOnline {
    if (_chatRoom.wasDeactivatedBoolValue) {
        return;
    }
    _isOnline = isOnline;
    if ([_isOnline integerValue] == ChatOnlineStatusOnline) {
        _onlineImageView.image = [UIImage imageNamed:@"cht_onlinGreenPoint_image"];
        _networkStatusLabel.text = @"Online";
    } else if ([_isOnline integerValue] == ChatOnlineStatusOffline) {
        _onlineImageView.image = [UIImage imageNamed:@"rlf_offlineGrayPoint"];
        _networkStatusLabel.text = @"Offline";
    } else if ([_isOnline integerValue] == ChatOnlineStatusBlocked) {
        _onlineImageView.image = [UIImage imageNamed:@"blocked_image"];
        _networkStatusLabel.text = @"Blocked";
    }
}



- (void)setChatRoom:(ChatRoom *)chatRoom {
    _chatRoom = chatRoom;
    
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:_chatRoom.companionImFriend.avatar.url]
                            placeholderImage:[UIImage imageNamed:@"cht_emptyAvatar_image"]];
    _friendNameLabel.text = [self getStringNamesForChatRoom:_chatRoom];
    
    if (chatRoom.wasDeactivatedBoolValue) {
        _friendNameLabel.textColor = [UIColor lightGrayColor];
        _onlineImageView.image = [UIImage imageNamed:@"rlf_offlineGrayPoint"];
        _networkStatusLabel.text = @"Friend deleted chat";
    } else {
        _friendNameLabel.textColor = [UIColor blackColor];
    }
}

//- (void)setImaginaryFriend:(ImaginaryFriend *)imaginaryFriend {
//    _imaginaryFriend = imaginaryFriend;
//    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:_imaginaryFriend.avatar.url]
//                            placeholderImage:[UIImage imageNamed:@"cht_emptyAvatar_image"]];
//    _friendNameLabel.text = _imaginaryFriend.friendName;
//    if ([_imaginaryFriend.wasDeleted boolValue]) {
//        _friendNameLabel.textColor = [UIColor lightGrayColor];
//        _onlineImageView.image = [UIImage imageNamed:@"rlf_offlineGrayPoint"];
//        _networkStatusLabel.text = @"Friend deleted role";
//    }
//}

- (void)setCdImaginaryFriend:(CDImaginaryFriend *)cdImaginaryFriend {
    _cdImaginaryFriend = cdImaginaryFriend;
    NSString *friendName = cdImaginaryFriend.friendName.length ? cdImaginaryFriend.friendName : @"Imaginary Friend";
    NSString *chatWithStr = [NSString stringWithFormat:@"With my %@", friendName];
    self.friendNameLabel.text = chatWithStr;
    
    NSString *path = [Utilities pathToImageWithName:_cdImaginaryFriend.avatarImageName
                                             userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
    UIImage *image = [Utilities getAvatarImageAtPath:path];
    self.avatarImageView.image = image ? image : [UIImage imageNamed:@"cht_emptyAvatar_image"];
}

- (void)setUnreadMessagesCount:(NSNumber *)unreadMessagesCount{
    _unreadMessagesCount = unreadMessagesCount;
    self.notificationButton.hidden = [_unreadMessagesCount integerValue] == 0 ? YES : NO;
    [self.notificationButton setTitle:[NSString stringWithFormat:@"%@", _unreadMessagesCount]
                             forState:UIControlStateNormal];
}


#pragma mark Notification observers

-(void)shouldShowLeftAccessoryButton:(NSNotification *)notification {
    [self showLeftUtilityButtonsAnimated:YES];
}


-(void)shouldHideLeftAccessoryButton:(NSNotification *)notification {
    [self hideUtilityButtonsAnimated:YES];
}

- (NSString *)getStringNamesForChatRoom:(ChatRoom *)chatRoom {
    if (!chatRoom.companionImFriend.friendName) {
        //
    }
    
    ImaginaryFriend *first = chatRoom.participantsImaginaryFriends.count ? chatRoom.participantsImaginaryFriends[0] : nil;
    ImaginaryFriend *second = chatRoom.participantsImaginaryFriends.count == 2 ? chatRoom.participantsImaginaryFriends[1] : nil;
    ImaginaryFriend *your = [first isEqual:chatRoom.companionImFriend] ? second : first;
    
    NSString *companionImFriendName = chatRoom.companionImFriend.friendName ? chatRoom.companionImFriend.friendName : @"Imaginary Friend";
    
    NSString *compoundStr = [NSString stringWithFormat:@"With %@ as %@", companionImFriendName, your.friendName];
    return compoundStr;
}

@end
