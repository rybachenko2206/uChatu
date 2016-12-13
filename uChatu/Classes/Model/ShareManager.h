//
//  ShareManager.h
//  uChatu
//
//  Created by Roman Rybachenko on 7/18/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "PrefixHeader.pch"

@interface ShareManager : NSObject

+ (ShareManager *)sharedInstance;

- (void)sendMessageFromViewController:(UIViewController *)viewController;
- (void)shareToTwitterFromViewController:(UIViewController *)viewController;
- (void)shareToFacebookFromViewController:(UIViewController *)viewController;
- (void)shareWithEmailFromViewController:(UIViewController *)viewController
                           withComplaint:(BOOL)isComplaint
                           attachedImage:(UIImage *)attachedImage
                             messageText:(NSString *)text;

@end
