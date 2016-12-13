//
//  UCFooterSeparator.h
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/3/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UCFooterViewDelegate <NSObject>

@optional
-(void)didTapInviteButton;

@end

@interface UCFooterView : UIView

+(CGFloat)footerHeight;

@property (weak, nonatomic) id <UCFooterViewDelegate> delegate;

@end
