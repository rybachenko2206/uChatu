//
//  UICollectionView+CenteredLayout.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/6/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "UICollectionView+CenteredLayout.h"

@implementation UICollectionView (CenteredLayout)

-(void)centrateLayout {
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    CGFloat cellWidth = layout.itemSize.width;
    NSUInteger count = [self.dataSource collectionView:self numberOfItemsInSection:0];
    
    CGFloat sideInset = (CGRectGetWidth(self.frame) - count * cellWidth) / 2;
    self.contentInset = sideInset > 0 ? UIEdgeInsetsMake(0, sideInset, 0, sideInset) : UIEdgeInsetsZero;
}

-(void)centrateSelectedCell:(UICollectionViewCell *)cell {
    CGFloat collectionViewWidth = CGRectGetWidth(self.frame);
    CGPoint offset = CGPointMake(cell.center.x - collectionViewWidth / 2,  0);
    [self setContentOffset:offset animated:YES];
}

@end
