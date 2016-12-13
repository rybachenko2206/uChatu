//
//  AuthorizationManager.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/1/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import "CoreDataManager.h"
#import "CDUserSettings.h"
#import "ResponseInfo.h"
#import "WebService.h"
#import "LoginViewController.h"
#import "Utilities.h"
#import "SharedDateFormatter.h"
#import "UIImageView+WebCache.h"
#import "ReachabilityManager.h"

#import "AuthorizationManager.h"


@interface AuthorizationManager () {
    BOOL isDownloadingUserAvatarImage;
}

@property (nonatomic, assign, readwrite) BOOL loggedIn;

@end


@implementation AuthorizationManager

@synthesize userSettings = _userSettings;
@synthesize currentCDUser = _currentCDUser;
@synthesize currentUser = _currentUser;

#pragma mark - Static methods

+(instancetype) sharedInstance {
    static AuthorizationManager *authManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        authManager = [[AuthorizationManager alloc] init];
    });
    
    return authManager;
}

+(void) presentLoginViewControllerForViewController:(UIViewController*)viewController animated:(BOOL)animated {
    UIStoryboard *storyboard = [UIStoryboard authentication];
    
    LoginViewController *loginModalVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginModalVC];
    navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [viewController presentViewController:navController animated:animated completion:nil];
}


#pragma mark - Interface methods

- (void)setCurrentUserOnline:(BOOL)isOnline {
    if ([[ReachabilityManager sharedInstance] isReachable]) {
        self.currentUser.isOnline = @(isOnline);
        [self.currentUser saveInBackground];
    }
}


#pragma mark - Getter methods

-(BOOL) loggedIn {
    _loggedIn = self.currentUser ? YES : NO;
    return _loggedIn;
}

- (PFUser *) currentUser {
    _currentUser = [PFUser currentUser];
    return _currentUser;
}

- (void)setCurrentUser:(PFUser *)currentUser {
    _currentUser = currentUser;
    [self userAvatarImage];
}

- (CDUser *)currentCDUser {
    if (!_currentUser) {
        return nil;
    }
    _currentCDUser = [CDUser userWithEmail:self.currentUser.email userId:_currentUser.objectId inContext:[CDManagerVersionTwo sharedInstance].managedObjectContext];
    
    return _currentCDUser;
}

- (void)setCurrentCDUser:(CDUser *)currentCDUser {
    _currentCDUser = currentCDUser;
    if ([_currentCDUser.lastUpdated compare:self.currentUser.updatedAt] == NSOrderedDescending) {
        _currentCDUser.email = _currentUser.email;
        _currentCDUser.phoneNumber = _currentUser.phoneNumber;
        _currentCDUser.userName = _currentUser.userName;
        _currentCDUser.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
        [[CDManagerVersionTwo sharedInstance] saveContext];
    }
}

- (UIImage *)userAvatarImage {
    if (!_currentUser) {
        return [UIImage imageNamed:@"cht_emptyAvatar_image"];
    }
    if (_userAvatarImage) {
        return _userAvatarImage;
    } else if (!_userAvatarImage && !isDownloadingUserAvatarImage) {
        isDownloadingUserAvatarImage = YES;
        
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager downloadImageWithURL:[NSURL URLWithString:self.currentUser.photo.url]
                              options:0
                             progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                 // progression tracking code
                             }
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                isDownloadingUserAvatarImage = NO;
                                if (image) {
                                    _userAvatarImage = image;
                                    NSString *imagePath = [Utilities pathToImageWithName:_currentCDUser.avatarImageName
                                                                                  userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
                                    [Utilities saveImage:_userAvatarImage atPath:imagePath];
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [[NSNotificationCenter defaultCenter] postNotificationName:kAvatarImageWasDownloaded
                                                                                            object:self.currentUser.objectId];
                                    });
                                }
                            }];
    }
    
    return [UIImage imageNamed:@"cht_emptyAvatar_image"];
}


@end
