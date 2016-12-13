//
//  ErrorManager.m
//  IntelliNote
//
//  Created by Sergey Zalozniy on 6/19/14.
//  Copyright (c) 2014 Amit Bar-Shai. All rights reserved.
//

#import "AuthorizationManager.h"
#import "HTTPStatusCodes.h"
#import "UIAlertView+GRKAlertBlocks.h"

#import "ErrorManager.h"


@interface ErrorManager ()<UIAlertViewDelegate>

@property (nonatomic, weak) UIAlertView *currentAlert;
@property (nonatomic, assign) BOOL alertIsPresented;

@end


@implementation ErrorManager

#pragma mark - Allocators

+(instancetype) sharedInstance {
    static ErrorManager *errorManager = nil;
    
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        errorManager = [[ErrorManager alloc] init];
    });
    
    return errorManager;
}


#pragma mark - Static methods

+(void) showAlertWithError:(NSError *)error {
//	if (error.code == kStatusCodeInvalidToken) {
//		[[AuthorizationManager sharedInstance] signOutAnimated:YES];
//		return;
//	}
	if (error.code > 400 && error.code < 1000) {
		[self showAlertWithTitle:NSLocalizedString(@"Internal server error", nil)];
		return;
	}
	[self showAlertWithTitle:error.localizedDescription];
}

+(void) showAlertWithTitle:(NSString *)title {
    [self showAlertWithTitle:title
                     message:nil
                  complition:NULL];

}

+(void) showAlertWithTitle:(NSString *)title
                complition:(void(^)(void))complition {
    [self showAlertWithTitle:title
                     message:nil
                  complition:complition];
}


+(void) showAlertWithTitle:(NSString *)title
                   message:(NSString *)message {
    [self showAlertWithTitle:title
                     message:message
                  complition:NULL];
}


+(void) showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                complition:(void(^)(void))complition {
    [self showAlertWithTitle:title
                     message:message
                 buttonTitle:nil
                  complition:complition];
}


+(void) showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               buttonTitle:(NSString *)buttonTitle
                complition:(void(^)(void))complition {
    void (^showAlert)() = ^() {
        UIAlertView *alert = [UIAlertView alertWithTitle:title
                                                 message:message];
        NSString *_buttonTitle = buttonTitle;
        if (![_buttonTitle length]) {
            _buttonTitle = NSLocalizedString(@"Ok", nil);
        }
        [alert addButtonWithTitle:_buttonTitle handler:^(UIAlertView *alert) {
            if (complition) {
                complition();
            }
        }];
        [alert show];
    };
    
    if ([NSThread isMainThread]) {
        showAlert();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            showAlert();
        });
    }
}


+(void) showAlertWithStatusCode:(NSInteger)statusCode {
    NSString *statusCodeDescription = [[NSHTTPURLResponse localizedStringForStatusCode:statusCode] capitalizedString];
    [self showAlertWithTitle:statusCodeDescription];
}


+(void) proceedServerErrorWithStatusCode:(NSInteger)statusCode {
//    switch (statusCode) {
//        case kHTTPStatusCodeUnauthorized:
//            [[AuthorizationManager sharedInstance] deauthorize];
//            break;
//            
//        default:
//            break;
//    }
}

@end
