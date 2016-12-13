//
//  RealFriendFooterCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "RealFriendFooterCell.h"

@implementation RealFriendFooterCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


#pragma mark - Action methods
- (IBAction)inviteButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(inviteButtonWasPressed)]) {
        [self.delegate inviteButtonWasPressed];
    }
}


#pragma mark - Static methods

+ (CGFloat)heightForCell {
    return 82.0f;
}

@end
