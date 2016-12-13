//
//  CDChatRoom.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/19/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "PrefixHeader.pch"

#import "CDChatRoom.h"
#import "CDImaginaryFriend.h"
#import "CDUser.h"


@implementation CDChatRoom

@dynamic updatedAt;
@dynamic roomId;
@dynamic imaginaryFriends;
@dynamic messages;

#pragma mark - Static methods

+ (CDChatRoom *)chatRoomWithImaginaryFriends:(NSSet *)imaginaryFriends inContext:(NSManagedObjectContext *)context {
    CDChatRoom *chatRoom = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[CDChatRoom class] description] inManagedObjectContext:context];
    [fetchRequest setEntity:entityDescription];
    
    
    NSMutableArray *predicates = [NSMutableArray new];
    for (CDImaginaryFriend *imFriend in imaginaryFriends) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"ANY imaginaryFriends.objectId MATCHES %@", imFriend.objectId]];
    }
    NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    [fetchRequest setPredicate:compoundPredicate];
    
    
    NSError *error = nil;
    NSArray *matchingData = [context executeFetchRequest:fetchRequest error:&error];
    if (matchingData.count == 1) {
        chatRoom = [matchingData lastObject];
    } else if (matchingData.count > 1){
        $l("Error -> chatRooms count = %d", matchingData.count);
    } else if (!matchingData.count) {
        chatRoom = [[CDChatRoom alloc] initWithEntity:entityDescription
                       insertIntoManagedObjectContext:context];
        chatRoom.roomId = [Utilities getNewGUID];
        chatRoom.imaginaryFriends = imaginaryFriends;
        chatRoom.updatedAt = [NSDate dateWithTimeIntervalSinceReferenceDate:410227200];
    }
    
    return chatRoom;
}

+ (NSArray *)getChatRoomsForUser:(CDUser *)user {
    NSMutableArray *chatRooms = [NSMutableArray new];
    
    NSArray *imagFriends = [user.imaginaryFriends allObjects];
    for (CDImaginaryFriend *currImFr in imagFriends) {
        NSArray *rooms = [currImFr.rooms allObjects];
        CDChatRoom *chatRoom = [rooms lastObject];
        if (chatRoom.messages.count) {
            [chatRooms addObject:chatRoom];
        }
    }
    
    return chatRooms;
}

@end
