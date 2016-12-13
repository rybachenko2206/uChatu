//
//  AllFriendsViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/9/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "AllPlayersViewController.h"
#import "ImaginarySettingsViewController.h"
#import "XMPPChatViewController.h"
//data sources
#import "ImaginaryFriendsDataSource.h"
#import "PublicImaginaryFriendsTableDataSource.h"
//managers
#import "WebService.h"
#import "AuthorizationManager.h"
#import "ReachabilityManager.h"
//model
#import "ImaginaryFriend.h"
//views
#import "UCFooterView.h"
#import "UICollectionView+CenteredLayout.h"

@interface AllPlayersViewController () <UICollectionViewDelegate, UITableViewDelegate, RealFriendsCellDelegate, UCFooterViewDelegate> {
    BOOL isInfoButtonPressed;
}

//outlets
@property (weak, nonatomic) IBOutlet UILabel *noFriendsInfoLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//private
@property (nonatomic, strong) NSIndexPath *infoButtonPressedIndexPath;
@property (nonatomic, strong) NSIndexPath *selectedCvIndexPath;
@property (strong, nonatomic) ImaginaryFriendsDataSource            *ifDataSource;
@property (strong, nonatomic) PublicImaginaryFriendsTableDataSource *piftDataSource;

//actions
- (IBAction)reloadTap:(id)sender;

@end

@implementation AllPlayersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _ifDataSource = [ImaginaryFriendsDataSource new];
    _collectionView.dataSource = _ifDataSource;
    _collectionView.delegate = self;
    
    _piftDataSource = [PublicImaginaryFriendsTableDataSource new];
    _piftDataSource.cellDelegate = self;
    _piftDataSource.mode = UCDataSourceModeAllUsers;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = _piftDataSource;
    
    if ([[ReachabilityManager sharedInstance] isReachable]) {
        [self requestUsersImaginaryFriends];
        [self requestRandomImaginaryFriends];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userWasFethchedWithObjectId:)
                                                 name:kAttachedObjectWasFetchedNotification
                                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(svProgressHudDidDismiss)
                                                 name:SVProgressHUDDidDisappearNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(avatarImageWasDownloaded:)
                                                 name:kAvatarImageWasDownloaded
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        return;
    } else {
        [self reloadUserData];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (!isInfoButtonPressed) {
        [self collectionView:_collectionView didDeselectItemAtIndexPath:_selectedCvIndexPath];
    }
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

- (void)dealloc {
    if (_tableView.delegate == self) {
        _tableView.delegate = nil;
    }
    if (_collectionView.delegate == self) {
        _collectionView.delegate = nil;
    }
}


#pragma mark Notification observers

- (void)userWasFethchedWithObjectId:(NSNotification *)notification {
    NSString *objectId = notification.object;
    if (!objectId) {
        return;
    }
    NSArray *visibleCells = [_tableView visibleCells];
    for (RealFriendsCell *cell in visibleCells) {
        if ([cell.imaginaryFriend.attachedToUser.objectId isEqualToString:objectId]) {
            NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
            cell.imaginaryFriend = _piftDataSource.imaginaryFriends[indexPath.row];
        }
    }
}

- (void)svProgressHudDidDismiss {
}

- (void)avatarImageWasDownloaded:(id)object {
    NSNotification *notification = object;
    NSString *objectId = notification.object;
    NSArray *cvVisibleCells = [_collectionView visibleCells];
    NSArray *tvVisibleCells = [_tableView visibleCells];
    for (ImaginaryFriendCollectionViewCell *cell in cvVisibleCells) {
        if ([cell.imaginaryFriend.objectId isEqualToString:objectId]) {
            NSIndexPath *reloadIndexPath = [_collectionView indexPathForCell:cell];
            [_collectionView reloadItemsAtIndexPaths:@[reloadIndexPath]];
            return;
        }
    }
    for (RealFriendsCell *cell in tvVisibleCells) {
        if ([cell.imaginaryFriend.objectId isEqualToString:objectId]) {
            NSIndexPath *reloadIndexPath = [_tableView indexPathForCell:cell];
            [_tableView reloadRowsAtIndexPaths:@[reloadIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
            return;
        }
    }
}


#pragma mark - Private methods

- (void)openChatWithChatRoom:(ChatRoom *)room initiator:(ImaginaryFriend *)initiator receiver:(ImaginaryFriend *)receiver {
    XMPPChatViewController *vc = [[UIStoryboard chats] instantiateViewControllerWithIdentifier:@"XMPPChatViewController"];
    vc.chatRoom = room;
    vc.myImFriend = initiator;
    vc.otherImFriend = receiver;
    vc.fromAllUsersRealFrScreen = YES;
    
    __weak typeof(self) weakSelf = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [weakSelf presentViewController:navController animated:YES completion:nil];
}

- (void)reloadUserData {
    if (isInfoButtonPressed) {
        isInfoButtonPressed = NO;
        
        if (self.infoButtonPressedIndexPath) {
            [self.tableView reloadRowsAtIndexPaths:@[self.infoButtonPressedIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            self.infoButtonPressedIndexPath = nil;
        }
        
        return;
    }
    [self requestUsersImaginaryFriends];
    [self requestRandomImaginaryFriends];
}

-(void)requestUsersImaginaryFriends {
    PFUser *currUser = [AuthorizationManager sharedInstance].currentUser;
    
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] getAllVisibleImaginaryFriendsForUser:currUser
                                                      completionBlock:^(ResponseInfo *response) {
                                                          NSArray *responseArray = [ImaginaryFriend sortImaginaryFriendsByName:response.objects];
                                                          [weakSelf setStateForInfoLabel:responseArray.count];
                                                          [weakSelf realoadCollectionViewSelectively:responseArray];
                                                          [weakSelf dismissSVProgressHudIfDownloaded];
                                                          [weakSelf.collectionView centrateLayout];
                                                          [weakSelf.collectionView reloadData];
                                                      }];
}


- (void)requestRandomImaginaryFriends {
    __weak typeof(self) weakSelf = self;
    
    if (![SVProgressHUD isVisible]) {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    }
    [[WebService sharedInstanse] getRandomImaginaryFriendsWithCompletion:^(ResponseInfo *response){
        if (response.success) {
            _piftDataSource.onlineStatuses = response.additionalInfo;
            _piftDataSource.imaginaryFriends = [NSMutableArray arrayWithArray:response.objects];
            [_tableView reloadData];
        }
        [weakSelf dismissSVProgressHudIfDownloaded];
    }];
}


- (void)realoadCollectionViewSelectively:(NSArray *)array {
    _ifDataSource.imaginaryFriends = array;
    [_collectionView reloadData];
}

- (void)setStateForInfoLabel:(NSInteger)countObjects {
    _noFriendsInfoLabel.hidden = countObjects != 0;
}

- (void)dismissSVProgressHudIfDownloaded {
    [SVProgressHUD dismiss];
}

- (void)sendInviteToRoleChatToImaginaryFriend:(ImaginaryFriend *)toImFriend {
    NSIndexPath *selected = [[self.collectionView indexPathsForSelectedItems] firstObject];
    ImaginaryFriend *fromImFried = self.ifDataSource.imaginaryFriends[selected.row];
    
    NSString *pushMsg = [NSString stringWithFormat:@"%@ %@", fromImFried.friendName, inviteToChatMSG];
    
    ChatRoom *room = [ChatRoom chatRoomWithInitiator:fromImFried receiver:toImFriend];
    [[WebService sharedInstanse] getUserWithObjectId:toImFriend.attachedToUser.objectId
                                          completion:^(ResponseInfo *response) {
                                              if (!response.error && response.objects.count == 1) {
                                                  PFUser *toUser = [response.objects lastObject];
                                                  
                                                  [[WebService sharedInstanse] sendPushNotificationToUser:toUser
                                                                                  fromImaginaryFriendName:fromImFried.friendName
                                                                                    toImaginaryFriendName:toImFriend.friendName
                                                                                              withMessage:pushMsg
                                                                                                  roomJID:room.roomJID
                                                                                         notificationType:PushNotificationTypeInviteToChat];
                                                  
                                                  [Utilities showAlertViewWithTitle:@""
                                                                            message:[NSString stringWithFormat:@"Invite to role-chat with %@ was sent", toImFriend.friendName]
                                                                  cancelButtonTitle:@"OK"];
                                              }
                                          }];
}


#pragma mark Delegate methods

#pragma mark - RealFriendsCellDelegate

- (void)realFriendSCellInfoButtonWasPressed:(RealFriendsCell *)cell {
    isInfoButtonPressed = YES;
    self.infoButtonPressedIndexPath = [self.tableView indexPathForCell:cell];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ImaginaryFriend *imFriend = _piftDataSource.imaginaryFriends[indexPath.row];
    ImaginarySettingsViewController *settingsVc = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"ImaginarySettingsViewController"];
    settingsVc.parseImaginaryFriend = imFriend;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVc];
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark — UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    ImaginaryFriendCollectionViewCell *cell = (ImaginaryFriendCollectionViewCell *)[_collectionView cellForItemAtIndexPath:_selectedCvIndexPath];
    cell.selectedBackgroundView = nil;
    cell.checkMarkImageView.hidden = YES;
    _selectedCvIndexPath = nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self collectionView:_collectionView didDeselectItemAtIndexPath:_selectedCvIndexPath];
    
    ImaginaryFriendCollectionViewCell *cell = (ImaginaryFriendCollectionViewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    CGRect newFrame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
    cell = (ImaginaryFriendCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.selectedBackgroundView = [ImaginaryFriendCollectionViewCell getSelectedBackgroundViewWithFrame:newFrame];
    cell.checkMarkImageView.hidden = NO;
    _selectedCvIndexPath = indexPath;
    
    [_collectionView centrateSelectedCell:cell];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (!_selectedCvIndexPath) {
        [Utilities showAlertViewWithTitle:@""
                                  message:@"Please, choose your identity for role-chat"
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    ImaginaryFriend *fromImFried = self.ifDataSource.imaginaryFriends[_selectedCvIndexPath.row];
    ImaginaryFriend *toImFriend = self.piftDataSource.imaginaryFriends[indexPath.row];
    
    [ChatRoom getChatRoomWithInitiator:fromImFried
                              receiver:toImFriend
                       completionBlock:^(ChatRoom *room, NSError *error) {
                           if (room) {
                               room.participantsImaginaryFriends = @[fromImFried, toImFriend];
                               [self openChatWithChatRoom:room initiator:fromImFried receiver:toImFriend];
                           }
                       }];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [RealFriendsCell heightForCell];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return [UCFooterView footerHeight];
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UCFooterView *footer = nil;
    CGRect footerFrame = CGRectMake(0, 0, CGRectGetWidth(_tableView.frame), [UCFooterView footerHeight]);
    footer = [[UCFooterView alloc] initWithFrame:footerFrame];
    footer.delegate = self;
    return footer;
}


#pragma mark - RealFriendsCellFooterDelegate

- (void)deselectCollectionViewCell {
    if (self.selectedCvIndexPath) {
        
    }
}

-(void)didTapInviteButton {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    UIViewController *sharing = [[UIStoryboard authentication] instantiateViewControllerWithIdentifier:@"SharingViewController"];
    sharing.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:sharing]
                       animated:YES
                     completion:nil];
}


#pragma mark Action methods

- (IBAction)reloadTap:(id)sender {
    [self requestRandomImaginaryFriends];
}


@end
