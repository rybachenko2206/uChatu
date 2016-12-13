//
//  LocalDSManager.h
//  uChatu
//
//  Created by Roman Rybachenko on 4/6/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

@class ResponseInfo;
@class ImaginaryFriend;
@class ChatRoom;
@class ChatPhoto;
@class UChatuMessage;

#import "PrefixHeader.pch"
#import <Parse/Parse.h>
#import <Foundation/Foundation.h>


@interface LocalDSManager : NSObject

+ (LocalDSManager *)sharedInstanse;

- (void)fetchChatRoomsForPFUser:(PFUser *)user completion:(RequestCallback)completion;
//- (void)uChatuMessagesFromLocalDataStoreWithChatRoom:(ChatRoom *)chatRoom completion:(RequestCallback)completion;
//- (void)pinInBackgroundUChatuMessage:(UChatuMessage *)message;

@end
