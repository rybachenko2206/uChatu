//
//  PFUser+Additions.m
//  planvy
//
//  Created by Igor Karpenko on 11/7/13.
//  Copyright (c) 2013 Mozi Development. All rights reserved.
//

#import "ImaginaryFriend.h"
#import "PFUser+Additions.h"
#import <MD5Digest/NSString+MD5.h>


NSString *const kPhotoKey = @"photo";
NSString *const kUserNameKey = @"userName";
NSString *const phoneNumberKey = @"phone";
NSString *const countryCodeKey = @"countryCode";
NSString *const kAvatarImageName = @"avatarImageName";
NSString *const kAccessToAddressBook = @"accessToAddressBook";
NSString *const kIsOnlineKey = @"isOnline";
NSString *const kIsUpdatedToVersionTwo = @"isUpdatedToVersionTwo";
NSString *const kShortPhoneNumberKey = @"shortPhoneNumber";



@implementation PFUser (Additions)


#pragma mark - shortPhoneNumber

- (NSString *)shortPhoneNumber {
    return self[kShortPhoneNumberKey];
}

- (void)setShortPhoneNumber:(NSString *)shortPhoneNumber {
    self[kShortPhoneNumberKey] = shortPhoneNumber;
}


#pragma mark - isOnline

- (NSNumber *)isOnline {
    return self[kIsOnlineKey];
}

- (void)setIsOnline:(NSNumber *)isOnline {
    self[kIsOnlineKey] = isOnline;
}


#pragma mark - isUpdatedToVersionTwo

- (NSNumber *)isUpdatedToVersionTwo {
    return self[kIsUpdatedToVersionTwo];
}

- (void)setIsUpdatedToVersionTwo:(NSNumber *)isUpdatedToVersionTwo {
    self[kIsUpdatedToVersionTwo] = isUpdatedToVersionTwo;
}


#pragma mark - countryCode

- (NSString *)countryCode {
    return self[countryCodeKey];
}

- (void)setCountryCode:(NSString *)countryCode {
    self[countryCodeKey] = countryCode;
}


#pragma mark - accessToAddressBook

- (NSString *)accessToAddressBook {
    return self[kAccessToAddressBook];
}

- (void)setAccessToAddressBook:(NSNumber *)accessToAddressBook {
    self[kAccessToAddressBook] = accessToAddressBook;
}

#pragma mark - userName

- (NSString *)userName {
	return self[kUserNameKey];
}

- (void)setUserName:(NSString *)userName {
    self[kUserNameKey] = userName;
}


#pragma mark - avatarImageName

- (NSString *)avatarImageName {
    return self[kAvatarImageName];
}

- (void)setAvatarImageName:(NSString *)avatarImageName {
    self[kAvatarImageName] = avatarImageName;
}

#pragma mark - photo

- (PFFile *)photo {
	return self[kPhotoKey];
}


- (void)setPhoto:(PFFile *)photo {
	self[kPhotoKey] = photo;
}


#pragma mark - Phone number

- (NSString *)phoneNumber {
	return self[phoneNumberKey];
}

- (void)setPhoneNumber:(NSString *)phoneNumber {
	self[phoneNumberKey] = phoneNumber;
}


-(NSString *)xmppPassword {
    return [self.email MD5Digest];
}

@end
