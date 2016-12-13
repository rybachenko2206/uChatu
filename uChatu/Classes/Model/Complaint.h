//
//  Complaint.h
//  uChatu
//
//  Created by Roman Rybachenko on 7/24/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>
#import "ImaginaryFriend.h"
#import "AvatarPhoto.h"

@interface Complaint : PFObject <PFSubclassing>

@property (strong) NSString *complaintText;
@property (strong) ImaginaryFriend *inappropriateObject;
@property (strong) PFUser *reporter;
@property (strong) AvatarPhoto *photo;

+ (NSString *)parseClassName;

@end
