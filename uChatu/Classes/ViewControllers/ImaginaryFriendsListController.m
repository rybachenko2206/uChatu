//
//  ImaginaryFriendsListViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/10/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "ReachabilityManager.h"
#import "ImaginarySettingsViewController.h"
#import "AuthorizationManager.h"
#import "ResponseInfo.h"
#import "ImaginaryFriendCell.h"
#import "SynchronizeManager.h"
#import "ChatWithFriendViewController.h"
#import "CDChatRoom.h"
#import "WebService.h"
#import "UCFooterView.h"
#import "ImaginaryFriend.h"
#import "UIAlertView+Blocks.h"

#import "ImaginaryFriendsListController.h"

@interface ImaginaryFriendsListController () <UITableViewDataSource, UITableViewDelegate, ImaginaryFriendCellDelegate, SWTableViewCellDelegate> {
    CGSize screenSize;
    ImaginaryFriendCell *cellToDelete;
    
    BOOL isEditing;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *imaginaryFriends;
@property (nonatomic, strong) NSArray *parseImaginaryFriends;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButtonOutlet;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButtonOutlet;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButtonOutlet;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteAllButtonOutlet;

- (IBAction)editBarButtonTapped:(id)sender;
- (IBAction)addBarButtonTapped:(id)sender;
- (IBAction)deleteAllBarButtonTapped:(id)sender;



@end


@implementation ImaginaryFriendsListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    screenSize = [UIScreen mainScreen].bounds.size;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(avatarImageWasDownloaded:)
                                                 name:kAvatarImageWasDownloaded
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    isEditing = NO;
    
    CDUser *currCDUser = [AuthorizationManager sharedInstance].currentCDUser;
    self.imaginaryFriends = [NSMutableArray arrayWithArray:[[CDManagerVersionTwo sharedInstance] getCDImaginaryFriedsForCDUser:currCDUser]];
    [self sortByNameImagynaryFrieds];
    [self.tableView reloadData];
    
    if ([[ReachabilityManager sharedInstance] isReachable]) {
        [[WebService sharedInstanse] getAllImaginaryFriendsForUser:[AuthorizationManager sharedInstance].currentUser
                                                completionBlock:^(ResponseInfo *response) {
                                                    if (response.success && response.objects) {
                                                        self.parseImaginaryFriends = response.objects;
                                                        [[SynchronizeManager sharedInstance] synchronizeLocalDbWithParse:response.objects
                                                                                                              completion:^(BOOL finished, NSArray *objects){
                                                            if (finished) {
                                                                CDUser *currCDUser = [AuthorizationManager sharedInstance].currentCDUser;
                                                                self.imaginaryFriends = [NSMutableArray arrayWithArray:[[CDManagerVersionTwo sharedInstance] getCDImaginaryFriedsForCDUser:currCDUser]];
                                                                [self sortByNameImagynaryFrieds];
                                                                [self.tableView reloadData];
                                                            }
                                                        }];
                                                    } else if (response.error) {
                                                        NSString *errString = [NSString stringWithFormat:@"Something was woring.\nError - %@\nerror code = %ld", [response.error localizedDescription], (long)[response.error code]];
                                                        $l("\n\n---%@", errString);
                                                    }
                                                }];
    }
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSString *message = [NSString stringWithFormat:@"- parseImaginaryFriends.count = %lu,\n- cdImaginaryFriends.count = %lu", (unsigned long)_parseImaginaryFriends.count, (unsigned long)_imaginaryFriends.count];
//        [Utilities showAlertViewWithTitle:@"Screen state" message:message cancelButtonTitle:@"OK"];
//    });
}

- (UINavigationItem *)navigationItem {
    UINavigationItem *navItem = [super navigationItem];
    navItem.leftBarButtonItem = nil;
    navItem.rightBarButtonItem = nil;
    
    navItem.rightBarButtonItem  = isEditing ? _deleteAllButtonOutlet : _addButtonOutlet;
    navItem.leftBarButtonItem   = isEditing ? _doneButtonOutlet : _editButtonOutlet;
    
    return navItem;
}

- (void)dealloc {
    if (_tableView.delegate == self) {
        _tableView.delegate = nil;
    }
}


#pragma mark - Navigation

- (void)avatarImageWasDownloaded:(id)object {
    $c;
    [self.tableView reloadData];
//    NSNotification *notification = object;
//    NSString *objectId = notification.object;
//    NSArray *tvVisibleCells = [_tableView visibleCells];
//    for (ImaginaryFriendCell *cell in tvVisibleCells) {
//        if ([cell.imaginaryFriend.objectId isEqualToString:objectId]) {
//            NSIndexPath *reloadIndexPath = [_tableView indexPathForCell:cell];
//            cell.imaginaryFriend = self.imaginaryFriends[reloadIndexPath.row];
//            return;
//        }
//    }
}


#pragma mark - Action methods

- (IBAction)editBarButtonTapped:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    isEditing = !isEditing;
    [self navigationItem];
    
    NSString *notificationName = isEditing ? kShouldShowLeftAccessoryButtonsNotification : kShouldHideLeftAccessoryButtonsNotification;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

- (IBAction)addBarButtonTapped:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    ImaginarySettingsViewController *settingsVc = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"ImaginarySettingsViewController"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVc];
    [self presentViewController:navController animated:YES completion:nil];
}

- (IBAction)deleteAllBarButtonTapped:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    [UIAlertView showWithTitle:@""
                       message:@"Delete all ImaginaryFriends?"
             cancelButtonTitle:@"Cancel"
             otherButtonTitles:@[@"Delete"]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex == 1) {
                              [self deleteImaginaryFriends:_imaginaryFriends withCompletion:^{
                                  [_imaginaryFriends removeAllObjects];
                                  [_tableView reloadData];
                              }];
                          }
                      }];
}

-(void)deleteImaginaryFriends:(NSArray *)friends withCompletion:(void(^)())completion {
    
    NSMutableArray *pfFriendsToDelete = [NSMutableArray new];
    for (CDImaginaryFriend *cdImFriend in friends) {
        ImaginaryFriend *imFriend = [self getImaginaryFriendWithObjectId:cdImFriend.objectId];
        if (imFriend) {
            imFriend.wasDeleted = @(YES);
            [pfFriendsToDelete addObject:imFriend];
        }
        cdImFriend.wasDeleted = @(YES);
//        [context deleteObject:cdImFriend];
    }
    [[CDManagerVersionTwo sharedInstance] saveContext];
    
    for (ImaginaryFriend *imFriend in pfFriendsToDelete) {
        [[WebService sharedInstanse] deactivateChatRoomsForImaginaryFriend:imFriend completion:^(ResponseInfo *response) {
            if (response.success) {
                $l("---chatrooms for imaginaryFriend %@ was deactiwated successfully", imFriend.friendName);
            } else {
                $l(" --- error -> %@", [response.error localizedDescription]);
            }
        }];
    }
    [PFObject saveAllInBackground:pfFriendsToDelete block:^(BOOL succes, NSError *error) {
        if (error) {
            [Utilities showAlertWithParseError:error];
        }
    }];
    
    [[CDManagerVersionTwo sharedInstance] saveContext];

    completion();
}


#pragma mark - Delegated methods:

#pragma mark - —UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.imaginaryFriends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ImaginaryFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ImaginaryFriendCell"
                                                                forIndexPath:indexPath];
    CDImaginaryFriend *imFriend = self.imaginaryFriends[indexPath.row];
    cell.imaginaryFriend = imFriend;
    cell.settingsButtonDelegate = self;
    cell.delegate = self;
    cell.leftUtilityButtons = [self leftCellButtons];
    
    if (isEditing) {
        [cell showLeftUtilityButtonsAnimated:NO];
    }
    
    return cell;
}


//-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    return [[UIView alloc] initWithFrame:CGRectZero];
//}


#pragma mark - —UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatWithFriendViewController *chatVC = [[UIStoryboard chats] instantiateViewControllerWithIdentifier:@"ChatWithFriendViewController"];
    CDImaginaryFriend *imFriend = _imaginaryFriends[indexPath.row];
    NSSet *friendsSet = [NSSet setWithObject:imFriend];
    NSManagedObjectContext *context = [CDManagerVersionTwo sharedInstance].managedObjectContext;
    chatVC.chatRoom = [CDChatRoom chatRoomWithImaginaryFriends:friendsSet inContext:context];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:chatVC];
    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:navController animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}


#pragma mark - —ImaginaryFriendCellDelegate

- (void)settingsButtonTapped:(ImaginaryFriendCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    CDImaginaryFriend *imFriend = _imaginaryFriends[indexPath.row];
    ImaginarySettingsViewController *settingsVc = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"ImaginarySettingsViewController"];
    settingsVc.imaginaryFriend = imFriend;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVc];
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - —SWTableViewCellDelegate

- (void)swipeableTableViewCell:(ImaginaryFriendCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        
        return;
    }
    ImaginaryFriendCell *myCell = (ImaginaryFriendCell *)cell;
    cellToDelete = myCell;
    
    
    [UIAlertView showWithTitle:@""
                       message:@"Delete this friend?"
             cancelButtonTitle:@"Cancel"
             otherButtonTitles:@[@"Delete"]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex == 1) {
                              NSIndexPath *indexPath = [_tableView indexPathForCell:cellToDelete];
                              CDImaginaryFriend *cdImFriend = cellToDelete.imaginaryFriend;
                              [self deleteImaginaryFriends:@[cdImFriend] withCompletion:^{
                                  [_imaginaryFriends removeObject:cdImFriend];
                                  [self.tableView beginUpdates];
                                  [_tableView deleteRowsAtIndexPaths:@[indexPath]
                                                    withRowAnimation:UITableViewRowAnimationAutomatic];
                                  [self.tableView endUpdates];
                              }];
                          }
                      }];
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return NO;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state {
    return isEditing;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
    
}

#pragma mark - Private methods

- (NSArray*)leftCellButtons {
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    [leftUtilityButtons sw_addUtilityButtonWithColor:[UIColor clearColor]
                                                icon:[UIImage imageNamed:@"stg_delete_image"]];
    
    return leftUtilityButtons;
}

- (ImaginaryFriend *)getImaginaryFriendWithObjectId:(NSString *)objectId {
    ImaginaryFriend *imFriend = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"coreDataObjectId == %@", objectId];
    NSArray *filtredArray = [_parseImaginaryFriends filteredArrayUsingPredicate:predicate];
    imFriend = [filtredArray lastObject];
    
    return imFriend;
}

- (void)sortByNameImagynaryFrieds {
    NSSortDescriptor *sortDescr = [NSSortDescriptor sortDescriptorWithKey:@"friendName"
                                                                ascending:YES];
    [_imaginaryFriends sortUsingDescriptors:@[sortDescr]];
}

@end
