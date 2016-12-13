//
//  PFInstallation+Additions.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/13/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "PFInstallation+Additions.h"

NSString * const kCurrentUser = @"kCurrentUser";

@implementation PFInstallation (Additions)

-(void)setCurrentUser:(PFUser *)currentUser {
    self[kCurrentUser] = currentUser;
}


-(PFUser *)currentUser {
    return self[kCurrentUser];
}

@end
