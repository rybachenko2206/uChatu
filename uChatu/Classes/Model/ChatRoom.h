//
//  ChatRoom.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/11/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import <Parse/PFObject+Subclass.h>
#import <Parse/Parse.h>

#import <UIKit/UIKit.h>

@class ImaginaryFriend;

@interface ChatRoom : PFObject <PFSubclassing>

@property (strong, nonatomic) NSString *roomId;
@property (strong, nonatomic) NSArray *userIds;
@property (strong, nonatomic) NSString *initiatorID;
@property (strong, nonatomic) NSString *initiatorImaginaryFriendID;
@property (strong, nonatomic) NSString *receiverImaginaryFriendID;
@property (strong, nonatomic) NSString *receiverID;
@property (strong, nonatomic) NSString *lastMessage;
@property (strong, nonatomic) NSString *roomJID;
@property (assign, nonatomic) NSNumber *wasDeactivated;
@property (assign, nonatomic) NSNumber *wasDeleted;
@property (strong, nonatomic) NSString *deletedByUser;
@property (assign, nonatomic) NSNumber *wasAcceptedStatus;
@property (strong, nonatomic) NSArray *participantsObjectId;
@property (strong, nonatomic) NSArray *participantsImaginaryFriends;
@property (strong, nonatomic) ImaginaryFriend *companionImFriend;
@property (strong, nonatomic) NSNumber *unreadMessagesCountReceiver;
@property (strong, nonatomic) NSNumber *unreadMessagesCountInitiator;
@property (nonatomic, assign) BOOL wasDeactivatedBoolValue;

+ (NSString *)parseClassName;

+ (instancetype)chatRoomWithInitiator:(ImaginaryFriend *)initiator
                             receiver:(ImaginaryFriend *)receiver;
+ (NSString *)roomJIDWithInitiator:(ImaginaryFriend *)initiator
                          receiver:(ImaginaryFriend *)receiver;

+ (BOOL)isMyImFriendInitiatorInChatRoom:(ChatRoom *)chatRoom;

+ (void)getChatRoomWithInitiator:(ImaginaryFriend *)initiator
                        receiver:(ImaginaryFriend *)receiver
                 completionBlock:(void (^)(ChatRoom *room, NSError *error))completion;
+ (void)deleteChatRooms:(NSArray *)rooms withCompletionBlock:(void(^)(BOOL success, NSError *error))comletion;

- (void)deleteChatRoom;
- (ImaginaryFriend *)yourImaginaryFriend;


@end
