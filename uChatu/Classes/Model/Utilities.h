//
//  Utilities.h
//  uChatu
//
//  Created by Roman Rybachenko on 11/27/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

@class CDUser;
@class ChatRoom;
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Social/Social.h>

@interface Utilities : NSObject

+(BOOL) isEmailValid:(NSString *)email;
+(BOOL) isPasswrdValid:(NSString *)password;
+(NSString *)getPathToDocumentsDirectory;
+(NSString *) pathToFriendAvatarImageForUserWithId:(NSString *)userId;
+(NSString *) pathToUserAvatarImageForUserWithId:(NSString *)userId;
+(UIImage *) getUserAvatarImageForUserWithId:(NSString *)userId;
+(UIImage *) getFriendAvatarImageForUserWithId:(NSString *)userId;

+ (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)buttonTitle;
+ (void)dismissAlertViewIfShowing;

+ (UIImage *)generateThumbnailImageFromImage:(UIImage *)fullImage;
+ (UIImage *)generateFullScreenImageFromImage:(UIImage *)startImage;
+ (void)requestAccesToAddressBookWithCompletion:(void(^)(BOOL finished))completion;
+ (NSString *)getNewGUID;
+ (UIImage *)getImageWithName:(NSString *)imageName;
+ (NSString *)pathToImageWithName:(NSString *)imageName userId:(NSString *)userId;
+ (UIImage *)getAvatarImageAtPath:(NSString *)path;
+ (BOOL)saveImage:(UIImage *)image atPath:(NSString *)path;
+ (NSString *)getAgeStringForValue:(NSNumber *)ageValue;
+ (NSString *)shortPhoneNumberFromNumber:(NSString *)phoneNumber;

+ (NSArray *)filtredRetreivedChatRooms:(NSArray *)allChatRooms;
+ (NSArray *)userObjectIdsForImaginaryFriends:(NSArray *)imFriends;
+ (NSDictionary *)onlineStatusDictionaryForUsers:(NSArray *)users;
+ (NSArray *)imaginaryFriendObjectIdsForChatRooms:(NSArray *)rooms;
+ (NSArray *)addParticipants:(NSArray *)imFriends toChatRooms:(NSArray *)chatRooms;
+ (void)handlePostResult:(SLComposeViewControllerResult)result;
+ (void)showAlertWithParseError:(NSError *)error;

@end
