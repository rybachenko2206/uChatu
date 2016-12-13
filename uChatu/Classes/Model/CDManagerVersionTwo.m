//
//  CDManagerVersionTwo.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/13/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "CDPhoto.h"
#import "CDChatRoom.h"

#import "CDManagerVersionTwo.h"

@interface CDManagerVersionTwo ()

@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CDManagerVersionTwo

#pragma mark - Static methods

+(CDManagerVersionTwo *) sharedInstance {
    static CDManagerVersionTwo *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [CDManagerVersionTwo new];
        
    });
    
    return sharedManager;
}


#pragma mark - Interface methods

- (NSArray *)getCDImaginaryFriedsForCDUser:(CDUser *)user {
    NSArray *imFriends = [user.imaginaryFriends allObjects];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"wasDeleted != YES"];
    imFriends = [imFriends filteredArrayUsingPredicate:predicate];
    
    return imFriends;
}

- (NSArray *)getAllCDChatMessagesWithRoomJID:(NSString *)roomJID {
    NSArray *messages = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescr = [NSEntityDescription entityForName:[[CDChatMessage class] description] inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entityDescr];
    [request setPredicate:[NSPredicate predicateWithFormat:@"chatRoomJID = %@", roomJID]];
    NSSortDescriptor *sortDescr = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    [request setSortDescriptors:@[sortDescr]];
    
    NSError *error = nil;
    messages = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return messages;
}

- (NSArray *)getCDChatMessagesWithRoomJID:(NSString *)roomJID sinceDate:(NSDate *)sinceDate {
    NSArray *messages = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescr = [NSEntityDescription entityForName:[[CDChatMessage class] description] inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entityDescr];
    [request setPredicate:[NSPredicate predicateWithFormat:@"chatRoomJID = %@ AND createdAt > %@", roomJID, sinceDate]];
    NSSortDescriptor *sortDescr = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    [request setSortDescriptors:@[sortDescr]];
    
    NSError *error = nil;
    messages = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return messages;
}

- (void)insertNewMessageWithMessageText:(NSString *)message
                       messageType:(MessageType)messageType
                              createdAt:(NSDate *)createdAt
                               chatRoom:(CDChatRoom *)chatRoom
                          attachedImage:(UIImage *)image
                     forImaginaryFriend:(CDImaginaryFriend *)imaginaryFriend {
    
    NSEntityDescription *entityDescr = [NSEntityDescription entityForName:[[CDChatMessage class] description]
                                                   inManagedObjectContext:self.managedObjectContext];
    CDChatMessage *newMessage = [[CDChatMessage alloc] initWithEntity:entityDescr
                               insertIntoManagedObjectContext:_managedObjectContext];
    newMessage.imaginaryFriend = imaginaryFriend;
    newMessage.messageText = message;
    newMessage.messageType = @(messageType);
    newMessage.createdAt = createdAt;
    newMessage.chatRoom = chatRoom;
    
    if (image) {
        CDPhoto *photo = [CDPhoto newCDPhotoWithImage:image
                                            inContext:self.managedObjectContext];
        newMessage.photo = photo;
    }
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        $l(@"--- Save to DB error -> %@", error);
    } else {
        $l(@"New Message saved to DB succesfully");
    }
}

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
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"VersionTwoDataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

-(NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"uChatuVersionTwo.sqlite"];
    
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

@end
