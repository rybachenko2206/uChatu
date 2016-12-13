//
//  UICollectionView+CenteredLayout.h
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/6/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionView (CenteredLayout)

-(void)centrateLayout;
-(void)centrateSelectedCell:(UICollectionViewCell *)cell;

@end
