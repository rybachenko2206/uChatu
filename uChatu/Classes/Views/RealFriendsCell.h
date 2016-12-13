//
//  RealFriendsCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImaginaryFriend.h"
#import "RoundedImageView.h"
@class RealFriendsCell;


@protocol RealFriendsCellDelegate <NSObject>

- (void)realFriendSCellInfoButtonWasPressed:(id)sender;

@end


@interface RealFriendsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *onlineStatusImageView;
@property (weak, nonatomic) IBOutlet RoundedImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *friendNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *realNameLabel;
@property (nonatomic, strong) NSNumber *isOnline;

@property (weak) id <RealFriendsCellDelegate> delegate;

@property (assign, nonatomic) BOOL shouldHideUserName;

@property (nonatomic, strong) ImaginaryFriend *imaginaryFriend;

+ (CGFloat)heightForCell;
- (void)resetImaginaryFriend:(ImaginaryFriend *)imaginaryFriend;

@end
