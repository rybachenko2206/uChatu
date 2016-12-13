//
//  AppDelegate.m
//  uChatu
//
//  Created by Roman Rybachenko on 11/19/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>
#import <Fabric/Fabric.h>
#import "XMPPRoom.h"
#import <Crashlytics/Crashlytics.h>
#import "ReachabilityManager.h"
#import "AuthorizationManager.h"
#import "WebService.h"
#import "ImaginaryFriend.h"
#import "ChatRoom.h"
#import "PrefixHeader.pch"
#import "SynchronizeDbManager.h"
#import "XMPPService.h"
#import "PFInstallation+Additions.h"
#import "XMPPChatViewController.h"
#import "MHCustomTabBarController.h"
#import "UChatuMessage.h"
#import "AvatarPhoto.h"
#import "AudioPlayer.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "XMPPLogging.h"
#import "AppDelegate.h"


static NSString * const parseAppId = @"oKiHPEbpFa63UySTJBZY3YdIeVFzm9Sn7ltpPPZA";
static NSString * const parseClientKey = @"hq4w4LT6IGWK42Uss9eWy0IEOur7W6qOQHbqh7WA";



@interface AppDelegate () <UIAlertViewDelegate>

@property (strong, nonatomic) Reachability *serviceReachability;
@property (strong, nonatomic) NSDictionary *notificationInfo;
@property (nonatomic) UIAlertView *inetFailedAlert;
@property (nonatomic) UIAlertView *inetRestoredAlert;

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.serviceReachability = [Reachability reachabilityForInternetConnection];
    [self.serviceReachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkStatusDidChaged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                    (__bridge const void *)(self), // observer
                                    hasBlankedScreen, // callback
                                    CFSTR("com.apple.springboard.hasBlankedScreen"), // event name
                                    NULL, // object
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    [self customizeNavigatioBarAppearance];
    
    [Fabric with:@[CrashlyticsKit]];
    
    [ImaginaryFriend registerSubclass];
    [ChatRoom registerSubclass];
    [AvatarPhoto registerSubclass];
    [PFInstallation registerSubclass];
    [PFUser registerSubclass];
    
//    [Parse enableLocalDatastore];
    
    [Parse setApplicationId:parseAppId
                  clientKey:parseClientKey];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [AuthorizationManager sharedInstance].currentUser = [PFUser currentUser];
    [[AuthorizationManager sharedInstance] setCurrentUserOnline:YES];
    
    //Setup Lumberjack logger
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
//    [DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:XMPP_LOG_LEVEL_VERBOSE];
    
    // Setup the XMPP stream
    [[XMPPService sharedInstance] setupStream];
    
    if ([AuthorizationManager sharedInstance].currentUser) {
        [[XMPPService sharedInstance] signIn];
    }
    
    self.screenIsPortraitOnly = YES;
    
    PFUser *currUser = [PFUser currentUser];
    if (![currUser.isUpdatedToVersionTwo boolValue]) {
        [[WebService sharedInstanse] logOut];
    }
    [AuthorizationManager sharedInstance].currentUser = currUser;
    
    // Configure remote notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else {
        //register to receive notifications
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    
    // Check launch payload
    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notificationPayload) {
        double delayInSeconds = 1.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self proceedRemoteNotification:notificationPayload];
        });
    }
    
    
    return YES;
}


-(void)dealloc {
    [[XMPPService sharedInstance] teardownStream];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    
    if(self.screenIsPortraitOnly == NO) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[AuthorizationManager sharedInstance] setCurrentUserOnline:NO];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[AuthorizationManager sharedInstance] setCurrentUserOnline:NO];
//    [[XMPPService sharedInstance] leaveRoom];
    [[XMPPService sharedInstance] disconnect];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[AuthorizationManager sharedInstance] setCurrentUserOnline:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[AuthorizationManager sharedInstance] setCurrentUserOnline:YES];
    if ([XMPPService sharedInstance].xmppStream && ![XMPPService sharedInstance].isConnected) {
        [[XMPPService sharedInstance] signIn];
    }
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[AuthorizationManager sharedInstance] setCurrentUserOnline:NO];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    self.deviceToken = deviceToken;
    if ([AuthorizationManager sharedInstance].currentUser) {
        // Store the deviceToken in the current installation and save it to Parse.
        [[WebService sharedInstanse] savePFInstallationForUser:[AuthorizationManager sharedInstance].currentUser
                                                    completion:^(ResponseInfo *response){
                                                    
                                                    }];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        $l("\n\n---Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        $l("\n\n---application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
    self.deviceToken = nil;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    
    if (application.applicationState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}

- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types {

}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    self.notificationInfo = userInfo;
    
    BOOL isJoined = [XMPPService sharedInstance].xmppRoom.isJoined;
    NSString *roomJID = [XMPPService sharedInstance].xmppRoom.roomJID.user;
    NSString *notifMessageToRoomJID = [userInfo[@"roomJID"] lowercaseString];
    
    if ((application.applicationState == UIApplicationStateActive && !isJoined)
        || (isJoined && ![notifMessageToRoomJID isEqualToString:roomJID])) {
        
        AudioServicesPlaySystemSound (NOTIFICATION_GENERAL_SOUND);
    }
    
    [self proceedRemoteNotification:userInfo];
}



#pragma mark - Private methods

static void hasBlankedScreen(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSString* notifyName = (__bridge NSString*)name;
    // this check should really only be necessary if you reuse this one callback method
    //  for multiple Darwin notification events
    if ([notifyName isEqualToString:@"com.apple.springboard.hasBlankedScreen"]) {
        $l("---- screen has either gone dark, or been turned back on!");
        [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationGoesToSleepNotification object:nil];
        [[AuthorizationManager sharedInstance] setCurrentUserOnline:YES];
    }
}

- (void)proceedRemoteNotification:(NSDictionary *)notification {
    NSString *fromImaginaryFriendName = notification[@"fromImaginaryFriendName"];
    PushNotificationType pType = [notification[@"pushNotificationType"] integerValue];
    
    switch (pType) {
        case PushNotificationTypeInviteToChat: {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:fromImaginaryFriendName
                                                                message:inviteToChatMSG
                                                               delegate:self
                                                      cancelButtonTitle:@"DECLINE"
                                                      otherButtonTitles:@"ACCEPT", nil];
            alertView.tag = PushNotificationTypeInviteToChat;
            [alertView show];
            
            break;
        }
        case PushNotificationTypeInviteAccepted: {
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
            NSString *roomJID = self.notificationInfo[@"roomJID"];
            NSArray *objectIds = [roomJID componentsSeparatedByString:@"_"];
            NSMutableArray *participants = [NSMutableArray arrayWithCapacity:2];
            [participants addObject:objectIds[1]];
            [participants addObject:objectIds[2]];
            [[WebService sharedInstanse] getChatRoomWithParticipants:participants
                                                          completion:^(ResponseInfo *response){
                                                              [SVProgressHUD dismiss];
                                                              if (response.objects.count == 1) {
                                                                  ChatRoom *chatRoom = [response.objects lastObject];
                                                                  chatRoom.wasAcceptedStatus = @(ChatRoomAccepdedStatusAccepted);
                                                              }
                                                          }];
            
            
            [Utilities showAlertViewWithTitle:fromImaginaryFriendName
                                      message:acceptedInviteToChatMSG
                            cancelButtonTitle:@"OK"];
            
            break;
        }
        case PushNotificationTypeInviteDeclined: {
            [Utilities showAlertViewWithTitle:fromImaginaryFriendName
                                      message:declinedInviteToChatMSG
                            cancelButtonTitle:@"OK"];
            
            break;
        }
        case PushNotificationTypeNewMessage: {
            [self openChatRoomViewController];
            break;
        }
            
        default:
            break;
    }
}

- (void)openChatRoomViewController {
    MHCustomTabBarController *openedVC = (MHCustomTabBarController *)self.window.rootViewController;
    [openedVC performSegueWithIdentifier:@"viewController1" sender:[openedVC.buttons objectAtIndex:2]];
}

-(void) customizeNavigatioBarAppearance {
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName : NAVIGATION_BAR_TITLE_FONT}];
}

-(void) fontNamesInLog {
    NSString *family, *font;
    for (family in [UIFont familyNames])
    {
        NSLog(@"\nFamily: %@", family);
        
        for (font in [UIFont fontNamesForFamilyName:family])
            NSLog(@"\tFont: %@\n", font);
    }
    
}

- (void)sendAnswerPushNotification:(BOOL)accepted {
    NSString *roomJID = self.notificationInfo[@"roomJID"];
    NSArray *objectIds = [roomJID componentsSeparatedByString:@"_"];
    
    NSString *receiverObjectId = [objectIds lastObject];
    NSString *fromImFriendName = self.notificationInfo[@"toImaginaryFriendName"];
    NSString *toImFriendName = self.notificationInfo[@"fromImaginaryFriendName"];
    NSString *pushMsg = accepted ? acceptedInviteToChatMSG : declinedInviteToChatMSG;
    pushMsg = [NSString stringWithFormat:@"%@ %@", fromImFriendName, pushMsg];
    PushNotificationType pType = accepted ? PushNotificationTypeInviteAccepted : PushNotificationTypeInviteDeclined;
    
    [[WebService sharedInstanse] getUserWithObjectId:receiverObjectId
                                          completion:^(ResponseInfo *response) {
                                              if (response.objects.count == 1) {
                                                  PFUser *toUser = [response.objects lastObject];
                                                  [[WebService sharedInstanse] sendPushNotificationToUser:toUser
                                                                                  fromImaginaryFriendName:fromImFriendName
                                                                                    toImaginaryFriendName:toImFriendName
                                                                                              withMessage:pushMsg
                                                                                                 roomJID:roomJID
                                                                                         notificationType:pType];
                                              }
                                          }];
}

- (void)openXMPPChatRoomVCWithChatRoomJID:(NSString *)roomJID {
//    [WebService sharedInstanse] 
    
    ChatRoom *chatRoom = nil;
    XMPPChatViewController *vc = [XMPPChatViewController xmppChatViewControllerWithRoom:chatRoom];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    MHCustomTabBarController *openedVC = (MHCustomTabBarController *)self.window.rootViewController;
    [openedVC performSegueWithIdentifier:@"viewController1" sender:[openedVC.buttons objectAtIndex:2]];
    [openedVC presentViewController:navController animated:YES completion:nil];
}


#pragma mark - Delegated methods - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == PushNotificationTypeInviteToChat) {
        NSString *roomJID = self.notificationInfo[@"roomJID"];
        NSString *fromImFriendName = self.notificationInfo[@"toImaginaryFriendName"];
        NSString *toImFriendName = self.notificationInfo[@"fromImaginaryFriendName"];
        if (buttonIndex == 1) {
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
            [[WebService sharedInstanse] setAcceptInviteForChatWithRoomJID:roomJID completion:^(ResponseInfo *response){
                [SVProgressHUD dismiss];
                if (response.success) {
                    [[WebService sharedInstanse] sendAnswerPushNotification:YES
                                                                    roomJID:roomJID
                                                                       from:fromImFriendName
                                                                         to:toImFriendName];
                    [self openXMPPChatRoomVCWithChatRoomJID:roomJID];
                }
            }];
        } else {
            [[WebService sharedInstanse] sendAnswerPushNotification:NO
                                                            roomJID:roomJID
                                                               from:fromImFriendName
                                                                 to:toImFriendName];
        }
        
    }
}

- (BOOL)isReachable {
    NetworkStatus nwStatus = [self.serviceReachability currentReachabilityStatus];
    return nwStatus == NotReachable ? NO : YES;
}


#pragma mark - Notification observers

- (void)networkStatusDidChaged:(NSNotification *)notification {
    $l("--- Reachability status changed ...");
    NSNumber *isReachable = [NSNumber numberWithBool:[self isReachable]];
    if (_inetFailedAlert.visible) {
        [_inetFailedAlert dismissWithClickedButtonIndex:0 animated:YES];
    }
    if (_inetRestoredAlert) {
        [_inetRestoredAlert dismissWithClickedButtonIndex:0 animated:YES];
    }
    
    if (![self isReachable]) {
        _inetFailedAlert = [[UIAlertView alloc] initWithTitle:@""
                                                      message:internetConnectionFailedMSG
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil, nil];
        [_inetFailedAlert show];
    } else {
        _inetRestoredAlert = [[UIAlertView alloc] initWithTitle:@""
                                                      message:kInternetRestoredMSG
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil, nil];
        [_inetRestoredAlert show];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityManagerNetworkStatusChanged
                                                        object:isReachable];
}


@end
