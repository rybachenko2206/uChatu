//
//  WebService.h
//  uChatu
//
//  Created by Roman Rybachenko on 11/27/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


@class ResponseInfo;
@class ImaginaryFriend;
@class ChatRoom;
@class ChatPhoto;
@class AvatarPhoto;
@class Complaint;

#import "PrefixHeader.pch"
#import <Parse/Parse.h>
#import <Foundation/Foundation.h>


//typedef void (^RequestCallback) (ResponseInfo *responseInfo);


@interface WebService : NSObject

+(WebService *) sharedInstanse;

-(BOOL) isLoggedIn;
-(void) logOut;
-(void) trackTimeWhenUserLogin;
-(void) signUpWithUsername:(NSString *)username email:(NSString *)email password:(NSString *)password completion:(RequestCallback)completionBlock;
-(void) logInWithEmail:(NSString *)email password:(NSString *)password completion:(RequestCallback)completionBlock;
-(void) requestPasswordResetForEmail:(NSString *)email completion:(RequestCallback)completionBlock;
-(void) updateCurrentUserWithBlock:(RequestCallback)completionBlock;

-(void) getUserSettingsWithBlock:(RequestCallback)completionBlock;
-(void) updateUserSettingsWithUserAvatar:(BOOL)withUserAvatar withFriendAvatar:(BOOL)withFriendAvatar;
-(void) getFriendsAvatarImageForObject:(PFObject *)pfUserSetting withBlock:(RequestCallback)completionBlock;
-(void) getUserAvatarImageForObject:(PFObject *)pfUserSetting withBlock:(RequestCallback)completionBlock;
-(void) sendUserAvatarImageToObject:(PFObject *)object;
-(void) sendFriendsAvatarImageToObject:(PFObject *)object;

///////////////////////////////////////////////////////////////////////////////////////////
- (void)isExistUserWithEmail:(NSString *)email completion:(RequestCallback)completionBlock;
- (void)isExistUserWithPhone:(NSString *)phoneNumber completion:(RequestCallback)completionBlock;
- (void)getImaginaryFriendsForUsersEmails:(NSArray *)emails
                             phoneNumbers:(NSArray *)phoneNumbers
                          completionBlock:(RequestCallback)completion;
- (void)getAllVisibleImaginaryFriendsForUser:(PFUser *)user completionBlock:(RequestCallback)completionBlock;
- (void)getRandomImaginaryFriendsWithCompletion:(RequestCallback)completion;
- (void)getAllImaginaryFriendsForUser:(PFUser *)user completionBlock:(RequestCallback)completionBlock;
- (void)getImaginaryFriendWithObjectId:(NSString *)objectId completionBlock:(RequestCallback)completionBlock;
- (void)getFriendAvatarImageForImaginaryFriend:(ImaginaryFriend *)imaginaryFriend withBlock:(RequestCallback)completionBlock;
- (void)getUserAvatarImageForUser:(PFUser *)user withBlock:(RequestCallback)completionBlock;
- (void)deleteImaginaryFriend:(ImaginaryFriend *)imaginaryFriend completionBlock:(RequestCallback)completionBlock;
- (void)deleteImaginaryFriends:(NSArray *)friends withCompletion:(RequestCallback)completionBlock;
- (void)deleteChatRoom:(ChatRoom *)chatRoom completion:(RequestCallback)completion;
- (void)uploadFriendAvatarImage:(UIImage *)image forImaginaryFriend:(ImaginaryFriend *)imaginaryFriend withBlock:(RequestCallback)completionBlock;
- (void)uploadUserAvatarImage:(UIImage *)image withBlock:(RequestCallback)completionBlock;
- (void)getChatRoomWithParticipants:(NSArray *)participants completion:(RequestCallback)completion;
- (void)getChatRoomsForUser:(PFUser *)user withCompletion:(RequestCallback)completion;
- (void)getImaginaryFriendsWithObjectIds:(NSArray *)objectIds completion:(RequestCallback)completion;
- (void)getUserWithObjectId:(NSString *)objectId completion:(RequestCallback)completion;
- (void)getAvatarPhotosForImaginaryFriend:(ImaginaryFriend *)imFriend completion:(RequestCallback)completion;
- (void)getChatRoomWithRoomJID:(NSString *)roomJID completion:(RequestCallback)completion;
- (void)setAcceptInviteForChatWithRoomJID:(NSString *)roomJID completion:(RequestCallback)completion;
- (void)deactivateChatRoomsForImaginaryFriend:(ImaginaryFriend *)imaginaryFriend completion:(RequestCallback)completion;

- (void)saveChatPhoto:(ChatPhoto *)chatPhoto completion:(RequestCallback)completion;
- (void)saveImaginaryFriend:(ImaginaryFriend *)imFriend withAvatarPhoto:(AvatarPhoto *)avatarPhoto completion:(RequestCallback)completion;
- (void)saveAvatarPhoto:(AvatarPhoto *)avatarPhoto forImaginaryFriend:(ImaginaryFriend *)imFriend completion:(RequestCallback)completion;
- (void)savePFInstallationForUser:(PFUser *)user completion:(RequestCallback)completion;
- (void)sendComplaint:(Complaint *)complaint completion:(RequestCallback)completion;

- (void)sendAnswerPushNotification:(BOOL)accepted
                           roomJID:(NSString *)roomJID
                              from:(NSString *)fromImaginaryFriendName
                                to:(NSString *)toImaginaryFriendName;

- (void)sendPushNotificationToUser:(PFUser *)user
           fromImaginaryFriendName:(NSString *)fromImaginaryFriendName
             toImaginaryFriendName:(NSString *)toImaginaryFriendName
                       withMessage:(NSString *)message
                           roomJID:(NSString *)roomJID
                  notificationType:(NSUInteger)notificationType;

@end
