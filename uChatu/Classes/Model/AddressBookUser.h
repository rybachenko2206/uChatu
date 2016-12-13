//
//  AddressBookUser.h
//  planvy
//
//  Created by Igor Karpenko on 10/22/13.
//  Copyright (c) 2013 Mozi Development. All rights reserved.
//

#import "PrefixHeader.pch"
@class PFUser;

@interface AddressBookUser : NSObject

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *middleName;
@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) NSArray *emails;
@property (nonatomic, strong) NSArray *phones;

@property (strong, nonatomic) PFUser *uChatuUser;

@end
