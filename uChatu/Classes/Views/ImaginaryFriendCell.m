//
//  ImaginaryFriendCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/10/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "WebService.h"
#import "ResponseInfo.h"
#import "PrefixHeader.pch"
#import "AuthorizationManager.h"

#import "ImaginaryFriendCell.h"

NSString * const kShouldShowLeftAccessoryButtonsNotification = @"kShouldShowLeftAccessoryButtonsNotification";
NSString * const kShouldHideLeftAccessoryButtonsNotification = @"kShouldHideLeftAccessoryButtonsNotification";

@implementation ImaginaryFriendCell

#pragma mark - Interface methods

- (void)awakeFromNib {
    NSNotificationCenter *nCenter = [NSNotificationCenter defaultCenter];
    
    [nCenter addObserver:self
                selector:@selector(shouldShowLeftAccessoryButton:)
                    name:kShouldShowLeftAccessoryButtonsNotification
                  object:nil];
    
    [nCenter addObserver:self
                selector:@selector(shouldHideLeftAccessoryButton:)
                    name:kShouldHideLeftAccessoryButtonsNotification
                  object:nil];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark  - Setter methods

- (void)setImaginaryFriend:(CDImaginaryFriend *)imaginaryFriend {
    _imaginaryFriend = imaginaryFriend;
    NSString *frName = _imaginaryFriend.friendName;
    self.friendsNameLabel.text = frName ? frName : @"ImaginaryFriend";
    NSString *path = [Utilities pathToImageWithName:_imaginaryFriend.avatarImageName
                                                   userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
    UIImage *image = [Utilities getAvatarImageAtPath:path];
    self.avatarImageView.image = image ? image : [UIImage imageNamed:@"cht_emptyAvatar_image"];
    
}


#pragma mark - Action methods

- (IBAction)settingsButtonTapped:(id)sender {
    if ([self.settingsButtonDelegate respondsToSelector:@selector(settingsButtonTapped:)]) {
        [self.settingsButtonDelegate settingsButtonTapped:self];
    }
}


#pragma mark - Static methods

+ (CGFloat)cellHeight {
    return 75.0f;
}


#pragma mark Notification observers

-(void)shouldShowLeftAccessoryButton:(NSNotification *)notification {
    [self showLeftUtilityButtonsAnimated:YES];
}


-(void)shouldHideLeftAccessoryButton:(NSNotification *)notification {
    [self hideUtilityButtonsAnimated:YES];
}
@end
