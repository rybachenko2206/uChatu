//
//  CDUserSettings.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/18/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import "PrefixHeader.pch"

#import "CDUserSettings.h"


@implementation CDUserSettings

@dynamic email;
@dynamic friendAge;
@dynamic friendName;
@dynamic friendOccupation;
@dynamic friendPersonality;
@dynamic lastChanged;
@dynamic lastOpenedChatAsUser;
@dynamic userId;
@dynamic userName;


+(CDUserSettings *) userSettingsWithUserId:(NSString *)userId
                                     email:(NSString *)email
                                 inContext:(NSManagedObjectContext *)context {
    
    CDUserSettings *userSettings = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[CDUserSettings class] description] inManagedObjectContext:context];
    [fetchRequest setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", userIdKey, userId];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *matchingData = [context executeFetchRequest:fetchRequest error:&error];
    if (matchingData.count == 1) {
        userSettings = [matchingData firstObject];
    } else if (matchingData.count > 1) {
        $l("ERROR - UserSettings count > 1");
        return nil;
    } else {
        userSettings = [[CDUserSettings alloc] initWithEntity:entityDescription
                               insertIntoManagedObjectContext:context];
        userSettings.userId = userId;
        userSettings.userName = @"";
        userSettings.email = email;
        userSettings.friendName = @"";
        userSettings.friendPersonality = @"";
        userSettings.friendOccupation = @"";
        userSettings.friendAge = @(0);
        userSettings.lastOpenedChatAsUser = @(YES);
        userSettings.lastChanged = [NSDate dateWithTimeIntervalSinceReferenceDate:410227200];
        
        if (![context save:&error]) {
            $l(@"---> Insert UserSettings error - %@", error);
        }
    }
    
    return userSettings;
}

@end

