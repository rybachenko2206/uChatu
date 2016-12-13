//
//  XMPPChatDataSource.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/12/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


//cells
#import "OnlyYouMessageCell.h"
#import "FriendMessageCell.h"

#import "ImaginaryFriend.h"
#import "AuthorizationManager.h"
#import "UChatuMessage.h"

#import "XMPPChatDataSource.h"


@implementation XMPPChatDataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *onlyYouCellIdentifier = @"OnlyYouMessageCell";
    static NSString *friendMessageCellIdentifier = @"FriendMessageCell";
    
    UChatuMessage *message = self.messages[indexPath.row];
    
    if (!message) {
        [Utilities showAlertViewWithTitle:@"Error. State from XMPPChatDataSource"
                                  message:@"Message = nil"
                        cancelButtonTitle:@"Cancel"];
    }
    
    ImaginaryFriend *imFriend = message.ownerImaginaryFriend;
    NSString *userObjectId = imFriend.attachedToUser.objectId;
    if ([userObjectId isEqualToString:[AuthorizationManager sharedInstance].currentUser.objectId]) {
       OnlyYouMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:onlyYouCellIdentifier
                                                                     forIndexPath:indexPath];
        cell.uchatuMessage = message;
        return cell;
    } else {
        FriendMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:friendMessageCellIdentifier
                                                                  forIndexPath:indexPath];
        cell.uchatuMessage = message;
        cell.isOnline = _isCompanionOnline;
        return cell;
    }
    
    return nil;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _messages.count;
}

@end
