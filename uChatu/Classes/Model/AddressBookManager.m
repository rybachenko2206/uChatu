//
//  AddressBookManager.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/3/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "AddressBookUser.h"

#import "AddressBookManager.h"

@implementation AddressBookManager

#pragma mark - Static methods

+ (AddressBookManager *)sharedInstance {
    static AddressBookManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [AddressBookManager new];
        
    });
    
    return sharedManager;
}


#pragma mark - Interface methods

- (NSArray *)getAddressBookUsers {
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook,
                                                 ^(bool granted, CFErrorRef error) {
                                                     if (granted) {
                                                         
                                                     }
                                                 });
    }else if (status == kABAuthorizationStatusDenied) {
        [Utilities showAlertViewWithTitle:@"Cannot Find Contacts"
                                  message:@"Go to settings, uChatu and access to Contacts for you can find your friends to role-play"
                        cancelButtonTitle:@"OK"];
        return nil;
    }
    NSMutableArray *addrBookUsers =[NSMutableArray new];
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
    
    NSMutableArray *allEmails = [NSMutableArray array];
    NSMutableArray *allPhones = [NSMutableArray array];
    
    for (NSInteger i = 0; i < nPeople; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
        AddressBookUser *currentUser = [[AddressBookUser alloc] init];
        
        currentUser.firstName = (__bridge NSString *) ABRecordCopyValue(person, kABPersonFirstNameProperty);
        currentUser.lastName = (__bridge NSString *) ABRecordCopyValue(person, kABPersonLastNameProperty);
        currentUser.middleName = (__bridge NSString *) ABRecordCopyValue(person, kABPersonMiddleNameProperty);
        
        NSMutableArray *emailsTmp = [NSMutableArray array];
        ABMultiValueRef emials = ABRecordCopyValue(person, kABPersonEmailProperty);
        for(CFIndex i = 0; i < ABMultiValueGetCount(emials); i++) {
            NSString *email = (__bridge NSString *) ABMultiValueCopyValueAtIndex(emials, i);
            [emailsTmp addObject:email];
            [allEmails addObject:email];
        }
        
        NSMutableArray *phonesTmp = [NSMutableArray array];
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex j = 0; j < ABMultiValueGetCount(phones); j++) {
            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
            NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
            NSCharacterSet* phoneChars = [[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet];
            NSString *pureNumbers = [[phoneNumber componentsSeparatedByCharactersInSet:phoneChars] componentsJoinedByString:@""];
            [phonesTmp addObject:pureNumbers];
            [allPhones addObject:pureNumbers];
        }
        
        NSData *data = (__bridge NSData *) ABPersonCopyImageData(person);
        if (data) {
            currentUser.profileImage = [[UIImage alloc] initWithData:data];
        }
        
        if (!emailsTmp.count && !phonesTmp.count) {
            continue;
        }
        
        currentUser.emails = [NSArray arrayWithArray:emailsTmp];
        currentUser.phones = [NSArray arrayWithArray:phonesTmp];
        [addrBookUsers addObject:currentUser];
        
    }
    
    self.allEmails = allEmails;
    self.allPhoneNumbers = allPhones;
    self.addressBookUsers = addrBookUsers;
    
    return self.addressBookUsers;
}

- (NSString *)getRealNameForUserWithObjectId:(NSString *)objectId {
    NSString *realName = @"";
    
    NSPredicate *pfUserPredicate = [NSPredicate predicateWithFormat:@"objectId = %@", objectId];
    PFUser *user = [[self.pfUsers filteredArrayUsingPredicate:pfUserPredicate] lastObject];
     $l("------------------User: \nphone = %@, \n name = %@, \n email = %@", user.phoneNumber, user.userName, user.email);
    if (!user) {
        return @"";
    }
    
    realName = [self findRealNameByEmailForUser:user];
    if (realName.length) {
        return realName;
    }
    
    realName = [self findRealNameByPhoneNumberForUser:user];
    
    return realName;
}

- (NSString *)findRealNameByEmailForUser:(PFUser *)user {
    NSString *realName = @"";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"self.emails contains[cd] %@", user.email];
    AddressBookUser *addrBookUser = [[_addressBookUsers filteredArrayUsingPredicate:emailPredicate] lastObject];
    if (addrBookUser) {
        realName = [NSString stringWithFormat:@"%@ %@",addrBookUser.firstName, addrBookUser.lastName];
    } else {
        realName = @"";
    }
    return realName;
}


- (NSString *)findRealNameByPhoneNumberForUser:(PFUser *)user {
    NSString *realName = @"";//user.username;
    NSString *phoneNumber = user.phoneNumber;
    
    NSPredicate *phoneNumPredicate = [NSPredicate predicateWithFormat:@"self.phones contains[cd] %@", phoneNumber];
    AddressBookUser *addrBookUser = [[_addressBookUsers filteredArrayUsingPredicate:phoneNumPredicate] lastObject];
    
    if (addrBookUser) {
        realName = [NSString stringWithFormat:@"%@ %@",addrBookUser.firstName, addrBookUser.lastName];
        return realName;
    }
    
    for (AddressBookUser *addrBUser in _addressBookUsers) {
        for (NSString *phone in addrBUser.phones) {
            NSString *subStrPhone = nil;
            
            if (phone.length >= 9) {
                subStrPhone = [phone substringFromIndex:phone.length - 9];
                $l("---subStrPhone = %@", subStrPhone);
            } else {
                break;
            }
            NSRange range = [phoneNumber rangeOfString:subStrPhone];
            if (range.length > 0) {
                NSString *name = [NSString stringWithFormat:@"%@ %@",addrBUser.firstName, addrBUser.lastName];
                realName = name.length > 1 ? name : [NSString stringWithFormat:@"addr_user doesn't have name, phone %@", phone];
            }
        }
    }
    
    return realName;
}

@end
