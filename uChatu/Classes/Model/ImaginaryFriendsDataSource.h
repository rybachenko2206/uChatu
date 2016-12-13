//
//  ImaginaryFriendsDataSource.h
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/5/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

@import UIKit;
@import Foundation;

#import "ImaginaryFriendCollectionViewCell.h"

@interface ImaginaryFriendsDataSource : NSObject <UICollectionViewDataSource>

@property (strong, nonatomic) NSArray *imaginaryFriends;

@end
