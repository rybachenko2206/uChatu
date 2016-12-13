//
//  ChatRoomsDataSource.h
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/12/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "ChatsListViewController.h"
@import Foundation;
@import UIKit;


@interface ChatRoomsDataSource : NSObject <UITableViewDataSource>

@property (strong, nonatomic) ChatsListViewController *viewController;
@property (strong, nonatomic) NSMutableArray *chatRooms;
@property (strong, nonatomic) NSMutableArray *cdChatRooms;
@property (strong, nonatomic) NSDictionary *onlineStatuses;

- (void)deleteCDChatRoom:(CDChatRoom *)cdChatRoom;

@end
