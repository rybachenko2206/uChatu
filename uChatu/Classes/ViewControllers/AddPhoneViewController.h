//
//  AddPhoneViewController.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/21/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, UCPresentationType) {
    UCPresentationTypeSignUp    = 0,
    UCPresentationTypeSettings  = 1
};

@interface AddPhoneViewController : UIViewController

@property (assign, nonatomic) UCPresentationType presentationType;

@end
