//
//  CDUser.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/19/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDImaginaryFriend;

@interface CDUser : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSDate   * lastUpdated;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSString * avatarImageName;
@property (nonatomic, retain) NSNumber * accessToAddressBook;
@property (nonatomic, retain) NSSet    * imaginaryFriends;
@end

@interface CDUser (CoreDataGeneratedAccessors)

- (void)addImaginaryFriendsObject:(CDImaginaryFriend *)value;
- (void)removeImaginaryFriendsObject:(CDImaginaryFriend *)value;
- (void)addImaginaryFriends:(NSSet *)values;
- (void)removeImaginaryFriends:(NSSet *)values;

+ (CDUser *)userWithEmail:(NSString *)email userId:(NSString *)userId inContext:(NSManagedObjectContext *)context ;

@end
