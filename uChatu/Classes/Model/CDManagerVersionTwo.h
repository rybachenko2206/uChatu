//
//  CDManagerVersionTwo.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/13/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import "CDUser.h"
#import "CDImaginaryFriend.h"
#import "CDChatMessage.h"
#import "PrefixHeader.pch"
#import <UIKit/UIKit.h>

@interface CDManagerVersionTwo : NSObject

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

+ (CDManagerVersionTwo *)sharedInstance;
- (BOOL)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (void)insertNewMessageWithMessageText:(NSString *)message
                            messageType:(MessageType)messageType
                              createdAt:(NSDate *)createdAt
                               chatRoom:(CDChatRoom *)chatRoom
                          attachedImage:(UIImage *)image
                     forImaginaryFriend:(CDImaginaryFriend *)imaginaryFriend;

- (NSArray *)getCDChatMessagesWithRoomJID:(NSString *)roomJID sinceDate:(NSDate *)sinceDate;
- (NSArray *)getAllCDChatMessagesWithRoomJID:(NSString *)roomJID;
- (NSArray *)getCDImaginaryFriedsForCDUser:(CDUser *)user;

@end
