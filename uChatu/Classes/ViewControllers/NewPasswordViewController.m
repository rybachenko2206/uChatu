//
//  NewPasswordViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/11/14.
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

#import "NewPasswordViewController.h"


@interface NewPasswordViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet JBTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet JBTextField *confirmPasswordTextField;
@property (weak, nonatomic) IBOutlet UILabel *invalidDataLabel;

- (IBAction)back:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;


@end


@implementation NewPasswordViewController

#pragma mark - Interface methods

-(void) viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    self.title = @"Password";
    
    _invalidDataLabel.hidden = YES;
    
    self.passwordTextField.delegate = self;
    self.passwordTextField.textFieldType = TextFieldTypePassword;
    self.confirmPasswordTextField.delegate = self;
    self.confirmPasswordTextField.textFieldType = TextFieldTypePassword;
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    if (![self verifyPassword]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    PFUser *currUser = [PFUser currentUser];
    
    currUser.password = self.passwordTextField.text;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] updateCurrentUserWithBlock:^(ResponseInfo *responseInfo){
        [SVProgressHUD dismiss];
        if (responseInfo.success) {
            [AuthorizationManager sharedInstance].currentUser = currUser;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"Password was changed"
                                                           delegate:weakSelf
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        } else {
            [Utilities showAlertViewWithTitle:@""
                                      message:[NSString stringWithFormat:@"Error!\n%@",[responseInfo.error localizedFailureReason]]
                            cancelButtonTitle:@"OK"];
        }
        
    }];
}

-(IBAction) cancel:(id)sender {
    [self back:nil];
}


#pragma mark - Delegated methods - UITextFieldDelegate

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    _invalidDataLabel.hidden = YES;
    [_passwordTextField setBackgroundNormal];
    [_confirmPasswordTextField setBackgroundNormal];
    
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField.tag == 0) {
        [textField resignFirstResponder];
        [_confirmPasswordTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
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

-(BOOL) verifyPassword {
    if (![_passwordTextField isValidPassword]) {
        [_passwordTextField setBackgroundError];
        return NO;
    }
    
    if (![_passwordTextField.text isEqualToString:_confirmPasswordTextField.text]) {
        [self showInvalidDataLabelWithMessage:alertPasswordDoNotMatch];
        [_passwordTextField setBackgroundError];
        [_confirmPasswordTextField setBackgroundError];
        return NO;
    }
    
    return YES;
}


@end
