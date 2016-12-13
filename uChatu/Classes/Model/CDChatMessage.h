//
//  CDChatMessage.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/4/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDChatRoom, CDImaginaryFriend, CDPhoto;
@class XMPPMessage;

@interface CDChatMessage : NSManagedObject

@property (nonatomic, retain) NSString *fullImageUrl;
@property (nonatomic, retain) NSString *thumbnailImageUrl;
@property (nonatomic, retain) NSNumber *thumbnailWidth;
@property (nonatomic, retain) NSNumber *thumbnailHeight;
@property (nonatomic, retain) NSDate   * createdAt;
@property (nonatomic, retain) NSString * messageText;
@property (nonatomic, retain) NSString * ownerObjectId;
@property (nonatomic, retain) NSString * chatRoomJID;
@property (nonatomic, retain) NSString * messageObjectId;
@property (nonatomic, retain) NSNumber * messageType;
@property (nonatomic, retain) CDChatRoom *chatRoom;
@property (nonatomic, retain) CDImaginaryFriend *imaginaryFriend;
@property (nonatomic, retain) CDPhoto *photo;


+ (CDChatMessage *)messageWithXMPPMessage:(XMPPMessage *)xmppMessage
                          chatRoomJID:(NSString *)roomJID
                            inContext:(NSManagedObjectContext *)context;

+ (BOOL)isExistMessage:(XMPPMessage *)xmppMessage inContext:(NSManagedObjectContext *)context;

@end
