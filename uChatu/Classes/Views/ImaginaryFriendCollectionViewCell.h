//
//  ImaginaryFriendCollectionViewCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImaginaryFriend.h"

@interface ImaginaryFriendCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (nonatomic, strong) ImaginaryFriend *imaginaryFriend;
@property (weak, nonatomic) IBOutlet UIImageView *checkMarkImageView;

+ (UIView *)getSelectedBackgroundViewWithFrame:(CGRect)frame;

@end
