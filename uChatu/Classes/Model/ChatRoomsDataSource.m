//
//  ChatRoomsDataSource.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/12/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "ChatRoom.h"
#import "ImaginaryFriend.h"
#import "ChatsTableViewCell.h"
#import "PrefixHeader.pch"
#import "AuthorizationManager.h"
#import "CDChatRoom.h"
#import "CDMessage.h"
#import "ReachabilityManager.h"
#import "WebService.h"
#import "UIAlertView+Blocks.h"

#import "ChatRoomsDataSource.h"


@interface ChatRoomsDataSource () <SWTableViewCellDelegate>

@end


@implementation ChatRoomsDataSource

- (void)setViewController:(ChatsListViewController *)viewController {
    _viewController = viewController;
}

#pragma mark - Delegated methods:
#pragma mark - —UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? _chatRooms.count : _cdChatRooms.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatsTableViewCell *cell = (ChatsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ChatsTableViewCell"
                                                                                     forIndexPath:indexPath];
    cell.delegate = self;
    cell.leftUtilityButtons = [self leftCellButtons];
    
    if (indexPath.section == 0) {
        ChatRoom *chat = _chatRooms[indexPath.row];
        cell.chatRoom = chat;
        if ([cell.chatRoom.companionImFriend isBlockedByUser:[AuthorizationManager sharedInstance].currentUser] ||
            [[cell.chatRoom yourImaginaryFriend] isBlockedByUser:cell.chatRoom.companionImFriend.attachedToUser]) {
            
            cell.isOnline = @(ChatOnlineStatusBlocked);
        } else {
            cell.isOnline = self.onlineStatuses[cell.chatRoom.companionImFriend.attachedToUser.objectId];
        }
        cell.unreadMessagesCount = [self getUnreadMessagesForChatRoom:chat];
        if (!chat.participantsImaginaryFriends.count || !chat.participantsImaginaryFriends) {
            //
        }
    } else if (indexPath.section == 1) {
        CDChatRoom *cdChatRoom = _cdChatRooms[indexPath.row];
        cell.unreadMessagesCount = @(0);
        cell.cdImaginaryFriend = [cdChatRoom.imaginaryFriends anyObject];
    }
    
    if (self.viewController.isEditing) {
        [cell showLeftUtilityButtonsAnimated:NO];
    }
    
    return cell;
}



#pragma mark - Private methods

- (NSNumber *)getUnreadMessagesForChatRoom:(ChatRoom *)room {
    NSNumber *count = nil;
    if ([room.companionImFriend.objectId isEqualToString:room.receiverImaginaryFriendID]) {
        count = room.unreadMessagesCountInitiator;
    } else {
        count = room.unreadMessagesCountReceiver;
    }
    
    return count;
}

- (NSArray*)leftCellButtons {
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    [leftUtilityButtons sw_addUtilityButtonWithColor:[UIColor clearColor]
                                                icon:[UIImage imageNamed:@"stg_delete_image"]];
    
    return leftUtilityButtons;
}

- (void)deleteCDChatRoom:(CDChatRoom *)cdChatRoom {
    NSManagedObjectContext *context = [CDManagerVersionTwo sharedInstance].managedObjectContext;
    
    NSArray *messages =[cdChatRoom.messages allObjects];
    for (CDMessage *msg in messages) {
        [context deleteObject:msg];
    }
    [context deleteObject:cdChatRoom];
    [[CDManagerVersionTwo sharedInstance] saveContext];
}


#pragma mark - —SWTableViewCellDelegate

- (void)swipeableTableViewCell:(ChatsTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    
    if (![[ReachabilityManager sharedInstance] isReachable]) {
//        [Utilities showAlertViewWithTitle:@""
//                                  message:internetConnectionFailedMSG
//                        cancelButtonTitle:@"OK"];
        return;
    }
    
    [UIAlertView showWithTitle:@""
                       message:@"Delete this room?"
             cancelButtonTitle:@"Cancel"
             otherButtonTitles:@[@"Delete"]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex == 1) {
                              ChatsTableViewCell *myCell = (ChatsTableViewCell *)cell;
                              NSIndexPath *indexPath = [self.viewController.tableView indexPathForCell:myCell];
                              
                              if (indexPath.section == 0) {
                                  ChatRoom *chatRoom = _chatRooms[indexPath.row];
                                  [self.chatRooms removeObjectAtIndex:indexPath.row];
                                  [chatRoom deleteChatRoom];
                              } else if (indexPath.section == 1) {
                                  CDChatRoom *cdChatRoom = _cdChatRooms[indexPath.row];
                                  [self.cdChatRooms removeObjectAtIndex:indexPath.row];
                                  [self deleteCDChatRoom:cdChatRoom];
                              }
                              
                              [self.viewController.tableView deleteRowsAtIndexPaths:@[indexPath]
                                                                   withRowAnimation:UITableViewRowAnimationMiddle];
                          }
                      }];
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return NO;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state {
    BOOL isSwipeable = self.viewController.isEditing;
    return isSwipeable;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
    
}


@end
