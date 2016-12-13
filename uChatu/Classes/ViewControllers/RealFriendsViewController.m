//
//  RealFriendsViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/9/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "AddressBookUser.h"
#import "RealFriendsCell.h"
#import "ReachabilityManager.h"
#import "Utilities.h"
#import "PrefixHeader.pch"
#import "WebService.h"
#import "ResponseInfo.h"
#import "AuthorizationManager.h"
#import "ImaginaryFriendCollectionViewCell.h"
#import "MBProgressHUD.h"
#import "ImaginarySettingsViewController.h"
#import "AddressBookManager.h"
#import "UCFooterView.h"
#import "AddPhoneViewController.h"

#import "ImaginaryFriendsDataSource.h"
#import "PublicImaginaryFriendsTableDataSource.h"

#import "XMPPChatViewController.h"
#import "UICollectionView+CenteredLayout.h"

#import "RealFriendsViewController.h"


@interface RealFriendsViewController () <UICollectionViewDelegate, UITableViewDelegate, UIAlertViewDelegate, RealFriendsCellDelegate, UCFooterViewDelegate> {
    UIBarButtonItem *searchBarButton;
    
    BOOL isMyImaginaryFriendDownloaded;
    BOOL isFriendsImaginaryFriendDownloaded;
    BOOL isInfoButtonPressed;
    BOOL isAddPhoneWasChosen;
}


@property (nonatomic, strong) NSIndexPath *infoButtonPressedIndexPath;
@property (nonatomic, strong) NSIndexPath *selectedCvIndexPath;

@property (weak, nonatomic) IBOutlet UILabel *noFriendsInfoLabel;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) ImaginaryFriendsDataSource            *ifDataSource;
@property (strong, nonatomic) PublicImaginaryFriendsTableDataSource *piftDataSource;

@end


@implementation RealFriendsViewController

#pragma mark - Interface methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _ifDataSource = [ImaginaryFriendsDataSource new];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = _ifDataSource;
    
    _piftDataSource = [PublicImaginaryFriendsTableDataSource new];
    _piftDataSource.cellDelegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = _piftDataSource;
    
    _noFriendsInfoLabel.hidden = YES;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userWasFethchedWithObjectId:)
                                                 name:kAttachedObjectWasFetchedNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(svProgressHudDidDismiss)
                                                 name:SVProgressHUDDidDisappearNotification
                                               object:nil];
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook,
                                                 ^(bool granted, CFErrorRef error) {
                                                     if (granted) {
                                                         [self reloadUserData];
                                                     }
                                                 });
    }
    
    isMyImaginaryFriendDownloaded = NO;
    isFriendsImaginaryFriendDownloaded = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    if (![AuthorizationManager sharedInstance].currentUser.phoneNumber && !isAddPhoneWasChosen) {
        UIAlertView *phoneReqAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:kSetPhoneNumberMSG
                                                               delegate:self
                                                      cancelButtonTitle:@"Skip"
                                                      otherButtonTitles:@"Add", nil];
        phoneReqAlert.tag = 1;
        isAddPhoneWasChosen = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [phoneReqAlert show];
        });
    }
    
    [self reloadUserData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (!isInfoButtonPressed) {
        [self collectionView:_collectionView didDeselectItemAtIndexPath:_selectedCvIndexPath];
    }
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_tableView.delegate == self) {
        _tableView.delegate = nil;
    }
    if (_collectionView.delegate == self) {
        _collectionView.delegate = nil;
    }
}


#pragma mark - Notification observers

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
            cell.imaginaryFriend = _piftDataSource.imaginaryFriends[reloadIndexPath.row];
            return;
        }
    }
}


#pragma mark - Delegated methods:


#pragma mark - —UICollectionViewDelegate


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


#pragma mark - —UITableViewDelegate

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
    
    ImaginaryFriend *imFriend = self.ifDataSource.imaginaryFriends[_selectedCvIndexPath.row];
    ImaginaryFriend *otherImFriend = self.piftDataSource.imaginaryFriends[indexPath.row];

    [ChatRoom getChatRoomWithInitiator:imFriend
                              receiver:otherImFriend
                       completionBlock:^(ChatRoom *room, NSError *error) {
                           if (room) {
                               room.participantsImaginaryFriends = @[imFriend, otherImFriend];
                               [self openChatWithChatRoom:room initiator:imFriend receiver:otherImFriend];
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

#pragma mark - —RealFriendsCellDelegate

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


#pragma mark - —UCFooterViewDelegate

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


#pragma mark - —UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            AddPhoneViewController *addPhoneVC = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"AddPhoneViewController"];
            addPhoneVC.presentationType = UCPresentationTypeSettings;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPhoneVC];
            navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:navController animated:YES completion:nil];
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

- (NSArray *)getShortPhoneNumbersFromNumbers:(NSArray *)phoneNumbers {
    NSMutableArray *simplePhoneNumbers = [NSMutableArray new];
    for (NSString *phoneNum in phoneNumbers) {
        
        NSString *simpleNumber = [Utilities shortPhoneNumberFromNumber:phoneNum];
        [simplePhoneNumbers addObject:simpleNumber];
    }
    return simplePhoneNumbers;
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
    
    [[AddressBookManager sharedInstance] getAddressBookUsers];
    
    NSArray *allEmails = [AddressBookManager sharedInstance].allEmails;
    NSArray *allPhones = [AddressBookManager sharedInstance].allPhoneNumbers;
    allPhones = [self getShortPhoneNumbersFromNumbers:allPhones];
    
    if ([[ReachabilityManager sharedInstance] isReachable]) {
        [_collectionView reloadData];
        [_tableView reloadData];
        PFUser *currUser = [AuthorizationManager sharedInstance].currentUser;
        
        __weak typeof(self) weakSelf = self;
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        [[WebService sharedInstanse] getAllVisibleImaginaryFriendsForUser:currUser
                                                          completionBlock:^(ResponseInfo *response) {
                                                              NSArray *responseArray = [response.objects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"wasDeleted = %@ OR wasDeleted = nil", @(NO)]];
                                                              responseArray = [ImaginaryFriend sortImaginaryFriendsByName:responseArray];
                                                              [weakSelf setStateForInfoLabel:responseArray.count];
                                                              [weakSelf realoadCollectionViewSelectively:responseArray];
                                                              isMyImaginaryFriendDownloaded = YES;
                                                              [weakSelf dismissSVProgressHudIfDownloaded];
                                                              [weakSelf.collectionView centrateLayout];
                                                          }];
        
        [[WebService sharedInstanse] getImaginaryFriendsForUsersEmails:allEmails phoneNumbers:allPhones completionBlock:^(ResponseInfo *response){
            if (response.success) {
                _piftDataSource.onlineStatuses = response.additionalInfo;
                NSArray *responseArray = [ImaginaryFriend sortImaginaryFriendsByName:response.objects];
                [self realoadTableViewSelectively:responseArray];
            }
            isFriendsImaginaryFriendDownloaded = YES;
            [self dismissSVProgressHudIfDownloaded];
        }];
    }
}

- (void)realoadCollectionViewSelectively:(NSArray *)array {
    _ifDataSource.imaginaryFriends = array;
    [_collectionView reloadData];
}

- (void)realoadTableViewSelectively:(NSArray *)array {
    _piftDataSource.imaginaryFriends = [NSMutableArray arrayWithArray:array];
    [_tableView reloadData];
}

- (void)setStateForInfoLabel:(NSInteger)countObjects {
    if (!countObjects) {
        _noFriendsInfoLabel.hidden = NO;
    } else {
        _noFriendsInfoLabel.hidden = YES;
    }
}

- (void)dismissSVProgressHudIfDownloaded {
    if (isFriendsImaginaryFriendDownloaded && isMyImaginaryFriendDownloaded) {
        [SVProgressHUD dismiss];
    }
}


@end
