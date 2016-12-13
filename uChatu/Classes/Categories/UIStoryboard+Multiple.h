//
//  UIStoryboard+Multiple.h
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/4/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIStoryboard (Multiple)

+(instancetype)main;
+(instancetype)authentication;
+(instancetype)settings;
+(instancetype)chats;

@end
