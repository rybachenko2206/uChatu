//
//  CDChatRoom.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/19/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDUser;

@class CDImaginaryFriend;

@interface CDChatRoom : NSManagedObject

@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * roomId;
@property (nonatomic, retain) NSSet *imaginaryFriends;
@property (nonatomic, retain) NSSet *messages;
@end

@interface CDChatRoom (CoreDataGeneratedAccessors)

- (void)addImaginaryFriendsObject:(CDImaginaryFriend *)value;
- (void)removeImaginaryFriendsObject:(CDImaginaryFriend *)value;
- (void)addImaginaryFriends:(NSSet *)values;
- (void)removeImaginaryFriends:(NSSet *)values;

- (void)addMessagesObject:(NSManagedObject *)value;
- (void)removeMessagesObject:(NSManagedObject *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

+ (CDChatRoom *)chatRoomWithImaginaryFriends:(NSSet *)imaginaryFriends inContext:(NSManagedObjectContext *)context;
+ (NSArray *)getChatRoomsForUser:(CDUser *)user;

@end
