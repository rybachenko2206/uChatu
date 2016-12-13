//
//  CDUser.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/19/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import "PrefixHeader.pch"

#import "CDUser.h"
#import "CDImaginaryFriend.h"


@implementation CDUser

@dynamic email;
@dynamic lastUpdated;
@dynamic phoneNumber;
@dynamic userId;
@dynamic userName;
@dynamic avatarImageName;
@dynamic accessToAddressBook;
@dynamic imaginaryFriends;

#pragma mark - Static methods

+ (CDUser *)userWithEmail:(NSString *)email userId:(NSString *)userId inContext:(NSManagedObjectContext *)context {
    CDUser *user;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[CDUser class] description] inManagedObjectContext:context];
    [fetchRequest setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", userIdKey, userId];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *matchingData = [context executeFetchRequest:fetchRequest error:&error];
    if (matchingData.count) {
        user = [matchingData firstObject];
    } else {
        user = [[CDUser alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        user.userId = userId;
        user.email = email;
        user.avatarImageName = [Utilities getNewGUID];
        user.accessToAddressBook = @(NO);
        user.lastUpdated = [NSDate dateWithTimeIntervalSinceReferenceDate:410227200];
        
        if (![context save:&error]) {
            $l(@"---> Insert CDUser error - %@", error);
        }
    }
    
    return user;
}

@end
