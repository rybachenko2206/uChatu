//
//  PublicImaginaryFriendsTableDataSource.h
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/5/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

@import UIKit;
@import Foundation;

#import "RealFriendsCell.h"

typedef NS_ENUM(NSUInteger, UCDataSourceMode) {
    UCDataSourceModeRealFriends = 0,
    UCDataSourceModeAllUsers    = 1
};

@interface PublicImaginaryFriendsTableDataSource : NSObject <UITableViewDataSource>

@property (assign, nonatomic) UCDataSourceMode mode;

@property (strong, nonatomic) NSArray *imaginaryFriends;
@property (strong, nonatomic) NSDictionary *onlineStatuses;
@property (weak, nonatomic) id <RealFriendsCellDelegate> cellDelegate;

@end
