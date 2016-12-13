//
//  CDChatMessage.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/4/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import "PrefixHeader.pch"
#import "SharedDateFormatter.h"
#import "XMPP.h"
#import "NSXMLElement+XEP_0203.h"
#import "XMPPMessage+XEP0045.h"

#import "CDChatMessage.h"
#import "CDChatRoom.h"
#import "CDImaginaryFriend.h"
#import "CDPhoto.h"


@implementation CDChatMessage

@dynamic createdAt;
@dynamic messageText;
@dynamic messageType;
@dynamic chatRoom;
@dynamic imaginaryFriend;
@dynamic photo;
@dynamic chatRoomJID;
@dynamic ownerObjectId;
@dynamic messageObjectId;
@dynamic thumbnailImageUrl;
@dynamic fullImageUrl;
@dynamic thumbnailHeight;
@dynamic thumbnailWidth;


#pragma mark - Static methods

+ (BOOL)isExistMessage:(XMPPMessage *)xmppMessage inContext:(NSManagedObjectContext *)context {
    NSString *xmppMessageId = [xmppMessage attributeStringValueForName:@"id"];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescr = [NSEntityDescription entityForName:[[CDChatMessage class] description] inManagedObjectContext:context];
    [request setEntity:entityDescr];
    [request setPredicate:[NSPredicate predicateWithFormat:@"messageObjectId = %@", xmppMessageId]];
    
    NSError *error = nil;
    NSArray *fetchedData = [context executeFetchRequest:request error:&error];
    
    return fetchedData.count;
}

+ (CDChatMessage *)messageWithXMPPMessage:(XMPPMessage *)xmppMessage chatRoomJID:(NSString *)roomJID inContext:(NSManagedObjectContext *)context {
    CDChatMessage *message = nil;
    NSError *error = nil;
    
    BOOL existMsg = [self isExistMessage:xmppMessage inContext:context];
    if (existMsg) {
        return nil;
    } else {
        NSString *xmppMessageId = [xmppMessage attributeStringValueForName:@"id"];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescr = [NSEntityDescription entityForName:[[CDChatMessage class] description] inManagedObjectContext:context];
        [request setEntity:entityDescr];
        
        NSData *msgData = [xmppMessage.body dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonDict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:msgData
                                                                                 options:0
                                                                                   error:&error];
        
        message = [[CDChatMessage alloc] initWithEntity:entityDescr insertIntoManagedObjectContext:context];
        message.messageObjectId = xmppMessageId;
        if (jsonDict[kXMPPmessageText] == [NSNull null]) {
            message.messageText = @"";
        } else {
            message.messageText = jsonDict[kXMPPmessageText];
        }
        message.ownerObjectId = jsonDict[kXMPPmessageOwner];
        message.chatRoomJID = roomJID;
        message.fullImageUrl = jsonDict[kXMPPFullImagemageURL];
        message.thumbnailImageUrl = jsonDict[kXMPPThumbnailImagemageURL];
        message.thumbnailWidth = jsonDict[kXMPPThumbnailWidth];
        message.thumbnailHeight = jsonDict[kXMPPThumbnailHeight];
        
        NSDate *msgCreatedDate = xmppMessage.delayedDeliveryDate;
        message.createdAt = msgCreatedDate ? msgCreatedDate : [NSDate date];
        
        if (!message.createdAt) {
            message.createdAt = [SharedDateFormatter dateFromString:jsonDict[kXMPPcreatedAt]
                                                         withFormat:@"dd.MM.yyyy, HH:mm"];
        }
        
        if (message) {
            [context save:&error];
        }
        if (error) {
            $l("-----> save context error - %@", [error localizedDescription]);
        } else {
            $l("----- Message saved--------");
        }
    }
    
    return message;
}

@end
