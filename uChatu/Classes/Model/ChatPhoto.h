//
//  ChatPhoto.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Parse/Parse.h>
#import "ChatRoom.h"
#import "ImaginaryFriend.h"

@interface ChatPhoto : PFObject <PFSubclassing>

@property (strong) PFFile *thumbnailImage;
@property (strong) PFFile *fullImage;
@property (strong) ChatRoom *attachedToChatRoom;
@property (strong) NSNumber *thumbWidth;
@property (strong) NSNumber *thumbHeight;

+ (NSString *)parseClassName;

@end
