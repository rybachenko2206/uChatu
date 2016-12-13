//
//  NotificationButton.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/11/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import "NotificationButton.h"

@implementation NotificationButton

#pragma mark - Instance initialization

-(instancetype) init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self = [UIButton buttonWithType:UIButtonTypeCustom];
    self.titleEdgeInsets = UIEdgeInsetsMake(0.5, 0.5, 0, 0);
    self.userInteractionEnabled = NO;
    
    return self;
}


#pragma mark - Interface methods

-(void) setNotificationCount:(NSInteger)count {
    self.hidden = count == 0 ? YES : NO;
    [self setTitle:[NSString stringWithFormat:@"%ld", (long)count]
          forState:UIControlStateNormal];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
