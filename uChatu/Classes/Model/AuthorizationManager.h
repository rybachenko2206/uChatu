//
//  AuthorizationManager.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/1/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "PrefixHeader.pch"
#import "CDUserSettings.h"
#import "CoreDataManager.h"
#import "CDManagerVersionTwo.h"
#import "CDUser.h"

@interface AuthorizationManager : NSObject

@property (nonatomic, assign, readonly) BOOL loggedIn;
@property (nonatomic, strong) CDUserSettings *userSettings;
@property (nonatomic, strong) PFUser *currentUser;
@property (nonatomic, strong) CDUser *currentCDUser;
@property (nonatomic, strong) UIImage *userAvatarImage;


+(instancetype) sharedInstance;
+(void) presentLoginViewControllerForViewController:(UIViewController*)viewController animated:(BOOL)animated;
- (void)setCurrentUserOnline:(BOOL)isOnline;


@end
