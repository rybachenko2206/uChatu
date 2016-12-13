//
//  SynchronizeDbManager.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/11/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Parse/Parse.h>
#import "PrefixHeader.pch"
#import "CoreDataManager.h"
#import "CDManagerVersionTwo.h"
#import "CDUser.h"
#import "CDUserSettings.h"
#import "CDImaginaryFriend.h"
#import "WebService.h"
#import "ImaginaryFriend.h"
#import "AuthorizationManager.h"
#import "ReachabilityManager.h"
#import "SharedDateFormatter.h"

#import "SynchronizeDbManager.h"

@implementation SynchronizeDbManager

#pragma mark - Static methods

+ (SynchronizeDbManager *)sharedInstance {
    static SynchronizeDbManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [SynchronizeDbManager new];
        
    });
    
    return sharedManager;
}


#pragma mark - Interface methods

- (void)transferDataFromOldToNewDatabaseWithComletion:(SynchronizationFinished)comletion {
    PFUser *currUser = [PFUser currentUser];
    CDUser *newCDUser = [CDUser userWithEmail:currUser.email
                                       userId:currUser.objectId
                                    inContext:[CDManagerVersionTwo sharedInstance].managedObjectContext];
    [[WebService sharedInstanse] getUserSettingsWithBlock:^(ResponseInfo *response) {
        __block NSInteger finishedCount = 0;
        PFObject *userSettings = [response.objects lastObject];
        currUser.userName = userSettings[userNameCol];
        currUser.avatarImageName = newCDUser.avatarImageName;
        [currUser saveInBackgroundWithBlock:^(BOOL success, NSError *error){
            finishedCount++;
            if (finishedCount == 3) {
                comletion(response.success, response.error);
            }
        }];
        
        [self setUserAvatarForUser:currUser
                      userSettings:userSettings
                         comletion:^(BOOL success, NSError *error) {
                             finishedCount++;
                             if (finishedCount == 3) {
                                 comletion(response.success, response.error);
                             }
                      }];
        
        [self createImaginaryFriendWithUserSettings:userSettings
                                          andCDUser:newCDUser
                                          comletion:^(BOOL success, NSError *error) {
                                              finishedCount++;
                                              if (finishedCount == 3) {
                                                  comletion(response.success, response.error);
                                              }
                                          }];
    }];
    
//    [Lockbox setString:@"1" forKey:isTransferDataToVersionTwoDatabaseKey];
}


#pragma mark - Private methods

- (void)setUserAvatarForUser:(PFUser *)user userSettings:(PFObject *)userSettings comletion:(SynchronizationFinished)comletion {
    [[WebService sharedInstanse] getUserAvatarImageForObject:userSettings
                                                   withBlock:^(ResponseInfo *respInfo){
                                                       UIImage *image = nil;
                                                       if (respInfo.success && respInfo.objects.count) {
                                                           image = [respInfo.objects lastObject];
                                                       } else {
                                                           image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
                                                           comletion(respInfo.success, respInfo.error);
                                                       }
                                                       NSData *imgData = UIImagePNGRepresentation(image);
                                                       PFFile *imageFile = [PFFile fileWithName:@"friendAvatar.png" data:imgData];
                                                       
                                                       user.photo = imageFile;
                                                       [user saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                                                           comletion(success, error);
                                                       }];
                                                   }];
}

- (void)createImaginaryFriendWithUserSettings:(PFObject *)userSettings andCDUser:(CDUser *)cdUser comletion:(SynchronizationFinished)comletion {
    PFUser *currUser = [AuthorizationManager sharedInstance].currentUser;
    
    [[WebService sharedInstanse] getAllImaginaryFriendsForUser:currUser
                                               completionBlock:^(ResponseInfo *response){
                                                   if (response.success && !response.objects.count) {
                                                       ImaginaryFriend *imFriend = [ImaginaryFriend object];
                                                       imFriend.friendAge = userSettings[friendsAgeCol];
                                                       imFriend.friendName = userSettings[friendsNameCol];
                                                       imFriend.occupation = userSettings[friendsOccupationCol];
                                                       imFriend.personality = userSettings[friendsPersonalityCol];
                                                       imFriend.attachedToUser = currUser;
                                                       imFriend.publicType = @(ImaginaryFriendPublicTypeVisible);
                                                       
                                                       CDImaginaryFriend *cdImFriend = [self createCDImaginaryFriendWithImaginaryFriend:imFriend];
                                                       cdImFriend.user = cdUser;
                                                       
                                                       imFriend.coreDataObjectId = cdImFriend.objectId;
                                                       imFriend.avatarImageName = cdImFriend.avatarImageName;
                                                       
                                                       
                                                       [imFriend saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                                                           if (success) {
                                                               [self setFriendAvatarForImaginaryFriend:imFriend
                                                                                          userSettings:userSettings];
                                                               
                                                               [[CDManagerVersionTwo sharedInstance] saveContext];
                                                           }
                                                           comletion(success, error);
                                                       }];
                                                       
                                                       PFUser *user = [AuthorizationManager sharedInstance].currentUser;
                                                       cdUser.userName = user.userName;
                                                       cdUser.phoneNumber = user.phoneNumber;
                                                       cdUser.email = user.email;
                                                       cdUser.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
                                                       [[CDManagerVersionTwo sharedInstance] saveContext];
                                                   } else {
                                                       comletion(response.success, response.error);
                                                   }
                                               }];
}

- (void)setFriendAvatarForImaginaryFriend:(ImaginaryFriend *)imFriend userSettings:(PFObject *)userSettings {
    [[WebService sharedInstanse] getFriendsAvatarImageForObject:userSettings
                                                      withBlock:^(ResponseInfo *respInfo){
                                                          UIImage *frAvatarImage = nil;
                                                          if (respInfo.success && respInfo.objects.count == 1) {
                                                              frAvatarImage = [respInfo.objects lastObject];
                                                          } else {
                                                              frAvatarImage = [UIImage imageNamed:@"cht_emptyAvatar_image"];
                                                          }
                                                          NSData *imgData = UIImagePNGRepresentation(frAvatarImage);
                                                          PFFile *imageFile = [PFFile fileWithName:@"friendAvatar.png" data:imgData];
                                                          imFriend.avatar = imageFile;
                                                          if ([[ReachabilityManager sharedInstance] isReachable]) {
                                                              [imFriend saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                                                                  $l("saveInBackground success -> %d", success);
                                                              }];
                                                          } else {
                                                              [imFriend saveEventually:^(BOOL successed, NSError *error){
                                                                  $l("saveEventually success -> %d", successed);
                                                              }];
                                                          }
                                                      }];
}

- (CDImaginaryFriend *)createCDImaginaryFriendWithImaginaryFriend:(ImaginaryFriend *)imagFriend {
    CDImaginaryFriend *cdImFr = [CDImaginaryFriend imaginaryFriendWithObjectId:[Utilities getNewGUID]
                                                                     inContext:[CDManagerVersionTwo sharedInstance].managedObjectContext];
    cdImFr.friendAge = imagFriend.friendAge;
    cdImFr.friendName = imagFriend.friendName;
    cdImFr.occupation = imagFriend.occupation;
    cdImFr.personality = imagFriend.personality;
    cdImFr.biography = imagFriend.biography;
    
    return cdImFr;
}

@end
