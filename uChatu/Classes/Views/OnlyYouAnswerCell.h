//
//  OnlyYouAnswerCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/9/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


@class CDMessage;

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface OnlyYouAnswerCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdAtLabel;


+(CGFloat) heightForCellWithMessage:(NSString *)message;

-(void) setContentWithCDMessage:(CDMessage*)cdMessage;


@end
