//
//  LocalDSManager.m
//  uChatu
//
//  Created by Roman Rybachenko on 4/6/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "ChatRoom.h"
#import "ChatPhoto.h"
#import "UChatuMessage.h"
#import "ImaginaryFriend.h"

#import "LocalDSManager.h"


@implementation LocalDSManager

#pragma mark - Allocators

+ (LocalDSManager *)sharedInstanse {
    static LocalDSManager *_sharedInstanse = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstanse = [[LocalDSManager alloc] init];
    });
    return _sharedInstanse;
}


#pragma mark - Interface methods

- (void)fetchChatRoomsForPFUser:(PFUser *)user completion:(RequestCallback)completion {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"initiatorID = %@ OR receiverID = %@", user.objectId, user.objectId];
    PFQuery *query = [PFQuery queryWithClassName:[[ChatRoom class] description] predicate:predicate];
    [query fromLocalDatastore];
    query.limit = 1000;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        ResponseInfo *chatRoomsResponse = [ResponseInfo new];
        chatRoomsResponse.error = error;
        NSArray *filtredArr = [Utilities filtredRetreivedChatRooms:objects];
        chatRoomsResponse.objects = filtredArr;
        chatRoomsResponse.success = !error;
        
        if (chatRoomsResponse.objects.count) {
            NSArray *imFriendsObjectIds = [Utilities imaginaryFriendObjectIdsForChatRooms:chatRoomsResponse.objects];
            [[LocalDSManager sharedInstanse] fetchImaginaryFriendsWithObjectIds:imFriendsObjectIds completion:^(ResponseInfo *imFriendsResponse) {
                ResponseInfo *response = [ResponseInfo new];
                response.success = imFriendsResponse.success;
                response.error = imFriendsResponse.error;
                response.additionalInfo = imFriendsResponse.additionalInfo;
                if (imFriendsResponse.objects.count) {
                    NSArray *chatRooms = [Utilities addParticipants:imFriendsResponse.objects
                                                   toChatRooms:chatRoomsResponse.objects];
                    response.objects = chatRooms;
                }
                completion(response);
            }];
            
        } else {
            completion(chatRoomsResponse);
        }
    }];
}

//- (void)uChatuMessagesFromLocalDataStoreWithChatRoom:(ChatRoom *)chatRoom completion:(RequestCallback)completion {
//    PFQuery *localQuery = [PFQuery queryWithClassName:[[UChatuMessage class] description]];
//    [localQuery fromLocalDatastore];
//    [localQuery whereKey:@"attachedToChatRoom" equalTo:chatRoom];
//    
//    [localQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//        ResponseInfo *response = [ResponseInfo new];
//        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:createdAtKey ascending:YES];
//        response.objects = [objects sortedArrayUsingDescriptors:@[sortDescriptor]];
//        response.error = error;
//        response.success = !error;
//        completion(response);
//    }];
//}
//
//- (void)isExistMessageWithBody:(NSString *)messageBody completion:(RequestCallback)completion {
//    if (!messageBody) {
//        completion(nil);
//    }
//    PFQuery *query = [PFQuery queryWithClassName:[[UChatuMessage class] description]];
//    [query fromLocalDatastore];
//    [query whereKey:@"messageBody" equalTo:messageBody];
//    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//        ResponseInfo *response = [ResponseInfo new];
//        response.success = !error;
//        response.error = error;
//        response.objects = objects;
//        completion(response);
//    }];
//}
//
//- (void)pinInBackgroundUChatuMessage:(UChatuMessage *)message {
//    [self isExistMessageWithBody:message.messageBody
//                      completion:^(ResponseInfo *response) {
//                          if (response.success && !response.objects.count) {
//                              [message pinInBackground];
//                          }
//                      }];
//}

- (void)fetchImaginaryFriendsWithObjectIds:(NSArray *)objectIds completion:(RequestCallback)completion {
    PFQuery *query = [PFQuery queryWithClassName:[[ImaginaryFriend class] description]];
    query.limit = 1000;
    [query fromLocalDatastore];
    [query whereKey:objectIdKey containedIn:objectIds];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.error = error;
        response.objects = objects;
        response.success = !error;
        
        if (objects.count) {
            NSArray *objIds = [Utilities userObjectIdsForImaginaryFriends:response.objects];
            [self fetchUsersForObjectIds:objIds completion:^(ResponseInfo *usersResponse) {
                response.success = usersResponse.success;
                response.error = usersResponse.error;
                if (usersResponse.objects.count) {
                    response.additionalInfo = [Utilities onlineStatusDictionaryForUsers:usersResponse.objects];
                }
                completion(response);
            }];
        }
        
        if (error) {
            completion(response);
        }
    }];
}


#pragma mark - Private methods

- (void)fetchUsersForObjectIds:(NSArray *)objectIds completion:(RequestCallback)completion {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", objectIdKey, objectIds];
    PFQuery *query = [PFQuery queryWithClassName:@"_User" predicate:predicate];
    [query fromLocalDatastore];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        ResponseInfo *response = [ResponseInfo new];
        response.error = error;
        if (!error) {
            response.success = YES;
            [PFUser pinAllInBackground:objects];
        }
        response.objects = objects;
        if (response.error) {
            $l("error - > %@", error.localizedDescription);
        }
        completion(response);
    }];
}

@end
