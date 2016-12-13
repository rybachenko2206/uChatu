//
//  ChatRoom.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/11/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "ImaginaryFriend.h"
#import "PrefixHeader.pch"
#import "WebService.h"
#import "AuthorizationManager.h"

#import "ChatRoom.h"


@implementation ChatRoom

//TODO: Треба participantsImaginaryFriends зробити не @synthesize, a @dynamic, як колонка в таблиці і при отриманні chatRooms робити fetchAllInBackground..


@dynamic roomId;
@dynamic userIds;
@dynamic initiatorID;
@dynamic initiatorImaginaryFriendID;
@dynamic receiverImaginaryFriendID;
@dynamic receiverID;
@dynamic lastMessage;
@dynamic roomJID;
@dynamic wasDeactivated;
@dynamic participantsObjectId;
@dynamic wasAcceptedStatus;
@dynamic wasDeleted;
@dynamic deletedByUser;
@dynamic unreadMessagesCountReceiver;
@dynamic unreadMessagesCountInitiator;

@synthesize participantsImaginaryFriends;
@synthesize companionImFriend;
@synthesize wasDeactivatedBoolValue;


#pragma mark - Parse Initializtion

+ (void)load {
    [self registerSubclass];
}


+ (NSString *)parseClassName {
    return @"ChatRoom";
}


#pragma mark - Static methods

+ (instancetype)chatRoomWithInitiator:(ImaginaryFriend *)initiator receiver:(ImaginaryFriend *)receiver {
    ChatRoom *room = [ChatRoom object];
    room.wasAcceptedStatus = @(ChatRoomAccepdedStatusAccepted);
    
    room.initiatorID = initiator.attachedToUser.objectId;
    room.initiatorImaginaryFriendID = initiator.objectId;
    
    room.receiverID = receiver.attachedToUser.objectId;
    room.receiverImaginaryFriendID = receiver.objectId;
    room.participantsObjectId = @[initiator.objectId, receiver.objectId];
    
    room.roomJID = [self roomJIDWithInitiator:initiator receiver:receiver];
    
    return room;
}

+ (NSString *)roomJIDWithInitiator:(ImaginaryFriend *)initiator receiver:(ImaginaryFriend *)receiver {
    NSMutableArray *components = [NSMutableArray new];
    [components addObject:initiator.attachedToUser.objectId];
    [components addObject:initiator.objectId];
    [components addObject:receiver.objectId];
    [components addObject:receiver.attachedToUser.objectId];
    
    return [components componentsJoinedByString:@"_"];
}

+ (BOOL)isMyImFriendInitiatorInChatRoom:(ChatRoom *)chatRoom {
    return [chatRoom.initiatorID isEqualToString:[AuthorizationManager sharedInstance].currentUser.objectId] ? YES : NO;
}

+ (void)getChatRoomWithInitiator:(ImaginaryFriend *)initiator
                        receiver:(ImaginaryFriend *)receiver
                 completionBlock:(void (^)(ChatRoom *room, NSError *error))completion {
    
    [[WebService sharedInstanse] getChatRoomWithParticipants:@[initiator.objectId, receiver.objectId]
                                                  completion:^(ResponseInfo *response){
                                                      if (response.success && response.objects.count) {
                                                          ChatRoom *fetchedRoom = [response.objects lastObject];
                                                          [fetchedRoom saveInBackground];
                                                          completion(fetchedRoom, nil);
                                                      } else if (response.success && !response.objects.count) {
                                                          ChatRoom *newRoom = [ChatRoom chatRoomWithInitiator:initiator receiver:receiver];
                                                          [newRoom saveInBackground];
                                                          [newRoom pinInBackground];
                                                          completion(newRoom, nil);
                                                      } else if (response.error) {
                                                          completion(nil, response.error);
                                                      }
                                                  }];
}

+ (void)deleteChatRooms:(NSArray *)rooms withCompletionBlock:(void(^)(BOOL success, NSError *error))comletion {
    PFUser *currUser =[AuthorizationManager sharedInstance].currentUser;
    for (ChatRoom *chRoom in rooms) {
        chRoom.wasDeactivated = @(YES);
        if (chRoom.deletedByUser.length && ![chRoom.deletedByUser isEqualToString:currUser.objectId]) {
            chRoom.wasDeleted = @(YES);
        } else if (!chRoom.deletedByUser.length){
            chRoom.deletedByUser = currUser.objectId;
        }
    }
    [ChatRoom saveAllInBackground:rooms block:^(BOOL success, NSError *error) {
        comletion(success, error);
    }];
}

- (ImaginaryFriend *)yourImaginaryFriend {
    if (!participantsImaginaryFriends.count) {
        return nil;
    }
    NSInteger index = [self.participantsImaginaryFriends indexOfObject:[self companionImFriend]];
    ImaginaryFriend *imFr = index == 0 ? self.participantsImaginaryFriends[1] : self.participantsImaginaryFriends[0];
        
    return imFr;
}


#pragma mark - Getter methods

- (ImaginaryFriend *)companionImFriend {
    if (self.participantsImaginaryFriends.count < 2) {
        return nil;
    }
    
    ImaginaryFriend *first = [self.participantsImaginaryFriends firstObject];
    ImaginaryFriend *second = self.participantsImaginaryFriends.count == 2 ? [self.participantsImaginaryFriends objectAtIndex:1] : nil;
    
    if ([first.attachedToUser.objectId isEqualToString:[AuthorizationManager sharedInstance].currentUser.objectId]) {
        companionImFriend = second;
    } else  {
        companionImFriend = first;
    }
    
    return companionImFriend;
}


- (BOOL)wasDeactivatedBoolValue {
    wasDeactivatedBoolValue = [self.wasDeactivated boolValue];
    return wasDeactivatedBoolValue;
}


#pragma mark - Interface methods

- (void)deleteChatRoom {
    PFUser *currUser =[AuthorizationManager sharedInstance].currentUser;
    self.wasDeactivated = @(YES);
    if (self.deletedByUser.length && ![self.deletedByUser isEqualToString:currUser.objectId]) {
        self.wasDeleted = @(YES);
    } else if (!self.deletedByUser.length){
        self.deletedByUser = currUser.objectId;
    }
    
    [self saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        if (error) {
            [Utilities showAlertViewWithTitle:@"Error!"
                                      message:[error localizedDescription]
                            cancelButtonTitle:@"Cancel"];
        }
    }];
}

@end
