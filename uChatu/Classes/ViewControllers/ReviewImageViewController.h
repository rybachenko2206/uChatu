//
//  ReviewImageViewController.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/6/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AvatarPhoto.h"
#import "ImaginaryFriend.h"

@interface ReviewImageViewController : UIViewController

@property (nonatomic, strong) UIImage *imageForReview;
@property (nonatomic, strong) AvatarPhoto *avatarPhoto;
@property (nonatomic, strong) ImaginaryFriend *imFriend;

@end
