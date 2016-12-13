//
//  ChatTitleView.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatTitleView : UIView

- (instancetype)initWithTitle:(NSString *)title isOnline:(BOOL)isOnline isBlocked:(BOOL)isBlocked;

@end
