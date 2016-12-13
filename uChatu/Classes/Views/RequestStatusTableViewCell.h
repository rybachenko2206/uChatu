//
//  RequestStatusTableViewCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/20/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RequestStatusTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *statusTextLabel;

+ (CGFloat)heightForCell;

@end
