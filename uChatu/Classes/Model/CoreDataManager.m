//
//  CoreDataManager.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/8/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CDMessage.h"
#import "CDUserSettings.h"
#import "PrefixHeader.pch"

#import "CoreDataManager.h"


@interface CoreDataManager ()

@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


@implementation CoreDataManager

#pragma mark - Static methods

+(CoreDataManager *) sharedInstance {
    static CoreDataManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [CoreDataManager new];
        
    });
    
    return sharedManager;
}


#pragma mark - Interface methods

-(BOOL) saveContext {
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        $l(@"--- Save to DB error -> %@", error);
        return NO;
    } else {
        $l(@"managedObjectContext  saved  succesfully");
    }
    return YES;
}

-(CDUserSettings *) userSettingsWithUserId:(NSString *)userId email:(NSString *)email {
    return [CDUserSettings userSettingsWithUserId:userId email:email  inContext:self.managedObjectContext];
}

 -(void) insertNewMessageWithUserId:(NSString *)userId
                       messageText:(NSString *)message
                       messageType:(MessageType)messageType
                         createdAt:(NSDate *)createdAt {

    NSEntityDescription *entityDescr = [NSEntityDescription entityForName:[[CDMessage class] description]
                                                   inManagedObjectContext:self.managedObjectContext];
    CDMessage *newMessage = [[CDMessage alloc] initWithEntity:entityDescr
                               insertIntoManagedObjectContext:_managedObjectContext];
    newMessage.userId = userId;
    newMessage.message = message;
    newMessage.messageType = @(messageType);
    newMessage.createdAt = createdAt;
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        $l(@"--- Save to DB error -> %@", error);
    } else {
        $l(@"New Message saved to DB succesfully");
    }
}

-(NSArray *) getAllMessagesForUserId:(NSString *)userId messageType:(MessageType)mesageType {
    [self managedObjectContext];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[CDMessage class] description]
                                                   inManagedObjectContext:_managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDescription];
    
    
    NSPredicate *predicate = [self predicateForUserId:userId messageType:mesageType];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:createdAtKey ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        $l(@"--- fetch request error -> %@", [error localizedDescription]);
    }
    
    return fetchedObjects;
}


#pragma mark - Core Data stack

-(NSManagedObjectContext *) managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

-(NSManagedObjectModel *) managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

-(NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"uChatu.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

-(NSURL *) applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Private methods

-(NSPredicate *) predicateForUserId:(NSString *)userId messageType:(MessageType)mesageType {
    NSPredicate *predicate = nil;
    if (mesageType == MessageTypeUserToUser) {
        predicate = [NSPredicate predicateWithFormat:@"(%K == %@) AND (%K == %@)",userIdKey, userId, messageTypeKey, @(mesageType)];
    } else if (mesageType == MessageTypeUserToFriend) {
        predicate = [NSPredicate predicateWithFormat:@"(%K == %@) AND (%K >= %@)",userIdKey, userId, messageTypeKey, @(mesageType)];
    }
    
    return predicate;
}


@end
