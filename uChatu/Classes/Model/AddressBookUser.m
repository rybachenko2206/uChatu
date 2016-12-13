//
//  AddressBookUser.m
//  planvy
//
//  Created by Igor Karpenko on 10/22/13.
//  Copyright (c) 2013 Mozi Development. All rights reserved.
//

#import "AddressBookUser.h"

@implementation AddressBookUser

-(NSString *) firstName {
	return _firstName ? _firstName : @"";
}


-(NSString *) lastName {
	return _lastName ? _lastName : @"";
}

@end
