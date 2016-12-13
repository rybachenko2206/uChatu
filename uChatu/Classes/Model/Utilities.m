//
//  Utilities.m
//  uChatu
//
//  Created by Roman Rybachenko on 11/27/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#define kEmailRegex @"^[a-zA-Z0-9_-]+(\\.[a-zA-Z0-9_-]+)*@[a-zA-Z0-9-]+(\\.[a-zA-Z0-9_-]+)*\\.([a-zA-Z]{2,})$"
#define kPasswordRegex @"/^[a-zA-Z0-9]{3,32}$/"


#import "AddressBookUser.h"
#import <AddressBook/AddressBook.h>
#import <Parse/Parse.h>
#import "UIImage+Resize.h"
#import "LoginViewController.h"
#import "PrefixHeader.pch"
#import "CDUser.h"
#import "AuthorizationManager.h"
#import "ChatRoom.h"
#import "ImaginaryFriend.h"
#import "PFUser+Additions.h"
#import "ReachabilityManager.h"

#import "Utilities.h"

@implementation Utilities



+ (BOOL)isEmailValid:(NSString *)email {
    return [Utilities string:email matchesRegex:kEmailRegex];
}

+ (BOOL)isPasswrdValid:(NSString *)password {
    return [Utilities string:password matchesRegex:kPasswordRegex];
}


+ (void)showAlertViewWithTitle:(NSString *)title
                       message:(NSString *)message
             cancelButtonTitle:(NSString *)buttonTitle {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:buttonTitle
                                          otherButtonTitles:nil, nil];
    [alert show];
}

+ (void)dismissAlertViewIfShowing {
    for (UIWindow* window in [UIApplication sharedApplication].windows) {
        NSArray* subviews = window.subviews;
        if ([subviews count] > 0) {
            for (UIView *subview in subviews) {
                if ([subview isKindOfClass:[UIAlertView class]]) {
                    [(UIAlertView *)subview dismissWithClickedButtonIndex:[(UIAlertView *)[subviews objectAtIndex:0] cancelButtonIndex] animated:YES];
                }
            }
//            if ([[subviews objectAtIndex:0] isKindOfClass:[UIAlertView class]]) {
//                [(UIAlertView *)[subviews objectAtIndex:0] dismissWithClickedButtonIndex:[(UIAlertView *)[subviews objectAtIndex:0] cancelButtonIndex] animated:YES];
//            }
        }
    }
}

+ (NSString *)getPathToDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (UIImage *)getImageWithName:(NSString *)imageName {
    UIImage *image = nil;
    NSString *path = [Utilities pathToImageWithName:imageName
                                             userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
    image = [Utilities getAvatarImageAtPath:path];
    return image;
}

+ (NSString *)pathToImageWithName:(NSString *)imageName userId:(NSString *)userId {
    if (!imageName) {
        return nil;
    }
    NSString *path = [Utilities getPathToDocumentsDirectory];
    path = [path stringByAppendingPathComponent:userId];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
        
        if (error) {
            $l(@" ---- Creating folder error -> %@", [error localizedDescription]);
            return nil;
        }
    }
    path = [path stringByAppendingPathComponent:imageName];
    path = [path stringByAppendingPathExtension:@"png"];
    
    return path;
}

+(NSString *) pathToFriendAvatarImageForUserWithId:(NSString *)userId {
    NSString * path = [Utilities getPathToDocumentsDirectory];
    path = [path stringByAppendingPathComponent:userId];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
        
        if (error) {
            $l(@" ---- Creating folder error -> %@", [error localizedDescription]);
            return nil;
        }
    }
    path = [path stringByAppendingPathComponent:friendAvatarFileName];
    
    return path;
}

+ (UIImage *)getAvatarImageAtPath:(NSString *)path {
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    return image;
}

+ (BOOL)saveImage:(UIImage *)image atPath:(NSString *)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path
                                                   error:nil];
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    
    BOOL isSavedSuccessfully = [imageData writeToFile:path atomically:NO];
    return isSavedSuccessfully;
}


+(NSString *) pathToUserAvatarImageForUserWithId:(NSString *)userId {
    NSString * path = [Utilities getPathToDocumentsDirectory];
    path = [path stringByAppendingPathComponent:userId];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
        
        if (error) {
            $l(@" ---- Creating folder error -> %@", [error localizedDescription]);
            return nil;
        }
    }
    path = [path stringByAppendingPathComponent:userAvatarFileName];
    
    return path;
}

+(UIImage *) getUserAvatarImageForUserWithId:(NSString *)userId {
    NSString *filePath = [Utilities pathToUserAvatarImageForUserWithId:userId];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    return image;
}

+(UIImage *) getFriendAvatarImageForUserWithId:(NSString *)userId {
    NSString *filePath = [Utilities pathToFriendAvatarImageForUserWithId:userId];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    return image;
}

+ (UIImage *)generateThumbnailImageFromImage:(UIImage *)fullImage {
    UIImage *thmgImage = [fullImage resizedImageToFitInSize:CGSizeMake(150, 150) scaleIfSmaller:NO];
    return thmgImage;
}

+ (UIImage *)generateFullScreenImageFromImage:(UIImage *)startImage {
    UIImage *fullImage = [startImage resizedImageToFitInSize:CGSizeMake(600, 600) scaleIfSmaller:NO];
    return fullImage;
}

+ (NSString *)getAgeStringForValue:(NSNumber *)ageValue {
    NSInteger age = [ageValue integerValue];
    NSString *ageString = @"";
    if (age > 0) {
        NSString *yearWord = age == 1 ? @"year" : @"years";
        ageString = [NSString stringWithFormat:@"%ld %@", (long)age, yearWord];
    }
    return ageString;
}

+ (NSString *)getNewGUID {
    NSUUID  *UUID = [NSUUID UUID];
    NSString* stringUUID = [UUID UUIDString];
    return stringUUID;
}

+ (NSString *)shortPhoneNumberFromNumber:(NSString *)phoneNumber {
    if (!phoneNumber) {
        return nil;
    }
    NSString *simpleNumber = @"";
    if (phoneNumber.length >= 10) {
        simpleNumber = [phoneNumber substringFromIndex:phoneNumber.length - 10];
    }
    return simpleNumber;
}

+ (void)requestAccesToAddressBookWithCompletion:(void(^)(BOOL finished))completion {
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    switch (ABAddressBookGetAuthorizationStatus()) {
            
        case kABAuthorizationStatusNotDetermined:
        case kABAuthorizationStatusDenied: {
            ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(YES);
                });
            });
        }
            break;
            
        case kABAuthorizationStatusAuthorized:
            $l("AccesToAddressBook authorized");
            completion(YES);
            break;
            
        case kABAuthorizationStatusRestricted:
            $l("AccesToAddressBook Restricted");
            break;
            
        default:
            break;
    }

}

+ (void)handlePostResult:(SLComposeViewControllerResult)result {
    switch (result) {
        case SLComposeViewControllerResultDone:
            if ([[ReachabilityManager sharedInstance] isReachable]) {
                [Utilities showAlertViewWithTitle:@""
                                          message:@"Posted"
                                cancelButtonTitle:@"OK"];
            } else {
                [Utilities showAlertViewWithTitle:@""
                                          message:@"Post Canceled\nInternetConnection failed"
                                cancelButtonTitle:@"OK"];
            }
            break;
            
        case SLComposeViewControllerResultCancelled:
            [Utilities showAlertViewWithTitle:@""
                                      message:@"Post Canceled"
                            cancelButtonTitle:@"OK"];
            break;
            
        default:
            break;
    }
}

+ (NSArray *)filtredRetreivedChatRooms:(NSArray *)allChatRooms {
    NSArray *visibleRooms = nil;
    PFUser *currUser = [AuthorizationManager sharedInstance].currentUser;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastMessage != nil AND deletedByUser != %@ AND wasDeleted != %@", currUser.objectId, @(YES)];
    visibleRooms = [allChatRooms filteredArrayUsingPredicate:predicate];
    
    return visibleRooms;
}

+ (NSArray *)userObjectIdsForImaginaryFriends:(NSArray *)imFriends {
    NSMutableSet *userIds = [NSMutableSet new];
    for (ImaginaryFriend *friend in imFriends) {
        [userIds addObject:friend.attachedToUser];
    }
    
    return [userIds allObjects];
}

+ (NSDictionary *)onlineStatusDictionaryForUsers:(NSArray *)users {
    NSMutableDictionary *onlineStatusDict = [NSMutableDictionary new];
    for (PFUser *user in users) {
        NSNumber *isOnlineNum = user.isOnline ? user.isOnline : @(NO);
        [onlineStatusDict setObject:isOnlineNum forKey:user.objectId];
    }
    
    return (NSDictionary *)onlineStatusDict;
}

+ (NSArray *)imaginaryFriendObjectIdsForChatRooms:(NSArray *)rooms {
    NSMutableArray *objIds = [NSMutableArray new];
    for (ChatRoom *room in rooms) {
        [objIds addObject:room.initiatorImaginaryFriendID];
        [objIds addObject:room.receiverImaginaryFriendID];
    }
    
    return [NSArray arrayWithArray:objIds];
}

+ (NSArray *)addParticipants:(NSArray *)imFriends toChatRooms:(NSArray *)chatRooms {
    for (ChatRoom *room in chatRooms) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@ OR %K = %@", objectIdKey, room.initiatorImaginaryFriendID, objectIdKey, room.receiverImaginaryFriendID];
        NSArray *filtredArray = [imFriends filteredArrayUsingPredicate:predicate];
        NSSet *filtredSet = [NSSet setWithArray:filtredArray];
        room.participantsImaginaryFriends = [filtredSet allObjects];
        [room companionImFriend];
    }
    
    return chatRooms;
}

+ (void)showAlertWithParseError:(NSError *)error {
    NSString *errorMessage = @"";
    switch ((TBParseError)error.code) {
        case TBParseError_ConnectionFailed:
            errorMessage = @"Сonnection to the server failed. Try again later";
            break;
            
        case TBParseError_Timeout:
            errorMessage = @"The request timed out on the server. Check your internet connection and try again";
            break;
            
        default: {
            errorMessage = [NSString stringWithFormat:@"Error - %@\n error code = %ld", [error localizedDescription], (long)error.code];
            break;
        }
    }
    [Utilities showAlertViewWithTitle:@"Error"
                              message:errorMessage
                    cancelButtonTitle:@"OK"];
}


#pragma mark - Private methods

+(BOOL) string:(NSString *)str matchesRegex:(NSString *)regex {
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex] evaluateWithObject:str];
}




@end
