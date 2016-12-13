//
//  CDImaginaryFriend.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/19/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "PrefixHeader.pch"
#import "ImaginaryFriend.h"
#import "AuthorizationManager.h"
#import "SharedDateFormatter.h"
#import "UIImageView+WebCache.h"

#import "CDImaginaryFriend.h"
#import "CDUser.h"


@implementation CDImaginaryFriend

@dynamic friendAge;
@dynamic friendName;
@dynamic isYourself;
@dynamic lastOpenedChatAsUser;
@dynamic lastUpdated;
@dynamic objectId;
@dynamic occupation;
@dynamic personality;
@dynamic publicType;
@dynamic avatarImageName;
@dynamic wasDeleted;
@dynamic biography;
@dynamic user;
@dynamic message;
@dynamic rooms;


#pragma mark - Static methods

+ (CDImaginaryFriend *)imaginaryFriendWithObjectId:(NSString *)objectId inContext:(NSManagedObjectContext *)context {
    CDImaginaryFriend *imFriend = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[CDImaginaryFriend class] description] inManagedObjectContext:context];
    [fetchRequest setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", objectId];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *matchingData = [context executeFetchRequest:fetchRequest error:&error];
    if (matchingData.count) {
        imFriend = [matchingData firstObject];
        if (!imFriend.user) {
            imFriend.user = [AuthorizationManager sharedInstance].currentCDUser;
        }
    } else {
        imFriend = [[CDImaginaryFriend alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        imFriend.wasDeleted = @(NO);
        imFriend.objectId = objectId;
        imFriend.publicType = @(0);
        imFriend.avatarImageName = [Utilities getNewGUID];
        imFriend.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
        imFriend.user = [AuthorizationManager sharedInstance].currentCDUser;
    }
    
    if (![context save:&error]) {
        $l(@"---> Insert CDImaginaryFriend error - %@", error);
    }
    
    return imFriend;
}

+ (NSString *)updateCDImaginaryFriendFromParse:(ImaginaryFriend *)parseImFriend inContext:(NSManagedObjectContext *)context {
    NSString *updatedObjectId = nil;
    CDImaginaryFriend *imFriend = [CDImaginaryFriend imaginaryFriendWithObjectId:parseImFriend.coreDataObjectId
                                                                       inContext:context];
//    if ([imFriend.lastUpdated compare:parseImFriend.updatedAt] == NSOrderedSame) {
//        return nil;
//    }
    
    imFriend.lastUpdated = parseImFriend.updatedAt;
    imFriend.friendAge = parseImFriend.friendAge;
    imFriend.friendName = parseImFriend.friendName;
    imFriend.isYourself = parseImFriend.isYourselfObj;
    imFriend.wasDeleted = parseImFriend.wasDeleted;
    imFriend.occupation = parseImFriend.occupation;
    imFriend.personality = parseImFriend.personality;
    imFriend.publicType = parseImFriend.publicType;
    imFriend.avatarImageName = parseImFriend.avatarImageName;
    imFriend.biography = parseImFriend.biography;
    if (!imFriend.user) {
        imFriend.user = [AuthorizationManager sharedInstance].currentCDUser;
    }
    updatedObjectId = imFriend.objectId;
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:[NSURL URLWithString:parseImFriend.avatar.url]
                          options:0
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                             // progression tracking code
                         }
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                            if (image) {
                                NSString *imagePath = [Utilities pathToImageWithName:imFriend.avatarImageName
                                                                              userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
                                [Utilities saveImage:image atPath:imagePath];
                                [[NSNotificationCenter defaultCenter] postNotificationName:kAvatarImageWasDownloaded object:parseImFriend.objectId];
                            }
                        }];
    
    NSError *error = nil;
    if (![context save:&error]) {
        $l(@"---> save CDImaginaryFriend error - %@", error);
        return nil;
    }
    
    
    return updatedObjectId;
}

+ (CDImaginaryFriend *)convertParseImaginaryFriend:(ImaginaryFriend *)parseImFriend withContext:(NSManagedObjectContext *)context {
    CDImaginaryFriend *imFriend = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[CDImaginaryFriend class] description] inManagedObjectContext:context];
    [fetchRequest setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parseObjectId == %@", parseImFriend.objectId];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *matchingData = [context executeFetchRequest:fetchRequest error:&error];
    if (matchingData.count == 1) {
        imFriend = [matchingData lastObject];
    } else if(matchingData.count > 1) {
        $l("---Error !!! matchingData.count > 1");
        [Utilities showAlertViewWithTitle:@"Error"
                                  message:@"---Error !!! matchingData.count > 1"
                        cancelButtonTitle:@"OK"];
    } else {
        imFriend.lastUpdated = parseImFriend.updatedAt;
        imFriend.friendAge = parseImFriend.friendAge;
        imFriend.friendName = parseImFriend.friendName;
        imFriend.isYourself = parseImFriend.isYourselfObj;
        imFriend.wasDeleted = parseImFriend.wasDeleted;
        imFriend.occupation = parseImFriend.occupation;
        imFriend.personality = parseImFriend.personality;
        imFriend.publicType = parseImFriend.publicType;
        imFriend.avatarImageName = parseImFriend.avatarImageName;
        imFriend.biography = parseImFriend.biography;
    }
    
    return imFriend;
}

+ (NSArray *)sortImaginaryFriendsByFriendName:(NSArray *)friendsList {
    NSSortDescriptor *sortDescr = [NSSortDescriptor sortDescriptorWithKey:@"friendName"
                                                                ascending:YES];
    friendsList = [friendsList sortedArrayUsingDescriptors:@[sortDescr]];
    return friendsList;
}

@end
