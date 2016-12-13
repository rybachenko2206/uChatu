//
//  PFInstallation+Additions.h
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/13/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>

@interface PFInstallation (Additions)

@property (strong, nonatomic) PFUser *currentUser;

@end
