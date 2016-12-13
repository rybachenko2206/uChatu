//
//  CDUserSettings.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/18/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDUserSettings : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * friendAge;
@property (nonatomic, retain) NSString * friendName;
@property (nonatomic, retain) NSString * friendOccupation;
@property (nonatomic, retain) NSString * friendPersonality;
@property (nonatomic, retain) NSDate * lastChanged;
@property (nonatomic, retain) NSNumber * lastOpenedChatAsUser;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * userName;

+(CDUserSettings *) userSettingsWithUserId:(NSString *)userId
                                     email:(NSString *)email
                                 inContext:(NSManagedObjectContext *)context;

@end
