//
//  OnlyYouAnswerCell.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/9/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//



#define TEXT_MAX_WIDTH 230.0f
#define TEXT_FONT [UIFont fontWithName:@"HelveticaNeue" size:17.0f]
#define TOP_PADDING 17.0f


#import "NSString+Calculation.h"
#import "SharedDateFormatter.h"
#import "CDMessage.h"

#import "OnlyYouAnswerCell.h"

@implementation OnlyYouAnswerCell

- (void)awakeFromNib {
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


#pragma mark - Interface methods

-(void) setContentWithCDMessage:(CDMessage*)cdMessage {
    self.messageLabel.text = cdMessage.message;
    self.createdAtLabel.text = [SharedDateFormatter stringCreatedAtFromDate:cdMessage.createdAt];
}

+(CGFloat) heightForCellWithMessage:(NSString *)message {
    CGFloat cellHeight = [self sizeForText:message].height;
    cellHeight += TOP_PADDING;
    
    return cellHeight;
}


#pragma mark - Private methods

+(CGSize) sizeForText:(NSString *)text {
    CGSize size = [text usedSizeForMaxWidth:TEXT_MAX_WIDTH withFont:TEXT_FONT];
    size.height += 20.0f;
    
    return size;
}

@end
