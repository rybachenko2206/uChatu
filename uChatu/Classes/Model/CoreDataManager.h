//
//  CoreDataManager.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/8/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import "CDUserSettings.h"
#import "CDUser.h"
#import "CDImaginaryFriend.h"
#import "PrefixHeader.pch"

@interface CoreDataManager : NSObject

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

+(CoreDataManager *) sharedInstance;

- (NSURL *)applicationDocumentsDirectory;

-(void) insertNewMessageWithUserId:(NSString *)userId
                       messageText:(NSString *)message
                       messageType:(MessageType)messageType
                         createdAt:(NSDate *)createdAt;
-(NSArray *) getAllMessagesForUserId:(NSString *)userId messageType:(MessageType)mesageType;

-(CDUserSettings *) userSettingsWithUserId:(NSString *)userId email:(NSString *)email;
-(BOOL) saveContext;

@end
