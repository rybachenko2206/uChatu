//
//  WithFriendChatDataSource.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/10/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import "PrefixHeader.pch"
@class CDImaginaryFriend;
@class CDChatRoom;


@interface WithFriendChatDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong, readonly) NSArray *messages;
@property (nonatomic, strong) CDChatRoom *chatRoom;

- (void)reloadData;
- (void)addMessage:(NSString *)message
       messageType:(MessageType)messageType
          chatRoom:(CDChatRoom *)chatRoom
   imaginaryFriend:(CDImaginaryFriend *)imaginaryFriend
     attachedImage:(UIImage *)attachImg;

@end
