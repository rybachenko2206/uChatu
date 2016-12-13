//
//  XMPPChatViewController.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/11/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import "PrefixHeader.pch"
#import "RoundedImageView.h"
#import "ImagePickerManager.h"
#import "UChatuMessage.h"
#import "WebService.h"
#import "ImaginaryFriend.h"
#import "AuthorizationManager.h"
#import "OnlyYouMessageCell.h"
#import "FriendMessageCell.h"
#import "SharedDateFormatter.h"
#import "FriendMessageCell.h"
#import "ChatTitleView.h"
#import "chatPhoto.h"
#import "UIImageView+WebCache.h"
#import "ReachabilityManager.h"
#import "Reachability.h"
#import "AudioPlayer.h"
#import <Parse/Parse.h>
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "CDManagerVersionTwo.h"
//#import "LocalDSManager.h"
// XMPP
#import "XMPPService.h"
#import "XMPPRoom.h"
#import "XMPPMessage.h"
#import "XMPPJID.h"
#import "NSXMLElement+XEP_0203.h"
#import "XMPPMessage+XEP0045.h"
#import "XMPPRoomCoreDataStorage.h"
//data source
#import "XMPPChatDataSource.h"
//categories
#import "UIStoryboard+Multiple.h"
//controllers
#import "ReviewImageViewController.h"
#import "ImaginarySettingsViewController.h"

#import "XMPPChatViewController.h"

@interface XMPPChatViewController () <ImagePickerDelegate, XMPPServiceDelegate, XMPPRoomDelegate, UITextFieldDelegate, UITableViewDelegate, UIActionSheetDelegate> {
    BOOL keyboardIsShown;
    BOOL isPresentVC;
    BOOL isNeedDownloadMessages;
    BOOL backButtonWasTapped;
    BOOL anyMsgWasSent;
    BOOL wasConnectedToWrongRoom;
    NSDictionary *chatRoomStartState;
    NSNumber *isOnline;
    dispatch_queue_t saveMessageSerialQueue;
}

//Private
@property (strong, nonatomic) XMPPService *xmppService;
@property (strong, nonatomic) XMPPChatDataSource *dataSource;
@property (strong, nonatomic) XMPPRoom *xmppRoom;

@property (nonatomic, strong) UIImage *addedImage;
@property (nonatomic) ImagePickerManager *imagePicker;
@property (strong, nonatomic) UIActionSheet *addPhotoActionSheet;
@property (nonatomic, strong) RoundedImageView *avatarIconImageView;

//Outlets
@property (weak, nonatomic) IBOutlet UIImageView *addImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *sendButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *photoButtonOutlet;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UINavigationItem *chatNavigationItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoButtonRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageTFRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageViewBottomConstraint;

//Actions
- (IBAction)backButtonTapped:(id)sender;
- (IBAction)sendButtonTapped:(id)sender;
- (IBAction)photoButtonTapped:(id)sender;
- (IBAction)infoBarButtonTapped:(id)sender;
- (IBAction)tableViewWasTapped:(id)sender;


@end


@implementation XMPPChatViewController

#pragma mark Static methods

+(instancetype)xmppChatViewControllerWithRoom:(ChatRoom *)room {
    XMPPChatViewController *vc = [[UIStoryboard chats] instantiateViewControllerWithIdentifier:@"XMPPChatViewController"];
    vc.chatRoom = room;
    return vc;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
//    $l("chatRoom - %@", self.chatRoom);
    
    saveMessageSerialQueue = dispatch_queue_create("saveMessageSerialQueue", NULL);

    [self connect];
    
    [self activateChatRoomIfNeeded];
    
    self.xmppService = [XMPPService sharedInstance];
    self.xmppService.delegate = self;
    
    self.dataSource = [XMPPChatDataSource new];
    self.dataSource.messages = [NSMutableArray new];
    
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self;
    self.messageTextField.delegate = self;
    
    self.imagePicker = [[ImagePickerManager alloc] init];
    self.imagePicker.delegate = self;
    
    
    if (self.chatRoom.wasDeactivatedBoolValue) {
        [self setSendButtonsEnabled:NO];
    }
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(willResignActive:)
                          name: UIApplicationWillResignActiveNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(networkStatusWasChanged:)
                          name:kReachabilityManagerNetworkStatusChanged
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(xmppStremConnectionWasChanged:)
                          name:kXMPPStremConnectionWasChanged
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(xmppStreamdidConnect)
                          name:kXMPPStreamDidConectNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(xmppStreamAuthenticated:)
                          name:kXMPPStreamDidAutentificateNotification
                        object:nil];
    [defaultCenter addObserver:self
                     selector:@selector(appGoesToSleep)
                         name:kApplicationGoesToSleepNotification
                       object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(sentImageWasTapped:)
                          name:kAttachedImageWasTappedNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(avatarImageWasDownloaded:)
                          name:kAvatarImageWasDownloaded
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(appDidEnterBackground:)
                          name:UIApplicationDidEnterBackgroundNotification
                        object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(keyboardWillShow:)
                          name:UIKeyboardWillShowNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(keyboardWillHide:)
                          name:UIKeyboardWillHideNotification
                        object:nil];
    
    if (self.chatRoom.participantsImaginaryFriends) {
        [self setMyAndOtherImaginaryFriends];
        [self setNavigationBarStyle];
    } else {
        [self loadImaginaryFriendsForChatRoom];
    }
    
    if (_messageTextField.text.length >= 1) {
        _addImageView.hidden = YES;
    }
    
    NSArray *cdChatMessages = [[CDManagerVersionTwo sharedInstance] getAllCDChatMessagesWithRoomJID:self.chatRoom.roomJID];
    if (cdChatMessages.count) {
        NSMutableArray *uChatuMessages = [NSMutableArray arrayWithArray:[self convertCDChatMessagesToUchatuMessages:cdChatMessages]];
        self.dataSource.messages = uChatuMessages;
        [self.tableView reloadData];
        [self scrollToBottom];
    }
    
    [self setTextFieldPlaceholder];
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!isPresentVC) {
        [self connectToChatRoom];
        [self setSendButtonsEnabled:self.xmppRoom.isJoined];
    }
    
    isPresentVC = NO;
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self
                             name:UIKeyboardWillShowNotification
                           object:nil];
    
    [defaultCenter removeObserver:self
                             name:UIKeyboardWillHideNotification
                           object:nil];
}

- (void)dealloc {
    if (self.tableView.delegate == self) {
        _tableView.delegate = nil;
    }
    _tableView.dataSource = nil;
    _chatRoom = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_xmppRoom leaveRoom];
    [XMPPService sharedInstance].xmppRoom = nil;
}


#pragma mark - Action methods

- (IBAction)backButtonTapped:(id)sender {
    if ([[ReachabilityManager sharedInstance] isReachable] && self.xmppRoom.isJoined) {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeNone];
        backButtonWasTapped = YES;
        NSInteger countMsg = 0;
        if ([ChatRoom isMyImFriendInitiatorInChatRoom:self.chatRoom]) {
            self.chatRoom.unreadMessagesCountInitiator = @(countMsg);
        } else {
            self.chatRoom.unreadMessagesCountReceiver = @(countMsg);
        }
        if (!anyMsgWasSent && self.fromAllUsersRealFrScreen) {
            self.chatRoom.wasDeleted = chatRoomStartState[@"wasDeleted"];
            self.chatRoom.wasDeactivated = chatRoomStartState[@"wasDeactivated"];
            self.chatRoom.deletedByUser = chatRoomStartState[@"deletedByUser"];
        }
        [self.chatRoom saveInBackground];
        [self.xmppRoom leaveRoom];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)sendButtonTapped:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        return;
    }
    if (![XMPPService sharedInstance].isConnected || !self.xmppRoom.isJoined) {
        $l("\n\n-----XMPPStream isConnected = %d, XMPPRoom isJoined = %d", [XMPPService sharedInstance].isConnected, self.xmppRoom.isJoined);
        return;
    }
    [self showPhotoButtonAnimated];
    NSString *msgBody = [self createXMPPMessageBodyWithTextMessage];
    [self sendXMPPMessageWithBody:msgBody];
    [self showPhotoButtonAnimated];
}

- (IBAction)photoButtonTapped:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        return;
    }
    self.addPhotoActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Take Picture", @"Choose Picture", nil];
    [self.addPhotoActionSheet showInView:self.view];
}

- (IBAction)infoBarButtonTapped:(id)sender {
    
    isPresentVC = YES;
    ImaginarySettingsViewController *settingsVc = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"ImaginarySettingsViewController"];
    settingsVc.parseImaginaryFriend = self.otherImFriend;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVc];
    [self presentViewController:navController animated:YES completion:nil];
}

- (IBAction)tableViewWasTapped:(id)sender {
    [self hideKeyboardIfTableViewWasTapped];
}


#pragma mark - Notification observers

- (void)appDidEnterBackground:(NSNotification *)notification {
    [self.xmppRoom leaveRoom];
}

- (void)appGoesToSleep {
    if (self.xmppRoom.isJoined) {
        [self.xmppRoom leaveRoom];
    } else {
        [self connect];
    }
}

- (void)xmppStreamdidConnect {

}

- (void)xmppStreamAuthenticated:(NSNotification *)notification {
    NSNumber *object = notification.object;
    BOOL isAuthenticated = [object boolValue];
    if (isAuthenticated) {
        [self connectToChatRoom];
    }
}

- (void)xmppStremConnectionWasChanged:(NSNotification *)notification {
    NSNumber *object = notification.object;
    BOOL isConnected = [object boolValue];
    
    if (!isConnected && !wasConnectedToWrongRoom) {
        [SVProgressHUD dismiss];
        [self setSendButtonsEnabled:isConnected];
    } else if (!isConnected && wasConnectedToWrongRoom) {
        [self connectToChatRoom];
    }
}

- (void)networkStatusWasChanged:(NSNotification *)notification {
    NSNumber *object = notification.object;
    BOOL isReachable = [object boolValue];
    
    if (!isReachable) {
        [self.xmppRoom leaveRoom];
        [self setSendButtonsEnabled:isReachable];
    }
}

- (void)avatarImageWasDownloaded:(id)object {
    NSNotification *notification = object;
    NSString *objectId = notification.object;
    NSArray *tvVisibleCells = [self.tableView visibleCells];
    
    for (NSInteger i = 0; i < tvVisibleCells.count; i++) {
        UITableViewCell *cell = tvVisibleCells[i];
        if ([cell isKindOfClass:[FriendMessageCell class]]) {
            FriendMessageCell *frCell = tvVisibleCells[i];
            if ([frCell.uchatuMessage.ownerImaginaryFriend.objectId isEqualToString:objectId]) {
                frCell.uchatuMessage = frCell.uchatuMessage;
            }
            
        }
    }
}

-(void) willResignActive:(NSNotification *)notification {
    [self.messageTextField resignFirstResponder];
}

-(void) keyboardWillHide:(NSNotification *)notification {
    _addImageView.hidden = NO;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3f
                     animations:^{
                         weakSelf.messageViewBottomConstraint.constant = 0;
                         [weakSelf.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [self scrollToBottom];
                     }];
    
    keyboardIsShown = NO;
}


-(void) keyboardWillShow:(NSNotification *)notification {
    _addImageView.hidden = YES;
    
    NSDictionary* userInfo = [notification userInfo];
    
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat constantValue = keyboardSize.height;
    
    NSTimeInterval animationDuration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateKeyframesWithDuration:animationDuration
                                   delay:0.0
                                 options:curve
                              animations:^{
                                  weakSelf.messageViewBottomConstraint.constant = constantValue;
                                  [weakSelf.view layoutIfNeeded];
                              }
                              completion:^(BOOL finished){
                                  [self scrollToBottom];
                              }];
    
    keyboardIsShown = YES;
}

- (void)sentImageWasTapped:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[NSString class]]) {
        return;
    }
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        return;
    }
    NSString *fullImageURL = notification.object;
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    [manager downloadImageWithURL:[NSURL URLWithString:fullImageURL]
                          options:0
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                             // progression tracking code
                         }
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                            if (image) {
                                [SVProgressHUD dismiss];
                                ReviewImageViewController *reviewImageVC = [[UIStoryboard chats] instantiateViewControllerWithIdentifier:@"ReviewImageViewController"];;
                                reviewImageVC.imageForReview = image;
                                reviewImageVC.avatarPhoto = self.otherImFriend.avatarPhoto;
                                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:reviewImageVC];
                                [self presentViewController:navController animated:YES completion:nil];
                                isPresentVC = YES;
                            } else {
                                [Utilities showAlertViewWithTitle:@"Error!"
                                                          message:[error localizedDescription]
                                                cancelButtonTitle:@"Cancel"];
                            }
                        }];
}


#pragma mark Private methods

- (void)setTextFieldPlaceholder {
    if ([self.otherImFriend isBlockedByUser:[AuthorizationManager sharedInstance].currentUser] ||
        [self.myImFriend isBlockedByUser:self.otherImFriend.attachedToUser]) {
        
        self.messageTextField.placeholder = @"    Blocked";
        [self setSendButtonsEnabled:NO];
        
    } else {
        self.messageTextField.placeholder = @"    Your message";
        [self setSendButtonsEnabled:YES];
    }
}

- (void)connectToRoom:(ChatRoom *)room sinceDate:(NSDate *)sinceDate {
    if (!self.xmppRoom ||
        (self.xmppRoom && ![self.xmppRoom.roomJID.user isEqualToString:[room.roomJID lowercaseString]])) {
        
        NSString *roomId = room.roomJID;
        XMPPJID * roomJID = [XMPPJID jidWithString:[roomId stringByAppendingFormat:@"@%@", [[XMPPService sharedInstance] chatHostName]]];
        self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:[XMPPRoomCoreDataStorage sharedInstance]
                                                      jid:roomJID];
        [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    [[XMPPService sharedInstance] createOrJoinToRoom:self.xmppRoom sinceDate:sinceDate];
    [XMPPService sharedInstance].xmppRoom = self.xmppRoom;
}

- (void)connectToChatRoom {
    if ([XMPPService sharedInstance].xmppStream.isConnecting || [XMPPService sharedInstance].xmppStream.isAuthenticating) {
        return;
    }
    
    if ([XMPPService sharedInstance].isConnected  && [XMPPService sharedInstance].xmppStream.isAuthenticated) {
        NSDate *sinceDate = [self getLastMessageDate];
        [self connectToRoom:self.chatRoom
                  sinceDate:sinceDate];
    } else {
        [[XMPPService sharedInstance] signIn];
    }
}

- (void)activateChatRoomIfNeeded {
    if (self.fromAllUsersRealFrScreen && self.chatRoom.wasDeactivatedBoolValue) {
        
        self.chatRoom.wasDeactivated = self.chatRoom.wasDeactivated ? self.chatRoom.wasDeactivated : @(NO);
        self.chatRoom.wasDeleted = self.chatRoom.wasDeleted ? self.chatRoom.wasDeleted : @(NO);
        self.chatRoom.deletedByUser = self.chatRoom.deletedByUser ? self.chatRoom.deletedByUser : @"";
        
        chatRoomStartState = @{@"wasDeactivated" : self.chatRoom.wasDeactivated,
                               @"wasDeleted" : self.chatRoom.wasDeleted,
                               @"deletedByUser" : self.chatRoom.deletedByUser
                               };
        self.chatRoom.wasDeactivated = @(NO);
        self.chatRoom.wasDeleted = @(NO);
        self.chatRoom.deletedByUser = @"";
    }
}

- (void)saveInBackroundXMPPMessage:(XMPPMessage *)message {
    NSPersistentStoreCoordinator *psc = [CDManagerVersionTwo sharedInstance].managedObjectContext.persistentStoreCoordinator;
    dispatch_async(saveMessageSerialQueue, ^{
        NSManagedObjectContext *moContext = [[NSManagedObjectContext alloc] init];
        [moContext setPersistentStoreCoordinator:psc];
        [CDChatMessage messageWithXMPPMessage:message chatRoomJID:self.chatRoom.roomJID inContext:moContext];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refetchMessages) object:nil];
            [self performSelector:@selector(refetchMessages) withObject:nil afterDelay:0.2];
        });
    });
}

- (NSDate *)getLastMessageDate {
    NSDate *lastMsgDate = LAST_MESSAGE_DATE_DEFAULT; // 01.02.2015
    if (self.dataSource.messages.count) {
        UChatuMessage *msg = [self.dataSource.messages lastObject];
        lastMsgDate = msg.cdChatMessage.createdAt ? msg.cdChatMessage.createdAt : lastMsgDate;
    }
    return lastMsgDate;
}

- (void)connect {
    if (![[XMPPService sharedInstance] isConnected]) {
        [[XMPPService sharedInstance] signIn];
    }
}

- (NSMutableArray *)convertCDChatMessagesToUchatuMessages:(NSArray *)cdChatMessages {
    NSMutableArray *uChatuMessages = [NSMutableArray new];
    
    for (CDChatMessage *cdMessage in cdChatMessages) {
        ImaginaryFriend *imFriend = [self imaginaryFriendInChatRoomWithObjectId:cdMessage.ownerObjectId];
        UChatuMessage *uchatuMsg = [UChatuMessage uChatuMessageWithCDChatMessage:cdMessage imaginaryFriend:imFriend];
        [uChatuMessages addObject:uchatuMsg];
    }
    
    return uChatuMessages;
}

- (void)loadImaginaryFriendsForChatRoom {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] getImaginaryFriendsWithObjectIds:@[self.chatRoom.initiatorImaginaryFriendID, self.chatRoom.receiverImaginaryFriendID]
                                                       completion:^(ResponseInfo *imFriendsResponse) {
                                                         [SVProgressHUD dismiss];
                                                         if (imFriendsResponse.objects.count) {
                                                             self.chatRoom.participantsImaginaryFriends = imFriendsResponse.objects;
                                                             [self setMyAndOtherImaginaryFriends];
                                                             [self setNavigationBarStyle];
                                                         } else if (imFriendsResponse.error) {
                                                             [Utilities showAlertWithParseError:imFriendsResponse.error];
                                                         }
                                                     }];
}

- (void)setMyAndOtherImaginaryFriends {
    if (self.myImFriend && self.otherImFriend) {
        return;
    }
    ImaginaryFriend *firstObject = [self.chatRoom.participantsImaginaryFriends firstObject];
    if ([firstObject.attachedToUser.objectId isEqualToString:[AuthorizationManager sharedInstance].currentUser.objectId]) {
        self.myImFriend = firstObject;
        self.otherImFriend = [self.chatRoom.participantsImaginaryFriends lastObject];
    } else {
        self.myImFriend = [self.chatRoom.participantsImaginaryFriends lastObject];
        self.otherImFriend = firstObject;
    }
}

- (ImaginaryFriend *)imaginaryFriendInChatRoomWithObjectId:(NSString *)objectId {
    ImaginaryFriend *imFriend = nil;
    
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"attachedToUser.objectId = %@", objectId];
//    imFriend = [[self.chatRoom.participantsImaginaryFriends filteredArrayUsingPredicate:predicate] lastObject];
    if ([objectId isEqualToString:self.myImFriend.attachedToUser.objectId]) {
        imFriend = self.myImFriend;
    } else if ([objectId isEqualToString:self.otherImFriend.attachedToUser.objectId]) {
        imFriend = self.otherImFriend;
    } else {
        $l("\n\n---error! imFriend wasn't found");
    }
    
    return imFriend;
}

-(void) scrollToBottom {
    if (!self.dataSource.messages.count) {
        return;
    }
    
//    if (self.tableView.contentSize.height > self.tableView.frame.size.height) {
//        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
//        [self.tableView setContentOffset:offset animated:YES];
//    }
    if (self.dataSource.messages.count > 0) {
        NSInteger lastMsgIndex = self.dataSource.messages.count - 1;
        NSIndexPath *indPath = [NSIndexPath indexPathForRow:lastMsgIndex inSection:0];
        
        [self.tableView scrollToRowAtIndexPath:indPath
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];
    }
    
}

- (void)reloadTableView {
    [SVProgressHUD dismiss];
    
    if (self.dataSource.messages.count > 0) {
        [self.tableView reloadData];
        [self scrollToBottom];
    }
}

- (void)refetchMessages {
    [SVProgressHUD dismiss];
    NSArray *messages = [[CDManagerVersionTwo sharedInstance] getAllCDChatMessagesWithRoomJID:_chatRoom.roomJID];
    if (!messages.count) {
        return;
    }
    NSMutableArray *newIndexPaths = [NSMutableArray new];
    messages = [self convertCDChatMessagesToUchatuMessages:messages];
    self.dataSource.messages = [NSMutableArray arrayWithArray:messages];
    for (UChatuMessage *msg in messages) {
        NSInteger objIndex = [self.dataSource.messages indexOfObject:msg];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:objIndex inSection:0];
        [newIndexPaths addObject:indexPath];
    }
    [self reloadTableView];
}

- (void)insertMessagesAtIndexPaths:(NSArray *)indexPaths {
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
}

- (void)hidePhotoButtonAnimated {
    [UIView animateWithDuration:0.5 animations:^{
        _photoButtonRightConstraint.constant = -44;
        _messageTFRightConstraint.constant = 4;
        [self.view layoutIfNeeded];
        _photoButtonOutlet.alpha = 0;
    }];
}

- (void)showPhotoButtonAnimated {
    [UIView animateWithDuration:0.5 animations:^{
        _messageTFRightConstraint.constant = 50;
        _photoButtonRightConstraint.constant = 2;
        [self.view layoutIfNeeded];
        _photoButtonOutlet.alpha = 1;
    }];
}

- (void)sendPhoto {
    if (!_addedImage) {
        return;
    }
    
    UIImage *thmbImage = [Utilities generateThumbnailImageFromImage:_addedImage];
    UIImage *fullImage = [Utilities generateFullScreenImageFromImage:_addedImage];
    
    ChatPhoto *chPhoto = [ChatPhoto object];
    chPhoto.attachedToChatRoom = self.chatRoom;
    
    NSData *thmbData = UIImagePNGRepresentation(thmbImage);
    PFFile *thmbFile = [PFFile fileWithName:@"thumbnailImage.png" data:thmbData];
    chPhoto.thumbnailImage = thmbFile;
    
    NSData *fullImgData = UIImagePNGRepresentation(fullImage);
    PFFile *fullImgFile = [PFFile fileWithName:@"fullImage.png" data:fullImgData];
    chPhoto.fullImage = fullImgFile;
    
    [SVProgressHUD showWithStatus:@"Uploading image.." maskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] saveChatPhoto:chPhoto completion:^(ResponseInfo *response){
        [SVProgressHUD dismiss];
        if (response.error) {
            [Utilities showAlertWithParseError:response.error];
        } else if (response.success) {
            NSString *dateStr = [SharedDateFormatter getStringFromDate:[NSDate date]
                                                            withFormat:DATE_FORMAT_FULL];
            NSDictionary *msgDict = @{kXMPPFullImagemageURL : chPhoto.fullImage.url,
                                      kXMPPThumbnailImagemageURL : chPhoto.thumbnailImage.url,
                                      kXMPPThumbnailWidth : @(thmbImage.size.width),
                                      kXMPPThumbnailHeight : @(thmbImage.size.height),
                                      kXMPPcreatedAt : dateStr,
                                      kXMPPmessageText : @"",
                                      kXMPPmessageOwner : [AuthorizationManager sharedInstance].currentUser.objectId,
                                      };
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:msgDict options:1 error:&error];
            NSString *msgBody = [[NSString alloc] initWithData:jsonData
                                                      encoding:NSUTF8StringEncoding];
            
            [self sendXMPPMessageWithBody:msgBody];
        }
    }];
    
    self.addedImage = nil;
}

- (void)sendXMPPMessageWithBody:(NSString *)messageBody {
    if (!messageBody) {
        return;
    }
    if (![[XMPPService sharedInstance] isConnected] || !self.xmppRoom.isJoined) {
        [Utilities showAlertViewWithTitle:@""
                                  message:[NSString stringWithFormat:@"XMPPService isConnected = %d, \n_xmppRoom.isJoined = %d", [[XMPPService sharedInstance] isConnected], self.xmppRoom.isJoined]
                        cancelButtonTitle:@"OK"];
        self.messageTextField.text = @"";
        return;
    }
    [self showPhotoButtonAnimated];
    
    XMPPMessage *message = [XMPPMessage messageWithType:@"groupchat" to:self.xmppRoom.roomJID];
    NSString *messageID = [[XMPPService sharedInstance].xmppStream generateUUID];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addBody:messageBody];
    
    [self.xmppRoom sendMessage:message];
    anyMsgWasSent = YES;
    $l("---send message to room with roomJID - \n%@", self.xmppRoom.roomJID);
    
    [self sendPushNotificationAboutMessage];
    self.chatRoom.lastMessage = _messageTextField.text ? _messageTextField.text : @"sent image";
    [self incrementUnreadMessageCount];
    [self.chatRoom saveInBackground];
    
    self.messageTextField.text = @"";
    self.addedImage = nil;
}

- (void)incrementUnreadMessageCount {
    [[WebService sharedInstanse] getChatRoomWithRoomJID:self.chatRoom.roomJID completion:^(ResponseInfo *response) {
        if (response.success) {
            if (response.objects.count) {
                self.chatRoom = [response.objects lastObject];
            }
            if ([ChatRoom isMyImFriendInitiatorInChatRoom:self.chatRoom]) {
                [self.chatRoom incrementKey:@"unreadMessagesCountReceiver"];
            } else {
                [self.chatRoom incrementKey:@"unreadMessagesCountInitiator"];
            }
            [self.chatRoom saveInBackground];
        }
        
        if (response.error) {
            $l(" -- error - %@", [response.error localizedDescription]);
        }
    }];
}



- (NSString *)createXMPPMessageBodyWithTextMessage {
    if (!_messageTextField.text.length) {
        return nil;
    }
    NSString *dateStr = [SharedDateFormatter getStringFromDate:[NSDate date]
                                                    withFormat:DATE_FORMAT_FULL];
    NSDictionary *msgDict = @{kXMPPmessageText : _messageTextField.text,
                              kXMPPcreatedAt : dateStr,
                              kXMPPmessageOwner : [AuthorizationManager sharedInstance].currentUser.objectId,
                              };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:msgDict options:1 error:&error];
    NSString *msgBody = [[NSString alloc] initWithData:jsonData
                                              encoding:NSUTF8StringEncoding];
    return msgBody;
}

- (void)sendPushNotificationAboutMessage {
    [[WebService sharedInstanse] sendPushNotificationToUser:self.otherImFriend.attachedToUser
                                    fromImaginaryFriendName:self.myImFriend.friendName
                                      toImaginaryFriendName:self.otherImFriend.friendName
                                                withMessage:@"new message"
                                                    roomJID:self.chatRoom.roomJID
                                           notificationType:PushNotificationTypeNewMessage];
}


-(void) setNavigationBarStyle {
    self.navigationController.navigationBar.translucent = NO;
    ChatTitleView *customTitleView = nil;
    
    PFUser *user = self.otherImFriend.attachedToUser;
    [user fetchIfNeeded];
    if ([user isDataAvailable]) {
        isOnline = user.isOnline;
    }
    if (self.chatRoom.wasDeactivatedBoolValue ) {
        isOnline = @(NO);
    }
    BOOL isBlocked = [self.otherImFriend isBlockedByUser:[AuthorizationManager sharedInstance].currentUser] ||
                     [self.myImFriend isBlockedByUser:self.otherImFriend.attachedToUser];
    customTitleView = [[ChatTitleView alloc] initWithTitle:self.otherImFriend.friendName
                                                  isOnline:[isOnline boolValue]
                                                 isBlocked:isBlocked];
    self.dataSource.isCompanionOnline = isOnline;
    
    self.navigationItem.titleView = customTitleView;
}

- (void)setSendButtonsEnabled:(BOOL)isEnabeled {
    if ([self.otherImFriend isBlockedByUser:[AuthorizationManager sharedInstance].currentUser] ||
        [self.myImFriend isBlockedByUser:self.otherImFriend.attachedToUser] ||
        self.chatRoom.wasDeactivatedBoolValue) {
        
        _sendButtonOutlet.enabled = NO;
        _photoButtonOutlet.enabled = NO;
        _messageTextField.enabled = NO;
        return;
    }
    
    _sendButtonOutlet.enabled = isEnabeled;
    _photoButtonOutlet.enabled = isEnabeled;
    _messageTextField.enabled = isEnabeled;
}

- (BOOL)addToDataSourceXMPPMessage:(XMPPMessage *)message {
    if (![[XMPPService sharedInstance] isConnected] || !self.xmppRoom.isJoined) {
        return NO;
    }
    
    CDChatMessage *cdChatMessage = [CDChatMessage messageWithXMPPMessage:message
                                                      chatRoomJID:self.chatRoom.roomJID
                                                        inContext:[CDManagerVersionTwo sharedInstance].managedObjectContext];
    
    NSString *from = message.fromStr;
    NSString *hostName = [[XMPPService sharedInstance] chatHostName];
    NSRange hostNameRange = [from rangeOfString:hostName];
    NSInteger fromIndex = hostNameRange.location + hostName.length + 1;
    from = [from substringFromIndex:fromIndex];
    ImaginaryFriend *imFriend = [self imaginaryFriendInChatRoomWithObjectId:from];
    UChatuMessage *uchatuMsg = [UChatuMessage uChatuMessageWithCDChatMessage:cdChatMessage
                                                             imaginaryFriend:imFriend];
    if (uchatuMsg) {
        [self.dataSource.messages addObject:uchatuMsg];
        return YES;
    } else {
        $l(@"---!!!!-----error!!! -> !uchatuMsg");
    }
    
    return NO;
}

- (void)hideKeyboardIfTableViewWasTapped {
    if (![_messageTextField isFirstResponder]) {
        return;
    }
    _messageTextField.text = @"";
    [_messageTextField resignFirstResponder];
    [self showPhotoButtonAnimated];
}

- (NSIndexPath *)indexPathForLastObject {
    NSUInteger msgCount = [self.dataSource.messages count];
    NSIndexPath *indPath = nil;
    if (msgCount) {
        indPath = [NSIndexPath indexPathForItem:msgCount - 1
                                      inSection:0];
    }
    if (indPath.row == self.dataSource.messages.count - 1) {
        return indPath;
    } else {
        $l("---indexPath = %@\n   dataSource.messages.count = %ld", indPath, self.dataSource.messages.count);
        return nil;
    }
}

- (void)insertNewMessage:(XMPPMessage *)message {
    BOOL isAdded = [self addToDataSourceXMPPMessage:message];
    NSIndexPath *indPath = [self indexPathForLastObject];
    if (isAdded && self.dataSource.messages.count && indPath) {
        [self insertMessagesAtIndexPaths:@[indPath]];
        [self scrollToBottom];
        [AudioPlayer playWithTrackName:@"facebook_chat_sound"];
    } else {
        NSString *warningMsg = [NSString stringWithFormat:@"Wrong indexPath = %@,\n self.dataSource.messages.count = %ld", indPath, (unsigned long)self.dataSource.messages.count];
        $l("--- Warning! - %@", warningMsg);
    }
}


#pragma mark Delegate methods:

#pragma mark - —UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self hideKeyboardIfTableViewWasTapped];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellHeight;
    UChatuMessage *message = self.dataSource.messages[indexPath.row];
    if ([message.ownerImaginaryFriend.attachedToUser.objectId isEqualToString:[AuthorizationManager sharedInstance].currentUser.objectId]) {
        cellHeight = [OnlyYouMessageCell heightForCellWithUChatuMessage:message];
    } else {
        cellHeight = [FriendMessageCell heightForCellWithUChatuMessage:message];
    }
    
    return cellHeight;
}

#pragma mark - —UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        return NO;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self hidePhotoButtonAnimated];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self hidePhotoButtonAnimated];
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
    NSString *trimmedString = [textField.text stringByTrimmingCharactersInSet:charSet];
    if ([trimmedString isEqualToString:@""]) {
        textField.text = @"";
    }
    
    [textField resignFirstResponder];
    [self showPhotoButtonAnimated];
    
    NSString *msgBody = [self createXMPPMessageBodyWithTextMessage];
    [self sendXMPPMessageWithBody:msgBody];
    
    return YES;
}

#pragma mark - —ImagePickerDelegate

-(void) imagePickerChoseImage:(UIImage *)image {
    self.addedImage = image;
    [self sendPhoto];
}

#pragma mark - —UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // take picture with camera
        isPresentVC = YES;
        [self.imagePicker createImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera
                                                  forViewController:self];
    } else if (buttonIndex == 1) {
        // choose picture from Camera Roll
        isPresentVC = YES;
        [self.imagePicker createImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                                  forViewController:self];
    }
}


#pragma mark - —XMPPServiceDelegate

- (void)xmppServiceDidSendMessage:(XMPPMessage *)message toStream:(XMPPStream *)stream {
    if (![[self.chatRoom.roomJID lowercaseString] isEqualToString:self.xmppRoom.roomJID.user]) {
        [Utilities showAlertViewWithTitle:@"Warning!\nxmppStream:didSendMessage:\nto wrong chatRoom"
                                  message:[NSString stringWithFormat:@"Right roomJID = %@ \n current roomJID _xmppRoom.roomJID.user = %@\n stream isConnected - %d, room isJoined - %d", self.chatRoom.roomJID, self.xmppRoom.roomJID.user, [XMPPService sharedInstance].xmppStream.isConnected, self.xmppRoom.isJoined]
                        cancelButtonTitle:@"OK"];
    }
}

#pragma mark - —XMPPRoomDelegate

- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJI {
    $c;
    $l("message - %@", message);
    
    if (message.wasDelayed) {
        if (![SVProgressHUD isVisible]) {
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        }
        [self saveInBackroundXMPPMessage:message];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refetchMessages) object:nil];
        [self performSelector:@selector(refetchMessages) withObject:nil afterDelay:0.2];
        
    } else {
        [self insertNewMessage:message];
    }
}

- (void)xmppRoomDidCreate:(XMPPRoom *)sender {
//    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [sender fetchConfigurationForm];
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender {
    
    [sender fetchMembersList];
    
    
//    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    $l("\n--Connected to room -> %@\n--parseChatRoomJID  -> %@\n--self.xmppRoom     -> %@", sender.roomJID.user, self.chatRoom.roomJID, self.xmppRoom.roomJID.user);
    
    NSString *roomJID = sender.roomJID.user;
    if (![roomJID isEqualToString:[self.chatRoom.roomJID lowercaseString]]) {
        wasConnectedToWrongRoom = YES;
        [self.xmppRoom leaveRoom];
    } else {
        wasConnectedToWrongRoom = NO;
    }
    
    [SVProgressHUD dismiss];
    [self setSendButtonsEnabled:sender.isJoined];
}

- (void)xmppRoomDidLeave:(XMPPRoom *)sender {
    $l("\n\n---Room left - %@\n", sender.roomJID.user);
    
    [self.xmppRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    _xmppRoom = nil;
    
    if (backButtonWasTapped) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if (wasConnectedToWrongRoom) {
        [[XMPPService sharedInstance].xmppStream disconnect];
    }
    [self setSendButtonsEnabled:sender.isJoined];
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items {
    
    
    
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm {
    NSXMLElement *newConfig = [configForm copy];
    NSArray *fields = [newConfig elementsForName:@"field"];
    
    BOOL shouldConfigure = NO;
    for (NSXMLElement *field in fields) {
        NSString *var = [field attributeStringValueForName:@"var"];
        if ([var isEqualToString:@"muc#roomconfig_persistentroom"]) {
            [field removeChildAtIndex:0];
            [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
            shouldConfigure = YES;
        }
    }
    if (shouldConfigure) {
        [sender configureRoomUsingOptions:newConfig];
    }
}


- (void)xmppRoom:(XMPPRoom *)sender didNotConfigure:(XMPPIQ *)iqResult {
    
}


@end
