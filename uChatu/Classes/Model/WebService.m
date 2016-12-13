
//
//  WebService.m
//  uChatu
//
//  Created by Roman Rybachenko on 11/27/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import "ResponseInfo.h"
#import "AuthorizationManager.h"
#import "ReachabilityManager.h"
#import "AppDelegate.h"
#import "SharedDateFormatter.h"
#import "CDUserSettings.h"
#import "CoreDataManager.h"
#import "Utilities.h"
#import "ImaginaryFriend.h"
#import "AddressBookManager.h"
#import "NSArray+RandomObjects.h"
#import "ChatRoom.h"
#import "XMPPService.h"
#import "PFInstallation+Additions.h"
#import "ChatPhoto.h"
#import "UChatuMessage.h"
#import "LocalDSManager.h"
#import "AvatarPhoto.h"
#import "Complaint.h"

#import "WebService.h"


NSString *const userEmailKey = @"userEmailKey";
NSString *const userPasswordKey = @"userPasswordKey";


@implementation WebService


#pragma mark - Allocators

+(WebService *) sharedInstanse {
    static WebService *_sharedInstanse = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstanse = [[WebService alloc] init];
    });
    return _sharedInstanse;
}


#pragma mark - Interface methods

-(BOOL) isLoggedIn {
    PFUser *user = [PFUser currentUser];
    if (!user) {
        return NO;
    }
    
    return YES;
}

-(void) logOut {
    if (![PFUser currentUser]) {
        return;
    }
    [PFUser logOut];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation removeObjectForKey:@"kCurrentUser"];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        
    }];
    [AuthorizationManager sharedInstance].currentUser = nil;
    [AuthorizationManager sharedInstance].currentCDUser = nil;
}

-(void) signUpWithUsername:(NSString *)username
                     email:(NSString *)email
                  password:(NSString *)password
                completion:(RequestCallback)completionBlock {
    
    PFUser *user = [PFUser user];
    user.username = email;
    user.email = email;
    user.password = password;
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        ResponseInfo *respInfo = [[ResponseInfo alloc] init];
        respInfo.success = succeeded;
        respInfo.error = error;
        
        completionBlock(respInfo);
    }];
}

-(void) logInWithEmail:(NSString *)email
               password:(NSString *)password
             completion:(RequestCallback)completionBlock {
    
    [PFUser logInWithUsernameInBackground:email password:password
                                    block:^(PFUser *user, NSError *error) {
                                        ResponseInfo *respInfo = [[ResponseInfo alloc] init];
                                        respInfo.user = user;
                                        respInfo.error = error;
                                        if (user) {
                                            [self trackTimeWhenUserLogin];
                                            respInfo.success = YES;
                                            completionBlock(respInfo);
                                        } else {
                                            if ([error code] == kPFErrorConnectionFailed) {
                                                completionBlock(respInfo);
                                            } else if ([error code] == kPFErrorObjectNotFound) {
                                                [self isExistUserWithEmail:email
                                                                completion:^(ResponseInfo *responseInfo) {
                                                                    respInfo.objects = responseInfo.objects;
                                                                    respInfo.success = NO;
                                                                    completionBlock(respInfo);
                                                                }];
                                            }
                                        }
                                    }];
}

-(void) updateUserSettingsWithUserAvatar:(BOOL)withUserAvatar withFriendAvatar:(BOOL)withFriendAvatar {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        return;
    }
    
    PFUser *user = [PFUser currentUser];
    CDUserSettings *cdUserSettings = [[CoreDataManager sharedInstance] userSettingsWithUserId:user.objectId email:user.email];
    
    [[WebService sharedInstanse] getUserSettingsWithBlock:^(ResponseInfo *responseInfo) {
        PFObject *settings = [responseInfo.objects firstObject];
        if (settings) {
            // compare dates
            if ([settings.updatedAt compare:cdUserSettings.lastChanged] == NSOrderedDescending) {
                cdUserSettings.userName = settings[userNameCol];
                cdUserSettings.friendAge = settings[friendsAgeCol];
                cdUserSettings.friendName = settings[friendsNameCol];
                cdUserSettings.friendOccupation = settings[friendsOccupationCol];
                cdUserSettings.friendPersonality = settings[friendsPersonalityCol];
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserSettingsChangedNotification object:nil];
                // download avatars
                [self getUserAvatarImageForObject:settings withBlock:^(ResponseInfo *response) {
                    if (response.objects.count) {
                        UIImage *image = [response.objects firstObject];
                        NSString *pathToSave = [Utilities pathToUserAvatarImageForUserWithId:user.objectId];
                        [Utilities saveImage:image atPath:pathToSave];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kUserSettingsChangedNotification object:nil];
                    }
                }];
                
                [self getFriendsAvatarImageForObject:settings withBlock:^(ResponseInfo *response) {
                    if (response.objects.count) {
                        UIImage *image = [response.objects firstObject];
                        NSString *pathToSave = [Utilities pathToFriendAvatarImageForUserWithId:user.objectId];
                        [Utilities saveImage:image atPath:pathToSave];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kUserSettingsChangedNotification object:nil];
                    }
                }];
                
            } else {
                settings[userNameCol] = cdUserSettings.userName;
                settings[friendsAgeCol] = cdUserSettings.friendAge;
                settings[friendsNameCol] = cdUserSettings.friendName;
                settings[friendsOccupationCol] = cdUserSettings.friendOccupation;
                settings[friendsPersonalityCol] = cdUserSettings.friendPersonality;
                
                [settings saveInBackgroundWithBlock:^(BOOL succeded, NSError *error) {
                    [self sendUserAvatarImageToObject:settings];
                    [self sendFriendsAvatarImageToObject:settings];
                    if (error) {
                        $l("--Error - %@", [error localizedDescription]);
                    }
                }];
                
            }
            
        } else {
            $l("Error! User does not have settings");
        }
    }];
}

-(void) sendFriendsAvatarImageToObject:(PFObject *)object {
    PFUser *user = [PFUser currentUser];
    
    PFObject *userSettings = object;
    if (!userSettings) {
        userSettings = [PFObject objectWithClassName:userSettingsClass];
        userSettings[attachedToUserCol] = user;
    }
    CDUserSettings *cdUserSettings = [[CoreDataManager sharedInstance] userSettingsWithUserId:user.objectId email:user.email];
    UIImage *image = [Utilities getFriendAvatarImageForUserWithId:cdUserSettings.userId];
    if (!image) {
        image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    PFFile *imageFile = [PFFile fileWithName:@"friendsAva.png" data:imageData];
    userSettings[friendsAvatarImageCol] = imageFile;
    
    [userSettings saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        if (error) {
            $l("--- Error -> %@", [error localizedDescription]);
        }
    }];
}

-(void) sendUserAvatarImageToObject:(PFObject *)object {
    PFUser *user = [PFUser currentUser];
    
    PFObject *userSettings = object;
    if (!userSettings) {
        userSettings = [PFObject objectWithClassName:userSettingsClass];
        userSettings[attachedToUserCol] = user;
    }
    CDUserSettings *cdUserSettings = [[CoreDataManager sharedInstance] userSettingsWithUserId:user.objectId email:user.email];
    UIImage *image = [Utilities getUserAvatarImageForUserWithId:cdUserSettings.userId];
    if (!image) {
        image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    PFFile *imageFile = [PFFile fileWithName:@"userAva.png" data:imageData];
    userSettings[avatarImageCol] = imageFile;
    
    [userSettings saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        if (error) {
            $l("--- Error -> %@", [error localizedDescription]);
        }
    }];
}

-(void) getUserAvatarImageForObject:(PFObject *)pfUserSetting withBlock:(RequestCallback)completionBlock {
    PFFile *userAvatarFile = pfUserSetting[avatarImageCol];
    if (!userAvatarFile) {
        completionBlock(nil);
    }
    [userAvatarFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        ResponseInfo *responseInfo = [[ResponseInfo alloc] init];
        if (!error && imageData) {
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                responseInfo.success = YES;
                responseInfo.objects = @[image];
            }
        } else {
            responseInfo.success = NO;
            responseInfo.error = error;
            $l("--- Error - %@", [error localizedDescription]);
        }
        completionBlock(responseInfo);
    }];
}

-(void) getFriendsAvatarImageForObject:(PFObject *)pfUserSetting withBlock:(RequestCallback)completionBlock {
    PFFile *friendAvatarFile = pfUserSetting[friendsAvatarImageCol];
    [friendAvatarFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        ResponseInfo *responseInfo = [[ResponseInfo alloc] init];
        if (!error && imageData) {
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                responseInfo.success = YES;
                responseInfo.objects = @[image];
            }
        } else {
            responseInfo.success = NO;
            responseInfo.error = error;
            $l("--- Error - %@", [error localizedDescription]);
        }
        completionBlock(responseInfo);
    }];
}


-(void) getUserSettingsWithBlock:(RequestCallback)completionBlock {
    PFUser *user = [PFUser currentUser];
    PFQuery *query = [PFQuery queryWithClassName:userSettingsClass];
    [query whereKey:attachedToUserCol equalTo:user];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        ResponseInfo *responseInfo = [[ResponseInfo alloc] init];
        if (object) {
            responseInfo.objects = @[object];
            responseInfo.success = YES;
            completionBlock(responseInfo);
        } else {
            [self createAndSaveUserSerttingsForUser:user completion:^(ResponseInfo *response) {
                responseInfo.success = response.success;
                responseInfo.error = response.error;
                response.objects = response.objects;
                completionBlock(responseInfo);
                if (response.error) {
                    $l(@"Error -> %@,", error);
                }
            }];
            responseInfo.success = NO;
            responseInfo.error = error;
            completionBlock(responseInfo);
        }
    }];
}

- (void)isExistUserWithEmail:(NSString *)email completion:(RequestCallback)completionBlock {
    PFQuery *query = [PFUser query];
    [query whereKey:@"email" equalTo:email];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *responsInfo = [[ResponseInfo alloc] init];
        responsInfo.error = error;
        responsInfo.objects = objects;
        completionBlock(responsInfo);
    }];
}

- (void)isExistUserWithPhone:(NSString *)phoneNumber completion:(RequestCallback)completionBlock {
    PFQuery *query = [PFUser query];
    [query whereKey:@"phone" equalTo:phoneNumber];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *responsInfo = [[ResponseInfo alloc] init];
        responsInfo.error = error;
        responsInfo.objects = objects;
        completionBlock(responsInfo);
    }];
}

-(void) requestPasswordResetForEmail:(NSString *)email completion:(RequestCallback)completionBlock {
    [PFUser requestPasswordResetForEmailInBackground:email
                                               block:^(BOOL succeeded, NSError *error) {
                                                   ResponseInfo *responseInfo = [[ResponseInfo alloc] init];
                                                   if (succeeded) {
                                                       responseInfo.success = YES;
                                                       completionBlock(responseInfo);
                                                   } else {
                                                       responseInfo.success = NO;
                                                   }
                                               }];
}

-(void) trackTimeWhenUserLogin {
    PFUser *user = [PFUser currentUser];
    
    PFObject *timeLogin = [PFObject objectWithClassName:@"TimeUserLogin"];
    timeLogin[timeLoginCol] = [NSDate date];
    timeLogin[userNameCol] = user.username;
    timeLogin[userCol] = user;
    
    [timeLogin saveInBackground];
}

-(void) updateCurrentUserWithBlock:(RequestCallback)completionBlock {
    PFUser *currUser = [PFUser currentUser];
    
    [currUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        ResponseInfo *respInfo = [ResponseInfo new];
        respInfo.success = succeeded;
        respInfo.error = error;
        completionBlock(respInfo);
    }];
}

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

- (void)uploadUserAvatarImage:(UIImage *)image withBlock:(RequestCallback)completionBlock {
    if (!image) {
        image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    PFFile *imageFile = [PFFile fileWithName:@"userAvatar.png" data:imageData];
    PFUser *currUser = [AuthorizationManager sharedInstance].currentUser;
    currUser.photo = imageFile;
    [currUser saveInBackgroundWithBlock:^(BOOL succeded, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.success = succeded;
        response.error = error;
        if (error) {
            $l("--- Save UserAvatar Error -> %@", [error localizedDescription]);
            [currUser saveEventually];
        }
        completionBlock(response);
    }];
}

- (void)uploadFriendAvatarImage:(UIImage *)image forImaginaryFriend:(ImaginaryFriend *)imaginaryFriend withBlock:(RequestCallback)completionBlock {
    if (!imaginaryFriend.objectId) {
        return;
    }
    if (!image) {
        image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    PFFile *imageFile = [PFFile fileWithName:@"friendAvatar.png" data:imageData];
    imaginaryFriend.avatar = imageFile;
    [imaginaryFriend saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        ResponseInfo *responseInfo = [[ResponseInfo alloc] init];
        responseInfo.success = success;
        responseInfo.error = error;
        if (error) {
            $l("---Save ImaginaryFriend Error -> %@", [error localizedDescription]);
        }
        completionBlock(responseInfo);
    }];
}

- (void)getUserAvatarImageForUser:(PFUser *)user withBlock:(RequestCallback)completionBlock {
    PFFile *avatarFile = user.photo;
    [avatarFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        ResponseInfo *responseInfo = [[ResponseInfo alloc] init];
        if (!error && data) {
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                responseInfo.success = YES;
                responseInfo.objects = @[image];
            }
        } else {
            responseInfo.success = NO;
            responseInfo.error = error;
            $l("--- Error - %@", [error localizedDescription]);
        }
        completionBlock(responseInfo);
    }];
}

- (void)getFriendAvatarImageForImaginaryFriend:(ImaginaryFriend *)imaginaryFriend withBlock:(RequestCallback)completionBlock {
    PFFile *friendAvatarFile = imaginaryFriend.avatar;
    [friendAvatarFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        ResponseInfo *responseInfo = [[ResponseInfo alloc] init];
        if (!error && data) {
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                responseInfo.success = YES;
                responseInfo.objects = @[image];
            }
        } else {
            responseInfo.success = NO;
            responseInfo.error = error;
            $l("--- Error - %@", [error localizedDescription]);
        }
        completionBlock(responseInfo);
    }];
}


- (void)getAllImaginaryFriendsForUser:(PFUser *)user completionBlock:(RequestCallback)completionBlock {
    PFQuery *query = [PFQuery queryWithClassName:[[ImaginaryFriend class] description]];
    [query whereKey:attachedToUserCol equalTo:user];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [PFObject pinAllInBackground:objects];
        ResponseInfo *respInfo = [[ResponseInfo alloc] init];
        respInfo.success = !error;
        respInfo.error = error;
        respInfo.objects = [self filtredWasDeletedImaginaryFriends:objects];
        
        completionBlock(respInfo);
    }];
}

- (void)getAllVisibleImaginaryFriendsForUser:(PFUser *)user completionBlock:(RequestCallback)completionBlock {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"publicType = %@ AND wasDeleted != %@",
                              @(ImaginaryFriendPublicTypeVisible), @(YES)];
    PFQuery *query = [PFQuery queryWithClassName:[[ImaginaryFriend class] description] predicate:predicate];
    [query whereKey:attachedToUserCol equalTo:user];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        if (objects && !error) {
            [PFObject pinAllInBackground:objects];
            response.objects = objects;
            response.success = YES;
        } else {
            response.error = error;
        }
        completionBlock(response);
    }];
}


-(void)getRandomImaginaryFriendsWithCompletion:(RequestCallback)completion {
    const int kRequiredObjectCount = 1000;
    const int kBatchSize = 300;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"publicType = %@ AND wasDeleted != %@",
                              @(ImaginaryFriendPublicTypeVisible), @(YES)];
    PFQuery *query = [PFQuery queryWithClassName:[[ImaginaryFriend class] description]
                                       predicate:predicate];
    query.limit = kRequiredObjectCount;
    
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        query.skip = [self randomSkipValueWithCount:number
                                        rangeLength:kBatchSize];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            ResponseInfo *response = [ResponseInfo new];
            response.error = error;
            if (objects && !error) {
                [PFObject pinAllInBackground:objects];
                NSPredicate *predicateYourObjs = [NSPredicate predicateWithFormat:@"attachedToUser.objectId != %@", [AuthorizationManager sharedInstance].currentUser.objectId];
                NSArray *filtredArray = [objects filteredArrayUsingPredicate:predicateYourObjs];
                response.objects = [filtredArray randomItemsWithLimit:kRequiredObjectCount];
                response.success = YES;
                
                NSArray *usersToFetch = [Utilities userObjectIdsForImaginaryFriends:response.objects];
                
                [PFObject fetchAllIfNeededInBackground:usersToFetch block:^(NSArray *array, NSError *error) {
                    response.success = array ? YES : NO;
                    response.error = error;
                    if (array.count) {
                        response.additionalInfo = [Utilities onlineStatusDictionaryForUsers:array];
                    }
                    completion(response);
                }];
                
            } else {
                completion(response);
            }
            
        }];
    }];
}


-(int)randomSkipValueWithCount:(int)count rangeLength:(int)rangeLength {
    if (count <= rangeLength) {
        return 0;
    }
    
    return arc4random_uniform(count - rangeLength);
}


- (void)getImaginaryFriendWithObjectId:(NSString *)objectId completionBlock:(RequestCallback)completionBlock {
    PFQuery *query = [PFQuery queryWithClassName:[[ImaginaryFriend class] description]];
    [query whereKey:@"coreDataObjectId" equalTo:objectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        ResponseInfo *responseInfo = [ResponseInfo new];
        if (object) {
            responseInfo.objects = @[object];
            responseInfo.success = YES;
        } else {
            responseInfo.error = error;
            responseInfo.success = NO;
            $l("--- Error -> %@", error.localizedDescription);
        }
        completionBlock(responseInfo);
    }];
}

- (void)deleteImaginaryFriend:(ImaginaryFriend *)imaginaryFriend completionBlock:(RequestCallback)completionBlock {
    [imaginaryFriend deleteInBackgroundWithBlock:^(BOOL success, NSError *error) {
        if (success) {
            [imaginaryFriend unpinInBackground];
        }
        ResponseInfo *resopnse = [ResponseInfo new];
        resopnse.success = success;
        resopnse.error = error;
        completionBlock(resopnse);
    }];
}


- (void)deleteImaginaryFriends:(NSArray *)friends withCompletion:(RequestCallback)completionBlock {
    for (ImaginaryFriend *imFr in friends) {
        imFr.wasDeleted = @(YES);
    }
    [ImaginaryFriend saveAllInBackground:friends block:^(BOOL success, NSError *error) {
        if (success) {
            [PFObject unpinAllInBackground:friends];
        }
        ResponseInfo *resopnse = [ResponseInfo new];
        resopnse.success = success;
        resopnse.error = error;
        completionBlock(resopnse);
    }];
}

- (void)getUsersWithEmails:(NSArray *)emails
                      phones:(NSArray *)phones
             completionBlock:(RequestCallback)completion {
    if (!emails) {
        emails = @[];
    }
    if (!phones) {
        phones = @[];
    }
    
    BOOL noEmailsAndPhoneNumbers = !emails.count && !phones.count;
    if (noEmailsAndPhoneNumbers) {
        completion(nil);
        return;
    }
    
    PFQuery *queryEmails = [PFUser query];
    [queryEmails whereKey:@"email" containedIn:emails];
    
    PFQuery *phoneQuery = [PFUser query];
    [phoneQuery whereKey:@"shortPhoneNumber" containedIn:phones];
    
    NSArray *subQueries = @[queryEmails, phoneQuery];
    PFQuery *query = [PFQuery orQueryWithSubqueries:subQueries];
        query.limit = 1000;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.objects = objects;
        response.success = !error;
        response.error = error;
        completion(response);
    }];
}

- (void)getImaginaryFriendsForUsersEmails:(NSArray *)emails
                             phoneNumbers:(NSArray *)phoneNumbers
                          completionBlock:(RequestCallback)completion {
    [self getUsersWithEmails:emails
                      phones:phoneNumbers
             completionBlock:^(ResponseInfo *response) {
                 if (!response ) {
                     completion(nil);
                     return;
                 }
                 
                 NSDictionary *onlineStatuses = [Utilities onlineStatusDictionaryForUsers:response.objects];
                 if (response.success && response.objects.count > 0) {
                     [AddressBookManager sharedInstance].pfUsers = response.objects;

                     NSPredicate *predicate = [NSPredicate predicateWithFormat:@"publicType != %@ AND wasDeleted != %@",
                                               @(ImaginaryFriendPublicTypePrivate), @(YES)];
                     NSPredicate *predicateYourObjs = [NSPredicate predicateWithFormat:@"attachedToUser.objectId != %@", [AuthorizationManager sharedInstance].currentUser.objectId];
                     PFQuery *query = [PFQuery queryWithClassName:[[ImaginaryFriend class] description]];
                     [query whereKey:attachedToUserCol containedIn:response.objects];
                     [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                         ResponseInfo *responseInfo = [ResponseInfo new];
                         responseInfo.success = !error;
                         responseInfo.error = error;
                         responseInfo.objects = objects;
                         if (objects.count && !error) {
                             NSArray *filtredObjects = [objects filteredArrayUsingPredicate:predicate];
                             filtredObjects = [filtredObjects filteredArrayUsingPredicate:predicateYourObjs];
                             responseInfo.objects = filtredObjects;
                             responseInfo.additionalInfo = onlineStatuses;
                         }
                         completion(responseInfo);
                     }];
                 } else  {
                     if (response.error) {
                         
                     }
                     completion(response);
                 }
             }];
}


- (void)getChatRoomWithRoomJID:(NSString *)roomJID completion:(RequestCallback)completion {
    PFQuery *query = [PFQuery queryWithClassName:[[ChatRoom class] description]];
    [query whereKey:@"roomJID" equalTo:roomJID];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [PFObject pinAllInBackground:objects];
        ResponseInfo *response = [ResponseInfo new];
        response.objects = objects;
        response.error = error;
        response.success = !error;
        completion(response);
    }];
}


- (void)getChatRoomWithParticipants:(NSArray *)participants completion:(RequestCallback)completion {
    PFQuery *query = [PFQuery queryWithClassName:[[ChatRoom class] description]];
    [query whereKey:@"participantsObjectId" containsAllObjectsInArray:participants];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [PFObject pinAllInBackground:objects];
        ResponseInfo *response = [ResponseInfo new];
        response.error = error;
        response.objects = objects;
        response.success = !error;
        if (completion) {
            completion(response);
        }
    }];
}

- (void)deactivateChatRoomsForImaginaryFriend:(ImaginaryFriend *)imaginaryFriend completion:(RequestCallback)completion {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"initiatorImaginaryFriendID = %@ OR receiverImaginaryFriendID = %@", imaginaryFriend.objectId, imaginaryFriend.objectId];
    PFQuery *query = [PFQuery queryWithClassName:[[ChatRoom class] description] predicate:predicate];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        ResponseInfo *response = [ResponseInfo new];
        response.error = error;
        response.success = !error;
        if (error) {
            completion(response);
        } else if (objects) {
            for (ChatRoom *room in objects) {
                room.wasDeactivated = @(YES);
                if (!room.deletedByUser.length) {
                    room.deletedByUser = [AuthorizationManager sharedInstance].currentUser.objectId;
                }else if (room.deletedByUser.length &&
                          ![room.deletedByUser isEqualToString:[AuthorizationManager sharedInstance].currentUser.objectId]) {
                    room.wasDeleted = @(YES);
                }
            }
            [PFObject pinAllInBackground:objects];
            [PFObject saveAllInBackground:objects block:^(BOOL success, NSError *error){
                
                response.success = success;
                response.error = error;
                response.objects = nil;
                completion(response);
            }];
        }
        
        completion(response);
    }];
}

- (void)getChatRoomsForUser:(PFUser *)user withCompletion:(RequestCallback)completion {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"initiatorID = %@ OR receiverID = %@", user.objectId, user.objectId];
    PFQuery *query = [PFQuery queryWithClassName:[[ChatRoom class] description] predicate:predicate];
    query.limit = 1000;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        ResponseInfo *chatRoomsResponse = [ResponseInfo new];
        chatRoomsResponse.error = error;
        NSArray *filtredArr = [Utilities filtredRetreivedChatRooms:objects];
        chatRoomsResponse.objects = filtredArr;
        chatRoomsResponse.success = !error;
        if (chatRoomsResponse.objects.count) {
            NSArray *imFriendsObjectIds = [Utilities imaginaryFriendObjectIdsForChatRooms:chatRoomsResponse.objects];
            [[WebService sharedInstanse] getImaginaryFriendsWithObjectIds:imFriendsObjectIds completion:^(ResponseInfo *imFriendsResponse) {
                ResponseInfo *response = [ResponseInfo new];
                response.success = imFriendsResponse.success;
                response.error = imFriendsResponse.error;
                response.additionalInfo = imFriendsResponse.additionalInfo;
                if (imFriendsResponse.objects.count) {
                    NSArray *chatRooms = [Utilities addParticipants:imFriendsResponse.objects
                                                   toChatRooms:chatRoomsResponse.objects];
                    [PFObject pinAllInBackground:chatRooms];
                    response.objects = chatRooms;
                }
                completion(response);
            }];
            
        } else {
            completion(chatRoomsResponse);
        }
    }];
}


- (void)getImaginaryFriendsWithObjectIds:(NSArray *)objectIds completion:(RequestCallback)completion {
    PFQuery *query = [PFQuery queryWithClassName:[[ImaginaryFriend class] description]];
    query.limit = 1000;
    [query whereKey:objectIdKey containedIn:objectIds];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.error = error;
        response.objects = objects;
        response.success = !error;     
        
        if (objects.count) {
            NSArray *objects = [Utilities userObjectIdsForImaginaryFriends:response.objects];
            [PFObject fetchAllIfNeededInBackground:objects
                                             block:^(NSArray *array, NSError *error) {
                response.additionalInfo = [Utilities onlineStatusDictionaryForUsers:objects];
                completion(response);
            }];
        } else {
            completion(response);
        }
        
        
        if (error) {
            completion(response);
        }
    }];
}


- (void)getUserWithObjectId:(NSString *)objectId completion:(RequestCallback)completion {
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:objectIdKey equalTo:objectId];
    
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.success = !error;
        response.objects = objects;
        response.error = error;
        completion(response);
    }];
}

- (void)getAvatarPhotosForImaginaryFriend:(ImaginaryFriend *)imFriend completion:(RequestCallback)completion {
    PFQuery *query = [PFQuery queryWithClassName:[[AvatarPhoto class] description]];
    [query whereKey:@"imaginaryFriend" equalTo:imFriend];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.success = !error;
        response.objects = objects;
        response.error = error;
        completion(response);
    }];
}

- (void)deleteChatRoom:(ChatRoom *)chatRoom completion:(RequestCallback)completion {
    chatRoom.wasDeleted = @(YES);
    [chatRoom saveInBackgroundWithBlock:^(BOOL success, NSError *error){
        if (success) {
            [chatRoom unpinInBackground];
        }
        ResponseInfo *response = [ResponseInfo new];
        response.success = success;
        response.error = error;
        completion(response);
    }];
}

- (void)sendPushNotificationToUser:(PFUser *)user
           fromImaginaryFriendName:(NSString *)fromImaginaryFriendName
             toImaginaryFriendName:(NSString *)toImaginaryFriendName
                       withMessage:(NSString *)message
                           roomJID:(NSString *)roomJID
                  notificationType:(NSUInteger)notificationType {
    
    if (!roomJID) {
        return;
    }
    if (!fromImaginaryFriendName) {
        fromImaginaryFriendName = @"";
    }
    if (!toImaginaryFriendName) {
        toImaginaryFriendName = @"";
    }
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery  whereKey:@"kCurrentUser" equalTo:user];
    
    
    if (!roomJID || !message) {
        return;
    }
    if (!fromImaginaryFriendName) {
        fromImaginaryFriendName = @"";
    }
    if (!toImaginaryFriendName) {
        toImaginaryFriendName = @"";
    }
    
    NSDictionary *data = @{@"alert" : message,
                           @"badge" : @"Increment",
                           @"roomJID" : roomJID,
                           @"sounds" : @"sms-received1.caf",//@"notification_message_sound.caf",
                           @"fromImaginaryFriendName" : fromImaginaryFriendName,
                           @"toImaginaryFriendName" : toImaginaryFriendName,
                           @"pushNotificationType" : @(notificationType)};
    
    
    PFPush *push = [PFPush new];
    [push setQuery:pushQuery];
    [push setData:data];
    [push sendPushInBackgroundWithBlock:^(BOOL success, NSError *error) {
        
    }];
}

- (void)setAcceptInviteForChatWithRoomJID:(NSString *)roomJID completion:(RequestCallback)completion {
    NSArray *objectIds = [roomJID componentsSeparatedByString:@"_"];
    NSMutableArray *participants = [NSMutableArray arrayWithCapacity:2];
    [participants addObject:objectIds[1]];
    [participants addObject:objectIds[2]];
    [[WebService sharedInstanse] getChatRoomWithParticipants:participants
                                                  completion:^(ResponseInfo *response){
                                                      if (response.objects.count == 1) {
                                                          ChatRoom *chatRoom = [response.objects lastObject];
                                                          chatRoom.wasAcceptedStatus = @(ChatRoomAccepdedStatusAccepted);
                                                          [chatRoom saveInBackgroundWithBlock:^(BOOL success, NSError *error){
                                                              response.success = success;
                                                              response.error = error;
                                                              response.objects = nil;
                                                              completion(response);
                                                          }];
                                                      } else {
                                                          completion(response);
                                                      }
                                                  }];
}

- (void)sendAnswerPushNotification:(BOOL)accepted roomJID:(NSString *)roomJID from:(NSString *)fromImaginaryFriendName to:(NSString *)toImaginaryFriendName {
    NSArray *objectIds = [roomJID componentsSeparatedByString:@"_"];
    
    NSString *receiverObjectId = [objectIds firstObject];
    NSString *pushMsg = accepted ? acceptedInviteToChatMSG : declinedInviteToChatMSG;
    pushMsg = [NSString stringWithFormat:@"%@ %@", fromImaginaryFriendName, pushMsg];
    PushNotificationType pType = accepted ? PushNotificationTypeInviteAccepted : PushNotificationTypeInviteDeclined;
    
    [[WebService sharedInstanse] getUserWithObjectId:receiverObjectId
                                          completion:^(ResponseInfo *response) {
                                              if (response.objects.count == 1) {
                                                  PFUser *toUser = [response.objects lastObject];
                                                  [[WebService sharedInstanse] sendPushNotificationToUser:toUser
                                                                                  fromImaginaryFriendName:fromImaginaryFriendName
                                                                                    toImaginaryFriendName:toImaginaryFriendName
                                                                                              withMessage:pushMsg
                                                                                                  roomJID:roomJID
                                                                                         notificationType:pType];
                                              }
                                          }];
}

- (void)saveChatPhoto:(ChatPhoto *)chatPhoto completion:(RequestCallback)completion {
    if (!chatPhoto) {
        completion(nil);
    }
    [chatPhoto saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        [chatPhoto pinInBackground];
        ResponseInfo *response = [ResponseInfo new];
        response.success = success;
        response.error = error;
        completion(response);
    }];
}

- (void)sendComplaint:(Complaint *)complaint completion:(RequestCallback)completion {
    if (!complaint) {
        completion(nil);
        return;
    }
    
    [complaint saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.success = success;
        response.error = error;
        completion(response);
    }];
}


- (void)saveAvatarPhoto:(AvatarPhoto *)avatarPhoto forImaginaryFriend:(ImaginaryFriend *)imFriend completion:(RequestCallback)completion {
    if (!avatarPhoto || !imFriend) {
        return;
    }
    
    avatarPhoto.imaginaryFriend = imFriend;
    if (imFriend.avatarPhoto) {
        imFriend.avatarPhoto.fullImage = avatarPhoto.fullImage;
        imFriend.avatarPhoto.thumbnailImage = avatarPhoto.thumbnailImage;
    } else {
        imFriend.avatarPhoto = avatarPhoto;
    }
    
    
    [imFriend saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.success = success;
        response.error = error;
        completion(response);
    }];
}

- (void)saveImaginaryFriend:(ImaginaryFriend *)imFriend withAvatarPhoto:(AvatarPhoto *)avatarPhoto completion:(RequestCallback)completion {
    [imFriend saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.success = success;
        response.error = error;
        if (!avatarPhoto || !success) {
            completion(response);
        } else if (success && avatarPhoto) {
            [[WebService sharedInstanse] saveAvatarPhoto:avatarPhoto
                                      forImaginaryFriend:imFriend
                                              completion:^(ResponseInfo *response2) {
                                                  completion(response2);
                                              }];
        }
        
    }];
}

- (void)savePFInstallationForUser:(PFUser *)user completion:(RequestCallback)completion {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSData *deviceToken = appDelegate.deviceToken;
    if (!user || !deviceToken) {
        completion(nil);
        return;
    }
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    currentInstallation.currentUser = [AuthorizationManager sharedInstance].currentUser;
    [currentInstallation saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.success = success;
        response.error = error;
        completion(response);
    }];
}


#pragma mark - Private methods

- (void)getUsersForObjectIds:(NSArray *)objectIds completion:(RequestCallback)completion {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", objectIdKey, objectIds];
    PFQuery *query = [PFQuery queryWithClassName:@"_User" predicate:predicate];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.error = error;
        if (!error) {
            response.success = YES;
        }
        response.objects = objects;
        if (response.error) {
            $l("error - > %@", error.localizedDescription);
        }
        completion(response);
    }];
}

- (NSArray *)filtredWasDeletedImaginaryFriends:(NSArray *)imagFriends {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"wasDeleted != %@", @(YES)];
    NSArray *filtredArr = [imagFriends filteredArrayUsingPredicate:predicate];
    return filtredArr;
}

-(void) createAndSaveUserSerttingsForUser:(PFUser *)user completion:(RequestCallback)completionBlock {
    CDUserSettings *userSettings = [[CoreDataManager sharedInstance] userSettingsWithUserId:user.objectId email:user.email];
    PFObject *settings = [PFObject objectWithClassName:userSettingsClass];
    settings[attachedToUserCol] = user;
    settings[usersNameCol] = userSettings.userName;
    settings[friendsNameCol] = userSettings.friendName;
    settings[friendsAgeCol] = userSettings.friendAge;
    settings[friendsPersonalityCol] = userSettings.friendPersonality;
    settings[friendsOccupationCol] = userSettings.friendOccupation;
    [settings saveInBackgroundWithBlock:^(BOOL succeded, NSError *error) {
        ResponseInfo *responce = [[ResponseInfo alloc] init];
        responce.success = succeded;
        responce.error = error;
        responce.objects = @[settings];
        completionBlock (responce);
        if (error) {
            $l("--Error - %@", [error localizedDescription]);
        }
    }];
}

@end
