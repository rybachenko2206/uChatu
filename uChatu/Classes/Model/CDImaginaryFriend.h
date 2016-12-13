//
//  CDImaginaryFriend.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/19/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDUser;
@class ImaginaryFriend;

@interface CDImaginaryFriend : NSManagedObject

@property (nonatomic, retain) NSNumber * friendAge;
@property (nonatomic, retain) NSString * friendName;
@property (nonatomic, retain) NSNumber * isYourself;
@property (nonatomic, retain) NSNumber * lastOpenedChatAsUser;
@property (nonatomic, retain) NSDate * lastUpdated;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSString * occupation;
@property (nonatomic, retain) NSString * personality;
@property (nonatomic, retain) NSNumber * publicType;
@property (nonatomic, retain) NSString * avatarImageName;
@property (nonatomic, retain) NSNumber * wasDeleted;
@property (nonatomic, retain) NSString * biography;
@property (nonatomic, retain) CDUser *user;
@property (nonatomic, retain) NSSet *message;
@property (nonatomic, retain) NSSet *rooms;
@end

@interface CDImaginaryFriend (CoreDataGeneratedAccessors)

- (void)addMessageObject:(NSManagedObject *)value;
- (void)removeMessageObject:(NSManagedObject *)value;
- (void)addMessage:(NSSet *)values;
- (void)removeMessage:(NSSet *)values;

- (void)addRoomsObject:(NSManagedObject *)value;
- (void)removeRoomsObject:(NSManagedObject *)value;
- (void)addRooms:(NSSet *)values;
- (void)removeRooms:(NSSet *)values;

+ (CDImaginaryFriend *)imaginaryFriendWithObjectId:(NSString *)objectId inContext:(NSManagedObjectContext *)context;
+ (NSString *)updateCDImaginaryFriendFromParse:(ImaginaryFriend *)parseImFriend inContext:(NSManagedObjectContext *)context;
+ (NSArray *)sortImaginaryFriendsByFriendName:(NSArray *)friendsList;
+ (CDImaginaryFriend *)convertParseImaginaryFriend:(ImaginaryFriend *)parseImFriend withContext:(NSManagedObjectContext *)context;

@end
