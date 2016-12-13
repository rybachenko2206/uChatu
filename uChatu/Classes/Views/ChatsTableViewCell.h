//
//  ChatsTableViewCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/1/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import "RoundedImageView.h"
#import "ImaginaryFriend.h"
#import "CDImaginaryFriend.h"
#import "SWTableViewCell.h"
#import "NotificationButton.h"
#import "ChatRoom.h"

#import <UIKit/UIKit.h>

@interface ChatsTableViewCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet NotificationButton *notificationButton;
@property (weak, nonatomic) IBOutlet RoundedImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *friendNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *onlineImageView;
@property (weak, nonatomic) IBOutlet UILabel *networkStatusLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notificationButtonWidthConstrailnt;

@property (nonatomic, strong) ChatRoom *chatRoom;
@property (nonatomic, strong) CDImaginaryFriend *cdImaginaryFriend;
@property (nonatomic, assign) NSNumber *unreadMessagesCount;
@property (nonatomic, strong) NSNumber *isOnline;

@end
