//
//  ChatsListViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 11/19/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#define CELL_HEIGHT 75.0f


#import "SharingViewController.h"
#import "AuthorizationManager.h"
#import "Utilities.h"
#import "WebService.h"
#import "LoginViewController.h"
#import "ChatsTableViewCell.h"
#import "CustomTabBarViewController.h"
#import "SharingViewController.h"
#import "OnlyYouChatViewController.h"
#import "CustomSegue.h"
#import "ChatWithFriendViewController.h"
#import "CoreDataManager.h"
#import "CDUserSettings.h"
#import "CDChatRoom.h"
#import "UCFooterView.h"
#import "ChatRoomsDataSource.h"
#import "XMPPChatViewController.h"
#import "ReachabilityManager.h"
#import "LocalDSManager.h"
#import "XMPPService.h"
#import "UIAlertView+Blocks.h"

#import "ChatsListViewController.h"

@interface ChatsListViewController () <UITableViewDelegate> {
    UIBarButtonItem *doneBarButtonItem;
    UIBarButtonItem *deleteAllBarButtonItem;
    UIBarButtonItem *editBarButtonItem;
    UIBarButtonItem *shareBarButtonItem;
}

@property (nonatomic, assign, readwrite) BOOL isEditing;
@property (strong, nonatomic) NSArray *myFriends;
@property (strong, nonatomic) NSArray *myFriendsChatRooms;
@property (strong, nonatomic) ChatRoomsDataSource *chatsDataSource;


@end

@implementation ChatsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _chatsDataSource = [ChatRoomsDataSource new];
    _chatsDataSource.viewController = self;
    
    self.title = @"Chats";
    
    self.tableView.delegate = self;
    self.tableView.dataSource = _chatsDataSource;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkStatusChanged:)
                                                 name:kReachabilityManagerNetworkStatusChanged
                                               object:nil];
    
    doneBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nvg_done_button_image"]
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(editBarButtonTapped:)];
    
    deleteAllBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nvg_deleteAll_button"]
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(deleteAllBarBarButtonItemTapped)];
    
    editBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nvg_edit_button_image"]
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(editBarButtonTapped:)];
    shareBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nvg_shareBarButtonItem_image"]
                                                          style:UIBarButtonItemStyleBordered
                                                         target:self
                                                         action:@selector(shareBarButtonTapped:)];
    editBarButtonItem.tintColor = [UIColor blackColor];
    shareBarButtonItem.tintColor = [UIColor blackColor];
    doneBarButtonItem.tintColor = [UIColor blackColor];
    deleteAllBarButtonItem.tintColor = [UIColor blackColor];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _chatsDataSource.cdChatRooms = [NSMutableArray arrayWithArray:[CDChatRoom getChatRoomsForUser:[AuthorizationManager sharedInstance].currentCDUser]];
    [self.tableView reloadData];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![AuthorizationManager sharedInstance].loggedIn) {
        [SVProgressHUD dismiss];
        [AuthorizationManager presentLoginViewControllerForViewController:self animated:NO];
        return;
    }
    
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [SVProgressHUD dismiss];
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] getChatRoomsForUser:[AuthorizationManager sharedInstance].currentUser
                                      withCompletion:^(ResponseInfo *chatRoomsResponse) {
                                          [SVProgressHUD dismiss];
                                          if (chatRoomsResponse.success && chatRoomsResponse.objects.count) {
                                              [self reloadUserDataWithChatRooms:chatRoomsResponse.objects
                                                                 onlineStatuses:chatRoomsResponse.additionalInfo];
                                              [self setUnreadMessageForChatRooms:chatRoomsResponse.objects];
                                              
                                              
                                          } else {
                                              _chatsDataSource.chatRooms = [NSMutableArray new];
                                              [_tableView reloadData];
                                          }
                                          if (chatRoomsResponse.error) {
                                              NSString *errString = [NSString stringWithFormat:@"-localized description -> %@\n-error code = %ld", [chatRoomsResponse.error localizedDescription], (long)[chatRoomsResponse.error code]];
                                              $l(@"--- error - %@", errString);
                                              
                                              [Utilities showAlertViewWithTitle:@"Parse Error"
                                                                        message:errString
                                                              cancelButtonTitle:@"Cancel"];
                                          }
                                          
                                      }];
}

- (void)viewDidDisappear:(BOOL)animated {
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

-(UINavigationItem *) navigationItem {
    UINavigationItem *navItem = [super navigationItem];

    navItem.rightBarButtonItem = _isEditing ? deleteAllBarButtonItem : shareBarButtonItem;
    navItem.leftBarButtonItem = _isEditing ? doneBarButtonItem : editBarButtonItem;
    
    return navItem;
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_tableView.delegate == self) {
        _tableView.delegate = nil;
    }
}


#pragma mark - Delegated methods:

#pragma mark - —UITableViewDelegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        ChatRoom *room = _chatsDataSource.chatRooms[indexPath.row];
        if ([ChatRoom isMyImFriendInitiatorInChatRoom:room]) {
            room.unreadMessagesCountInitiator = @(0);
        } else {
            room.unreadMessagesCountReceiver = @(0);
        }
        
        [self hideNotificationButtonForCellAtIndexPath:indexPath];
        [room saveInBackground];

        XMPPChatViewController *vc = [XMPPChatViewController xmppChatViewControllerWithRoom:room];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navController animated:YES completion:nil];
        
    } else if (indexPath.section == 1) {
        CDChatRoom *cdRoom = _chatsDataSource.cdChatRooms[indexPath.row];
        ChatWithFriendViewController *chatVC = [[UIStoryboard chats] instantiateViewControllerWithIdentifier:@"ChatWithFriendViewController"];
        chatVC.chatRoom = cdRoom;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:chatVC];
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navController animated:YES completion:nil];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}


#pragma mark - Action methods

- (void)editBarButtonTapped:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    _isEditing = !_isEditing;
    [self navigationItem];
    
    NSString *notificationName = _isEditing ? kChatsTableViewCellShouldShowLeftAccessoryButtonsNotification : kChatsTableViewCellShouldHideLeftAccessoryButtonsNotification;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

- (void)shareBarButtonTapped:(id)sender {
    SharingViewController *sharingVC = [[UIStoryboard authentication] instantiateViewControllerWithIdentifier:@"SharingViewController"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:sharingVC];
    navController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)deleteAllBarBarButtonItemTapped {
    [UIAlertView showWithTitle:@""
                       message:@"Delete all rooms?"
             cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Delete"]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex == 1) {
                              [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
                              [ChatRoom deleteChatRooms:_chatsDataSource.chatRooms
                                    withCompletionBlock:^(BOOL success, NSError *error) {
                                        [SVProgressHUD dismiss];
                                        if (success) {
                                            [Utilities showAlertViewWithTitle:@"" message:@"All chat rooms were deleted" cancelButtonTitle:@"OK"];
                                        } else if (error) {
                                            [Utilities showAlertViewWithTitle:@"Error" message:[error localizedDescription] cancelButtonTitle:@"Cancel"];
                                        }
                                        [self.chatsDataSource.chatRooms removeAllObjects];
                                        [self.tableView reloadData];
                                    }];
                              
                              for (CDChatRoom *room in _chatsDataSource.cdChatRooms) {
                                  [_chatsDataSource deleteCDChatRoom:room];
                              }
                              [_chatsDataSource.cdChatRooms removeAllObjects];
                              [self.tableView reloadData];
                          }
                      }];
}

#pragma mark - Notification observers

- (void)networkStatusChanged:(NSNotification *)notification {
    NSNumber *isReachable = notification.object;
    if (![isReachable boolValue]) {
        //
    } else {
        [self viewDidAppear:NO];
    }
}


#pragma mark - Private methods

- (void)setUnreadMessageForChatRooms:(NSArray *)chatRooms {
    NSUInteger msgCount = 0;
    
    for (ChatRoom *room in chatRooms) {
        if ([ChatRoom isMyImFriendInitiatorInChatRoom:room]) {
            msgCount += [room.unreadMessagesCountInitiator integerValue];
        } else {
            msgCount += [room.unreadMessagesCountReceiver integerValue];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUnreadMessageCountChanged
                                                        object:@(msgCount)];
}

- (void)reloadUserDataWithChatRooms:(NSArray *)rooms onlineStatuses:(NSDictionary *)statuses {
    rooms = [self sortByUpdateDateChatRooms:rooms];
    _chatsDataSource.chatRooms = [NSMutableArray arrayWithArray:rooms];
    _chatsDataSource.onlineStatuses = statuses;
    [_tableView reloadData];
}

- (NSArray *)sortByUpdateDateChatRooms:(NSArray *)rooms {
    NSSortDescriptor *sortDescr = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt"
                                                                ascending:NO];
    return [rooms sortedArrayUsingDescriptors:@[sortDescr]];
}

- (NSArray *)getOtherImaginaryFriendsFromChatRooms:(NSArray *)chatRooms {
    NSMutableArray *imFriends = [NSMutableArray new];
    
    for (ChatRoom *chatRoom in chatRooms) {
        if ([chatRoom.initiatorID isEqualToString:[AuthorizationManager sharedInstance].currentUser.objectId]) {
            [imFriends addObject:chatRoom.receiverImaginaryFriendID];
        } else {
            [imFriends addObject:chatRoom.initiatorImaginaryFriendID];
        }
    }
    
    return imFriends;
}

- (void)hideNotificationButtonForCellAtIndexPath:(NSIndexPath *)indexPath {
    ChatsTableViewCell *cell = (ChatsTableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
    cell.notificationButton.hidden = YES;
}

@end
