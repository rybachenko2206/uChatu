//
//  RequestStatusTableViewCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/20/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "RequestStatusTableViewCell.h"

@implementation RequestStatusTableViewCell

- (void)awakeFromNib {

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Static methods

+ (CGFloat)heightForCell {
    return 37.0f;
}

@end
