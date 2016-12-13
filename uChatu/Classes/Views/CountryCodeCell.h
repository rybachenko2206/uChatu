//
//  CountryCodeCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/21/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CountryCodeCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *countryNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageView;

@property (nonatomic, strong) NSDictionary *country;

- (void)setSelected:(BOOL)selected;

@end
