//
// Created by Vitalii Krayovyi on 5/27/14.
// Copyright (c) 2014 Mozi Development. All rights reserved.
//

#import "RoundedImageView.h"


@implementation RoundedImageView {

}

-(void)awakeFromNib {
    [super awakeFromNib];
    
    self.layer.cornerRadius = self.frame.size.height / 2;
    self.layer.masksToBounds = YES;
    self.contentMode = UIViewContentModeScaleAspectFill;
}

@end
