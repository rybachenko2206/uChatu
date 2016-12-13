//
//  AttachedImageView.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/5/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "AttachedImageView.h"

@implementation AttachedImageView

-(void)awakeFromNib {
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
    self.contentMode = UIViewContentModeCenter;
}

@end
