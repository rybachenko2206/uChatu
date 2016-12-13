//
//  AppDelegate.h
//  uChatu
//
//  Created by Roman Rybachenko on 11/19/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import "Reachability.h"
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) BOOL screenIsPortraitOnly;
@property (nonatomic, strong) NSData *deviceToken;


@end

