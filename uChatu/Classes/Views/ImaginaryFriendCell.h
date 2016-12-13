//
//  ImaginaryFriendCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/10/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//



#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"
#import "RoundedImageView.h"
#import "CDImaginaryFriend.h"

extern NSString * const kShouldShowLeftAccessoryButtonsNotification;
extern NSString * const kShouldHideLeftAccessoryButtonsNotification;

@class ImaginaryFriendCell;

@protocol ImaginaryFriendCellDelegate <NSObject>
- (void)settingsButtonTapped:(ImaginaryFriendCell *)cell;
@end

@interface ImaginaryFriendCell :SWTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *friendsNameLabel;
@property (weak, nonatomic) IBOutlet RoundedImageView *avatarImageView;

@property (nonatomic, strong) CDImaginaryFriend *imaginaryFriend;
@property (weak) id <ImaginaryFriendCellDelegate> settingsButtonDelegate;

+ (CGFloat)cellHeight;

@end
