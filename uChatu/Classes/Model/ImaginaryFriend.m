//
//  User.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/10/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import "WebService.h"
#import "PrefixHeader.pch"
#import "AuthorizationManager.h"
#import "AddressBookManager.h"

#import "ImaginaryFriend.h"


@interface ImaginaryFriend () {
    BOOL isDownloadingAvatarImage;
}

@end


@implementation ImaginaryFriend

@synthesize avatarImage;
@synthesize isYourself;
@synthesize realName;
@synthesize fetchedUser;

@dynamic occupation;
@dynamic friendName;
@dynamic publicType;
@dynamic friendAge;
@dynamic personality;
@dynamic attachedToUser;
@dynamic lastChanged;
@dynamic coreDataObjectId;
@dynamic avatar;
@dynamic avatarPhoto;
@dynamic isYourselfObj;
@dynamic wasDeleted;
@dynamic avatarImageName;
@dynamic biography;
@dynamic blockedByUsers;


#pragma mark - Static methods

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"ImaginaryFriend";
}


#pragma mark - Getter methods

- (PFUser *)fetchedUser {
    if (fetchedUser) {
        return fetchedUser;
    }
    fetchedUser = self.attachedToUser;
    [fetchedUser fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (object) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAttachedObjectWasFetchedNotification
                                                                object:object.objectId];
        }
    }];
    
    return nil;
}

- (UIImage *)avatarImage {
    if (isDownloadingAvatarImage) {
        isDownloadingAvatarImage = YES;
        
        [[WebService sharedInstanse] getFriendAvatarImageForImaginaryFriend:self
                                                                   withBlock:^(ResponseInfo *responseInfo) {
                                                                       isDownloadingAvatarImage = NO;
                                                                       if (responseInfo.success && responseInfo.objects) {
                                                                           UIImage *image = [responseInfo.objects lastObject];
                                                                           
                                                                           if (image) {
                                                                               avatarImage = image;
                                                                               NSString *imagePath = [Utilities pathToImageWithName:self.avatarImageName
                                                                                                                                   userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
                                                                               [Utilities saveImage:avatarImage atPath:imagePath];
                                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   [[NSNotificationCenter defaultCenter] postNotificationName:kAvatarImageWasDownloaded
                                                                                                                                       object:self.objectId];
                                                                               });
                                                                               
                                                                           }
                                                                       }
                                                                   }];
    }
    
    return avatarImage;
}

- (BOOL)isYourself {
    return [self.isYourselfObj boolValue];
}

- (NSString *)realName {
    if ([self.publicType integerValue] != ImaginaryFriendPublicTypeVisible) {
        return @"";
    }
    realName = [[AddressBookManager sharedInstance] getRealNameForUserWithObjectId:self.attachedToUser.objectId];
    
    return realName;
}

+ (NSArray *)sortImaginaryFriendsByName:(NSArray *)imFriends {
    NSSortDescriptor *sortDescr = [NSSortDescriptor sortDescriptorWithKey:@"friendName"
                                                                ascending:YES];
    NSArray *sortedArray = [imFriends sortedArrayUsingDescriptors:@[sortDescr]];
    return sortedArray;
}

+ (NSString *)blockedByUsersPropertyName {
    return @"blockedByUsers";
}


- (BOOL)isBlockedByUser:(PFUser *)user {
    if ([self.blockedByUsers containsObject:user.objectId]) {
        return YES;
    }
    return NO;
}

@end
