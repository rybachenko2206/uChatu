//
//  XMPPChatViewController.h
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/11/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatRoom.h"
#import "ImaginaryFriend.h"

@protocol ChatRoomDelegate <NSObject>

@optional
-(void)chatRoom:(ChatRoom *)room didUpdateWithNewMessage:(NSString *)message;

@end

@interface XMPPChatViewController : UIViewController

+(instancetype)xmppChatViewControllerWithRoom:(ChatRoom *)room;
@property (strong, nonatomic) ChatRoom *chatRoom;
@property (strong, nonatomic) ImaginaryFriend *myImFriend;
@property (strong, nonatomic) ImaginaryFriend *otherImFriend;
@property (nonatomic, assign) BOOL fromAllUsersRealFrScreen;
@property (weak, nonatomic) id <ChatRoomDelegate> delegate;

@end
