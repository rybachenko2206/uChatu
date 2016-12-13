//
//  XMPPService.m
//  Friender
//
//  Created by Igor Karpenko on 30.09.14.
//  Copyright (c) 2014 Digicode. All rights reserved.
//

#import "Reachability.h"
#import "PrefixHeader.pch"
#import "PFUser+Additions.h"

#import "ErrorManager.h"
#import "AuthorizationManager.h"
#import "XMPPFramework.h"
#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPMessageDeliveryReceipts.h"
#import <CFNetwork/CFNetwork.h>
#import "ChatRoom.h"

#import "NSXMLElement+XEP_0203.h"
#import "XMPPMessage+XEP0045.h"
#import "NSDate+XMPPDateTimeProfiles.h"
#import "XMPPMUC.h"
#import "XMPPRoomCoreDataStorage.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "XMPPLogging.h"

#import "XMPPService.h"


NSString *const kXMPPChatHostName = @"conference.104.236.207.249";
NSString *const kXMPPHostName = @"104.236.207.249";
NSInteger const kXMPHostPort = 5222;

@interface XMPPService () <XMPPRosterDelegate, XMPPRoomDelegate, XMPPStreamDelegate> {
	BOOL isRegistering;
}


@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingStorage;
@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchivingModule;

//@property (nonatomic, strong) XMPPMessageDeliveryReceipts *xmppMessageDeliveryRecipts;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;

@property (nonatomic, strong) NSString *password;
@property (nonatomic, assign) BOOL customCertEvaluation;
@property (nonatomic, assign) BOOL isXmppConnected;
@property (nonatomic, assign) BOOL isAutentificated;
@property (nonatomic, assign) BOOL isFirstPresence;

- (void)goOnline;
- (void)goOffline;

- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;

@end

@implementation XMPPService

#pragma mark - Static methods

+ (instancetype)sharedInstance {
	static XMPPService *sharedService = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedService = [[self alloc] init];
	});
	return sharedService;
}


#pragma mark - Interface methods

- (instancetype)init {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reachabilityChangedNotification:)
												 name:kReachabilityManagerNetworkStatusChanged
											   object:nil];
	
	return self;
}

- (void)reachabilityChangedNotification:(NSNotification *)notification {
    NSNumber *object = notification.object;
    BOOL isReachable = [object boolValue];
	if (isReachable) {
		[self signIn];
	}
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext *)managedObjectContext_roster {
	return [_xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities {
	return [_xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

- (void)setupStream {
    
	NSAssert(_xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
	
	_xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		_xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	_xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
	
	_xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
	//	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	_xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
	
	_xmppRoster.autoFetchRoster = YES;
	_xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	//
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	_xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	_xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
	
	_xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
	
	// Setup capabilities
	//
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	//
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	//
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
	_xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
	_xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_xmppCapabilitiesStorage];
	
	_xmppCapabilities.autoFetchHashedCapabilities = YES;
	_xmppCapabilities.autoFetchNonHashedCapabilities = NO;

//	_xmppRoomCoreDataStorage = [XMPPRoomCoreDataStorage sharedInstance];
	
	// Activate xmpp modules
	
	[_xmppReconnect         activate:_xmppStream];
	[_xmppRoster            activate:_xmppStream];
	[_xmppvCardTempModule   activate:_xmppStream];
	[_xmppvCardAvatarModule activate:_xmppStream];
	[_xmppCapabilities      activate:_xmppStream];
	
	// Add ourself as a delegate to anything we may be interested in
	
	[_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.

	[_xmppStream setHostName:kXMPPHostName];
	[_xmppStream setHostPort:kXMPHostPort];
	
	// You may need to alter these settings depending on the server you're connecting to
	_customCertEvaluation = YES;
    
    //дає можливість бачити, чи отримана повідомлення. Якщо не error чи не groupchat
//    _xmppMessageDeliveryRecipts = [[XMPPMessageDeliveryReceipts alloc] initWithDispatchQueue:dispatch_get_main_queue()];
//    _xmppMessageDeliveryRecipts.autoSendMessageDeliveryReceipts = YES;
//    _xmppMessageDeliveryRecipts.autoSendMessageDeliveryRequests = YES;
//    [_xmppMessageDeliveryRecipts activate:self.xmppStream];
}

- (void)teardownStream {
	[_xmppStream removeDelegate:self];
	[_xmppRoster removeDelegate:self];
    [_xmppReconnect removeDelegate:self];
	
	[_xmppReconnect         deactivate];
	[_xmppRoster            deactivate];
	[_xmppvCardTempModule   deactivate];
	[_xmppvCardAvatarModule deactivate];
	[_xmppCapabilities      deactivate];
	
	[_xmppStream disconnect];
	
	self.xmppStream = nil;
	self.xmppReconnect = nil;
	self.xmppRoster = nil;
	self.xmppRosterStorage = nil;
	self.xmppvCardStorage = nil;
	self.xmppvCardTempModule = nil;
	self.xmppvCardAvatarModule = nil;
	self.xmppCapabilities = nil;
	self.xmppCapabilitiesStorage = nil;
//	self.xmppRoomCoreDataStorage = nil;
}

- (void)goOnline {
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	[[self xmppStream] sendElement:presence];
}

- (void)goOffline {
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)signIn {
	if (![_xmppStream isDisconnected]) {
		return;
	}
	
	PFUser *currentUser = [[AuthorizationManager sharedInstance] currentUser];
    NSString *myJID = [NSString stringWithFormat:@"%@@%@", currentUser.objectId, kXMPPHostName];
	NSString *myPassword = currentUser.xmppPassword;
	if (myJID == nil || myPassword == nil) {
		return;
	}
	
	[_xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
	_password = myPassword;
	
	NSError *error = nil;
	if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
//        [Utilities showAlertViewWithTitle:@"Error connecting"
//                                  message:@"See console for error details."
//                        cancelButtonTitle:@"Ok"];
		
    $l(@"\n\n---Error connecting: %@", error);
    } else {
        NSLog(@"Logged IN");
    }
}

- (void)signUp {
	if (![_xmppStream isDisconnected]) {
		return;
	}
	
    PFUser *currentUser = [[AuthorizationManager sharedInstance] currentUser];
    NSString *myJID = [NSString stringWithFormat:@"%@@%@", currentUser.objectId, kXMPPHostName];
    NSString *myPassword = currentUser.xmppPassword;
	if (myJID == nil || myPassword == nil) {
		return;
	}
	
	[_xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
	_password = myPassword;
	
	NSError *error = nil;
	BOOL success;
	
    if (![[self xmppStream] isConnected]) {
        success = [[self xmppStream] connectWithTimeout:XMPPStreamTimeoutNone error:&error];
    } else {
        success = [[self xmppStream] registerWithPassword:_password error:&error];
    }
    
    if (success) {
        isRegistering = YES;
    } else {
        [ErrorManager showAlertWithError:error];
    }
}

- (void)disconnect {
	[self goOffline];
	[_xmppStream disconnect];
}

- (BOOL)isConnected {
    return _isXmppConnected;
}

- (BOOL)isAtentificated {
    return _isAutentificated;
}

- (NSString *)chatHostName {
    return kXMPPChatHostName;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Chat methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)createOrJoinToRoom:(XMPPRoom *)room sinceDate:(NSDate *)sinceDate {
    if (!sinceDate) {
        sinceDate = LAST_MESSAGE_DATE_DEFAULT;
    }
	[room activate:self.xmppStream];
	
	NSXMLElement *history = [NSXMLElement elementWithName:@"history"];
//    [history addAttributeWithName:@"maxstanzas" doubleValue:500];
    NSString *dateStr = [sinceDate xmppDateTimeString];
    [history addAttributeWithName:@"since" stringValue:dateStr];
    
    PFUser *currentUser = [[AuthorizationManager sharedInstance] currentUser];
    [room joinRoomUsingNickname:currentUser.objectId
						history:history
					   password:nil];
}

- (void)deleteRoom {
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStreamDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
//    $c;
//    msgCount++;
//    $l("msgCount = %d", msgCount);
//    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
//    if ([self.delegate respondsToSelector:@selector(XMPPServiceDidReceiveMessage:)]) {
//        [self.delegate XMPPServiceDidReceiveMessage:message];
//    }
//}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    if ([self.delegate respondsToSelector:@selector(xmppServiceDidSendMessage:toStream:)]) {
        [self.delegate xmppServiceDidSendMessage:message toStream:sender];
    }
}

- (XMPPMessage *)xmppStream:(XMPPStream *)sender willSendMessage:(XMPPMessage *)message {
    return message;
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    $l("\n---xmppStream:didReceivePresence:\n");
//    DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
    if (_isFirstPresence) {
        _isFirstPresence = NO;
    }
}

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings {
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	NSString *expectedCertName = [_xmppStream.myJID domain];
	if (expectedCertName)
	{
		[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
	}
	
	if (_customCertEvaluation) {
		[settings setObject:@(YES) forKey:@"GCDAsyncSocketManuallyEvaluateTrust"];
	}
}

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler {
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	// The delegate method should likely have code similar to this,
	// but will presumably perform some extra security code stuff.
	// For example, allowing a specific self-signed certificate that is known to the app.
	
	dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(bgQueue, ^{
		
		SecTrustResultType result = kSecTrustResultDeny;
		OSStatus status = SecTrustEvaluate(trust, &result);
		
		if (status == noErr && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
			completionHandler(YES);
		}
		else {
			completionHandler(NO);
		}
	});
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender {
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    $l("\n\n--xmppStreamDidConnect\n");
	
	_isXmppConnected = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kXMPPStremConnectionWasChanged
                                                        object:@(_isXmppConnected)];
	
	NSError *error = nil;
	BOOL operationInProgress;
	
	if (isRegistering) {
		operationInProgress = [[self xmppStream] registerWithPassword:_password error:&error];
	} else {
		operationInProgress = [[self xmppStream] authenticateWithPassword:_password error:&error];
	}
	
	if (!operationInProgress) {
		[ErrorManager showAlertWithError:error];
	}
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    $l("\n\n----xmppStreamDidDisconnect\n--witn error - %@\n", error);
//    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if (!_isXmppConnected) {
//        DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
    }
    
//    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    _isAutentificated = NO;
    _isXmppConnected = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kXMPPStremConnectionWasChanged
                                                        object:@(_isXmppConnected)];
    
    if (error) {
        [self signIn];
    }
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender {
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	// Update tracking variables
	isRegistering = NO;
	
    PFUser *currentUser = [[AuthorizationManager sharedInstance] currentUser];
	[sender authenticateWithPassword:currentUser.xmppPassword error:nil];
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error {
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	// Update tracking variables
	isRegistering = NO;
	
	// Update GUI
	[sender disconnect];
    [self signIn];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
//    [self getAllRegisteredUsers];
    
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    _isAutentificated = YES;
	_isFirstPresence = YES;
	[self goOnline];
    [[NSNotificationCenter defaultCenter] postNotificationName:kXMPPStreamDidAutentificateNotification
                                                        object:@(YES)];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	[_xmppStream disconnect];
	[self signUp];
    _isAutentificated = NO;
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Error! %@", [error localizedDescription]]];
        $l("---- didReceiveError. Error => %@", [error localizedDescription]);
    }
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence {
    $l("\n\n---xmppRoster:didReceiveBuddyRequest:\n\n");
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPReconnectDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppReconnect:(XMPPReconnect *)sender didDetectAccidentalDisconnect:(SCNetworkReachabilityFlags)connectionFlags {
    $l("\n\n---xmppReconnect:didDetectAccidentalDisconnect:\n --- sender = %@", sender);
}

- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags {
    $l("\n\n---xmppReconnect:shouldAttemptAutoReconnect:\n --- sender = %@\n --- reachabilityFlags = %d", sender, reachabilityFlags);
    return YES;
}


@end
