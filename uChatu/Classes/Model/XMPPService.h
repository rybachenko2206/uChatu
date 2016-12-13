//
//  XMPPService.h
//  Friender
//
//  Created by Igor Karpenko on 30.09.14.
//  Copyright (c) 2014 Digicode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "XMPPJID.h"
@class XMPPStream;
@class XMPPMessage;
@class ChatRoom;

// Log levels: off, error, warn, info, verbose
//#if DEBUG
//static const int ddLogLevel = LOG_LEVEL_VERBOSE;
//#else
//static const int ddLogLevel = LOG_LEVEL_INFO;
//#endif

@class XMPPRoom;
@class XMPPService;

@protocol XMPPServiceDelegate <NSObject>
- (void)xmppServiceDidSendMessage:(XMPPMessage *)message toStream:(XMPPStream *)stream;

@end


@interface XMPPService : NSObject


@property (nonatomic, strong) XMPPStream *xmppStream;
@property (strong, nonatomic) XMPPRoom *xmppRoom;
@property (weak) id <XMPPServiceDelegate> delegate;
//@property (nonatomic, strong) ChatRoom *parseChatRoom;

+ (instancetype)sharedInstance;

- (void)signIn;
- (void)signUp;
- (void)disconnect;
- (BOOL)isConnected;
- (BOOL)isAtentificated;
- (NSString *)chatHostName;

- (void)setupStream;
- (void)teardownStream;

- (void)createOrJoinToRoom:(XMPPRoom *)room sinceDate:(NSDate *)sinceDate;

@end

extern NSString *const kXMPPChatHostName;
extern NSString *const kXMPPStreamDidConectNotification;
