//
//  SelectCCodeViewController.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/21/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

@class SelectCCodeViewController;

#import <UIKit/UIKit.h>

@protocol SelectCCodeViewControllerDelegate <NSObject>

- (void)countrySelected:(NSDictionary *)country;

@end

@interface SelectCCodeViewController : UIViewController

@property (weak) id <SelectCCodeViewControllerDelegate> delegate;

@end
