//
//  ImaginaryFriendsDataSource.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/5/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "ImaginaryFriendsDataSource.h"


@implementation ImaginaryFriendsDataSource


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ImaginaryFriendCollectionViewCell";
    ImaginaryFriendCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                                        forIndexPath:indexPath];
    
    cell.imaginaryFriend = self.imaginaryFriends[indexPath.row];
    
    return cell;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _imaginaryFriends.count;
}


@end
