//
//  User.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/10/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Parse/PFObject+Subclass.h>
#import <Parse/Parse.h>
#import "AvatarPhoto.h"

@interface ImaginaryFriend : PFObject <PFSubclassing>

@property (strong) NSString *friendName;
@property (strong) NSString *occupation;
@property (strong) NSString *coreDataObjectId;
@property (strong) NSNumber *friendAge;
@property (strong) NSString *personality;
@property (strong) NSDate *lastChanged;
@property (assign) NSNumber *publicType;
@property (strong) AvatarPhoto *avatarPhoto;
@property (strong) PFUser *attachedToUser;
@property (strong) PFFile *avatar;
@property (strong) NSNumber *isYourselfObj;
@property (strong) NSNumber *wasDeleted;
@property (strong) NSString *avatarImageName;
@property (strong) NSString *biography;
@property (strong) NSArray *blockedByUsers;

@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, assign) BOOL isYourself;
@property (nonatomic, strong) NSString *realName;
@property (nonatomic, strong) PFUser *fetchedUser;


+ (NSString *)parseClassName;
+ (NSArray *)sortImaginaryFriendsByName:(NSArray *)imFriends;

+ (NSString *)blockedByUsersPropertyName;

- (BOOL)isBlockedByUser:(PFUser *)user;
- (BOOL)isBlocked;


@end
