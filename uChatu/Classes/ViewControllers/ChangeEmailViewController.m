//
//  ChangeEmailViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/18/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>
#import "PrefixHeader.pch"
#import "JBTextField.h"
#import "WebService.h"
#import "ResponseInfo.h"
#import "Utilities.h"
#import "MBProgressHUD.h"
#import "AuthorizationManager.h"
#import "ReachabilityManager.h"
#import "CDUser.h"
#import "CDManagerVersionTwo.h"
#import "SVProgressHUD.h"

#import "ChangeEmailViewController.h"

@interface ChangeEmailViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet JBTextField *emailTextField;
@property (weak, nonatomic) IBOutlet UILabel *invalidDataLabel;

- (IBAction)back:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;


@end

@implementation ChangeEmailViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    self.title = @"Email";
    
    _invalidDataLabel.hidden = YES;
    
    self.emailTextField.delegate = self;
    self.emailTextField.textFieldType = TextFieldTypeEmail;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}


#pragma mark - Action methods

-(IBAction) back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction) save:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
//        [Utilities showAlertViewWithTitle:@""
//                                  message:internetConnectionFailedMSG
//                        cancelButtonTitle:@"OK"];
        return;
    }
    
    PFUser *currentUser = [PFUser currentUser];
    if (![self checkEmailVaild]) {
        [_emailTextField setBackgroundError];
        [Utilities showAlertViewWithTitle:@"" message:@"Error!\nEmail is incorrect" cancelButtonTitle:@"OK"];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] isExistUserWithEmail:_emailTextField.text completion:^(ResponseInfo *responseInfo) {
        [SVProgressHUD dismiss];
        if (responseInfo.objects.count) {
            
            [Utilities showAlertViewWithTitle:@""
                                      message:@"Rejected.\nUser with this email already registered"
                            cancelButtonTitle:@"OK"];
            [_emailTextField setBackgroundError];
        } else {
            currentUser.email = [_emailTextField.text lowercaseString];
            currentUser.username = [_emailTextField.text lowercaseString];
            
            CDUser *currUser = [AuthorizationManager sharedInstance].currentCDUser;
            currUser.email = currentUser.email;
            [[CDManagerVersionTwo sharedInstance] saveContext];
        
            [[WebService sharedInstanse] updateCurrentUserWithBlock:^(ResponseInfo *responce) {
                [SVProgressHUD dismiss];
                [AuthorizationManager sharedInstance].currentUser = currentUser;
                
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"Email was changed"
                                                               delegate:weakSelf
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
                [alert show];
            }];
            
        }
    }];
}

- (IBAction)cancel:(id)sender {
    [self back:nil];
}


#pragma mark - Delegated methods - UITextFieldDelegate

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    _invalidDataLabel.hidden = YES;
    [_emailTextField setBackgroundNormal];
    
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - Delegated methods - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSTimeInterval delay = 0.4;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }
}


#pragma mark - Private methods

-(void) showInvalidDataLabelWithMessage:(NSString *)message {
    _invalidDataLabel.hidden = NO;
    _invalidDataLabel.text = message;
}

-(BOOL) checkEmailVaild {
    if ([Utilities isEmailValid:_emailTextField.text]) {
        return YES;
    }
    
    return NO;
}

@end
