//
//  PFUser+Additions.h
//  planvy
//
//  Created by Igor Karpenko on 11/7/13.
//  Copyright (c) 2013 Mozi Development. All rights reserved.
//

#import <Parse/Parse.h>

@interface PFUser (Additions)

@property (strong) NSString *userName;
@property (strong) NSString *countryCode;
@property (strong) NSString *phoneNumber;
@property (strong) NSString *shortPhoneNumber;
@property (strong) NSString *avatarImageName;
@property (strong) NSNumber *accessToAddressBook;
@property (strong) NSNumber *isOnline;
@property (strong) NSNumber *isUpdatedToVersionTwo;
@property (strong) PFFile   *photo;

- (NSString *)xmppPassword;

@end
