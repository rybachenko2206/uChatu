//
//  ImaginaryFriendCollectionViewCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "UIImageView+WebCache.h"
#import "PrefixHeader.pch"

#import "ImaginaryFriendCollectionViewCell.h"


@implementation ImaginaryFriendCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _checkMarkImageView.hidden = YES;
    _avatarImageView.image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
    _nameLabel.text = @"";
}

- (void)setImaginaryFriend:(ImaginaryFriend *)imaginaryFriend {
    _imaginaryFriend = imaginaryFriend;
    
    [_avatarImageView sd_setImageWithURL:[NSURL URLWithString:_imaginaryFriend.avatar.url]
                        placeholderImage:[UIImage imageNamed:@"cht_emptyAvatar_image"]];
    _nameLabel.text = _imaginaryFriend.friendName;
}

+ (UIView *)getSelectedBackgroundViewWithFrame:(CGRect)frame {
    UIView *selectedBgView = [[UIView alloc] initWithFrame:frame];
    selectedBgView.backgroundColor = [UIColor colorWithRed:240/255.0
                                                     green:240/255.0
                                                      blue:240/255.0 alpha:1.0];
    selectedBgView.layer.cornerRadius = 10;
    selectedBgView.layer.masksToBounds = YES;
    selectedBgView.contentMode = UIViewContentModeScaleAspectFill;
    return selectedBgView;
}


-(void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    _checkMarkImageView.hidden = !selected;
}

#pragma mark - Private methods

@end
