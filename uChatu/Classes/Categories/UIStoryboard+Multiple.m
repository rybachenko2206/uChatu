//
//  UIStoryboard+Multiple.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/4/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "UIStoryboard+Multiple.h"

@implementation UIStoryboard (Multiple)

+(instancetype)main {
    return [UIStoryboard storyboardWithName:@"Main" bundle:nil];
}

+(instancetype)authentication {
    return [UIStoryboard storyboardWithName:@"Authentication" bundle:nil];
}

+(instancetype)settings {
    return [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
}

+(instancetype)chats {
    return [UIStoryboard storyboardWithName:@"Chats" bundle:nil];
}

@end
