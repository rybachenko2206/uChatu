//
//  CountryCodeCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/21/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import "PrefixHeader.pch"

#import "CountryCodeCell.h"

@implementation CountryCodeCell

#pragma mark - Interface methods

- (void)awakeFromNib {
    self.checkmarkImageView.hidden = YES;
}

- (void)setSelected:(BOOL)selected {
    if (selected) {
        self.checkmarkImageView.hidden = NO;
        self.countryNameLabel.textColor = [UIColor colorWithRed:2/255.0
                                                          green:138/255.0
                                                           blue:253/255.0
                                                           alpha:1.0];
    } else {
        self.countryNameLabel.textColor = [UIColor blackColor];
        self.checkmarkImageView.hidden = YES;
    }
}


#pragma mark - Setter methods

- (void)setCountry:(NSDictionary *)country {
    _country = country;
    
    self.countryNameLabel.text = _country[kCountryName];
}


@end
