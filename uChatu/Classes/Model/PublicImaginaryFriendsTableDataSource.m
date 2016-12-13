//
//  PublicImaginaryFriendsTableDataSource.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/5/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "ImaginaryFriend.h"
#import "AuthorizationManager.h"

#import "PublicImaginaryFriendsTableDataSource.h"


@implementation PublicImaginaryFriendsTableDataSource 

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _imaginaryFriends.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"RealFriendsCell";
    RealFriendsCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                            forIndexPath:indexPath];
    cell.imaginaryFriend = _imaginaryFriends[indexPath.row];
    cell.delegate = self.cellDelegate;
    cell.shouldHideUserName = self.mode == UCDataSourceModeAllUsers;
    
    
    if ([cell.imaginaryFriend isBlockedByUser:[AuthorizationManager sharedInstance].currentUser]) {
        cell.isOnline = @(ChatOnlineStatusBlocked);
    } else {
        cell.isOnline = self.onlineStatuses[cell.imaginaryFriend.attachedToUser.objectId];
    }
    
    
    
    return cell;
}


@end
