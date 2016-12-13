//
//  ImagenarySettingsViewController.h
//  uChatu
//
//  Created by Roman Rybachenko on 11/19/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


@class CDImaginaryFriend;
@class ImaginaryFriend;

#import <UIKit/UIKit.h>

@interface ImaginarySettingsViewController : UIViewController

@property (nonatomic, strong) CDImaginaryFriend *imaginaryFriend;
@property (nonatomic, strong) ImaginaryFriend *parseImaginaryFriend;

@end
