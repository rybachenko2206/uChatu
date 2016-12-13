//
//  AvatarImage.h
//  uChatu
//
//  Created by Roman Rybachenko on 4/16/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>
@class ImaginaryFriend;

@interface AvatarPhoto : PFObject <PFSubclassing>

@property (strong) PFFile *thumbnailImage;
@property (strong) PFFile *fullImage;
@property (strong) ImaginaryFriend *imaginaryFriend;

+ (NSString *)parseClassName;
+ (AvatarPhoto *)avatarImageWithImage:(UIImage *)image imaginaryFriend:(ImaginaryFriend *)imFriend;

@end
