//
//  ChatPhoto.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "ChatPhoto.h"

@implementation ChatPhoto

@dynamic thumbnailImage;
@dynamic fullImage;
@dynamic attachedToChatRoom;
@dynamic thumbHeight;
@dynamic thumbWidth;

#pragma mark - Static methods

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"ChatPhoto";
}

@end
