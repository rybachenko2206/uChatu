//
//  AddressBookManager.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/3/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AddressBookUser;

@interface AddressBookManager : NSObject

@property (nonatomic, strong) NSArray *allEmails;
@property (nonatomic, strong) NSArray *allPhoneNumbers;
@property (nonatomic, strong) NSArray *addressBookUsers;
@property (nonatomic, strong) NSArray *pfUsers;


+ (AddressBookManager *)sharedInstance;
- (NSArray *)getAddressBookUsers;
- (NSString *)getRealNameForUserWithObjectId:(NSString *)objectId;


@end
