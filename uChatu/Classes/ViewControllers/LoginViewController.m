//
//  LoginViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 11/26/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>
#import "WebService.h"
#import "ResponseInfo.h"
#import "SignUpViewController.h"
#import "FindAccountViewController.h"
#import "ChatsListViewController.h"
#import "PrefixHeader.pch"
#import "Utilities.h"
#import "MBProgressHUD.h"
#import "AuthorizationManager.h"
#import "JBTextField.h"
#import "ReachabilityManager.h"
#import "SVProgressHUD.h"
#import "XMPPService.h"
#import "PFInstallation+Additions.h"
#import "SynchronizeDbManager.h"

#import "LoginViewController.h"


@interface LoginViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *invalidDataLabel;
@property (weak, nonatomic) IBOutlet JBTextField *emailTextFiled;
@property (weak, nonatomic) IBOutlet JBTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraintEmailTFOutlet;

-(IBAction) forgotPassword:(id)sender;
-(IBAction) login:(id)sender;
-(IBAction) signUp:(id)sender;

@end

@implementation LoginViewController

#pragma mark - Interface methods

-(void) viewDidLoad {
    [super viewDidLoad];

    [self updateConstraintsOutletIfNeeded];
    
    self.emailTextFiled.delegate = self;
    self.emailTextFiled.textFieldType = TextFieldTypeEmail;
    self.passwordTextField.delegate = self;
    self.passwordTextField.textFieldType = TextFieldTypePassword;
    
    [self hideInvalidDataLabel];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString * lastEmail = [Lockbox stringForKey:lastSuccessLoggedEmailKey];
    if (lastEmail) {
        _emailTextFiled.text = lastEmail;
    }
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}


#pragma mark - Action methods

-(IBAction) forgotPassword:(id)sender {
    [self hideInvalidDataLabel];
    FindAccountViewController *findAccVC = [[UIStoryboard authentication] instantiateViewControllerWithIdentifier:@"FindAccountViewController"];
    if ([Utilities isEmailValid:_emailTextFiled.text]) {
        findAccVC.email = _emailTextFiled.text;
    }
    [self.navigationController pushViewController:findAccVC
                                         animated:YES];
}

-(IBAction) login:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    [self hideInvalidDataLabel];
    if (![self verifyInputData]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    [[WebService sharedInstanse] logInWithEmail:[_emailTextFiled.text lowercaseString]
                                        password:_passwordTextField.text
                                      completion:^(ResponseInfo *responseInfo) {
                                          if (responseInfo.success) {
                                              [Lockbox setString:responseInfo.user.email
                                                          forKey:lastSuccessLoggedEmailKey];
                                              PFUser *currUser = [PFUser currentUser];
                                              if (![currUser.isUpdatedToVersionTwo boolValue]) {
                                                  [[SynchronizeDbManager sharedInstance] transferDataFromOldToNewDatabaseWithComletion:^(BOOL success, NSError *error) {
                                                      currUser.isUpdatedToVersionTwo = @(YES);
                                                      currUser.isOnline = @(YES);
                                                      [currUser saveInBackground];
                                                      [AuthorizationManager sharedInstance].currentUser = currUser;
                                                      [AuthorizationManager sharedInstance].currentCDUser = [CDUser userWithEmail:currUser.email
                                                                                                                           userId:currUser.objectId
                                                                                                                        inContext:[CDManagerVersionTwo sharedInstance].managedObjectContext];
                                                  }];
                                              }
                                              [AuthorizationManager sharedInstance].currentUser = currUser;
                                              [[AuthorizationManager sharedInstance] setCurrentUserOnline:YES];
                                              
                                              [[XMPPService sharedInstance] signIn];
                                              [[WebService sharedInstanse] savePFInstallationForUser:currUser completion:^(ResponseInfo *response) {
                                                  [SVProgressHUD dismiss];
                                                  [weakSelf dismissViewControllerAnimated:YES
                                                                               completion:NULL];
                                              }];
                                          }
                                          else {
                                              [SVProgressHUD dismiss];
                                              if ([responseInfo.error code] == kPFErrorConnectionFailed) {
                                                  [Utilities showAlertViewWithTitle:@""
                                                                            message:internetConnectionFailedMSG
                                                                  cancelButtonTitle:@"Cancel"];
                                              } else if (responseInfo.objects.count) {
                                                  [self showInvalidDataLabelWithWrongMessage:NO
                                                                               wrongPassword:YES];
                                              } else {
                                                  [self showInvalidDataLabelWithWrongMessage:YES
                                                                               wrongPassword:NO];
                                              }
                                          }
                                      }];
}

-(IBAction) signUp:(id)sender {
    [self hideInvalidDataLabel];
    
    SignUpViewController *signUpVC = [[UIStoryboard authentication] instantiateViewControllerWithIdentifier:@"SignUpViewController"];
    if ([Utilities isEmailValid:_emailTextFiled.text]) {
        signUpVC.email = _emailTextFiled.text;
    }
    [self.navigationController pushViewController:signUpVC animated:YES];
}



#pragma mark - Delegated methods:

#pragma mark —UITextFieldDelegate

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    [self hideInvalidDataLabel];
    if (textField.tag == 0) {
        [_emailTextFiled setBackgroundNormal];
    }
    if (textField.tag == 1) {
        [_passwordTextField setBackgroundNormal];
    }
    
    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    if (textField.tag == 0) {
        [_passwordTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    
    return YES;
}

#pragma mark —UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    __weak typeof(self) weakSelf = self;
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [AuthorizationManager sharedInstance].currentUser.accessToAddressBook = @(YES);
            [[WebService sharedInstanse] updateCurrentUserWithBlock:^(ResponseInfo *response) {
                if (response.success) {
                    CDUser *currCDUser = [AuthorizationManager sharedInstance].currentCDUser;
                    currCDUser.accessToAddressBook = @(YES);
                    [[CDManagerVersionTwo sharedInstance] saveContext];
                }
            }];
            [weakSelf dismissViewControllerAnimated:YES
                                         completion:NULL];
        }
    }
}


#pragma mark - Private methods

-(BOOL) verifyInputData {
    if (![self verifyEmail] || ![self verifyPassword]) {
        
        [self showInvalidDataLabelWithWrongMessage:![self verifyEmail]
                                wrongPassword:![self verifyPassword]];
        return NO;
    }
    return YES;
}

-(BOOL) verifyEmail {
    if (![Utilities isEmailValid:_emailTextFiled.text]) {
        [_emailTextFiled setBackgroundError];
        return NO;
    }
    return YES;
}

-(BOOL) verifyPassword {
    if (![_passwordTextField isValidPassword]) {
        [_passwordTextField setBackgroundError];
        return NO;
    }
    return YES;
}

-(void) updateConstraintsOutletIfNeeded {
    if (IPHONE_4) {
        self.topConstraintEmailTFOutlet.constant -= 60;
    }
}

-(void) hideInvalidDataLabel {
    _invalidDataLabel.hidden = YES;
}

-(void) showInvalidDataLabelWithWrongMessage:(BOOL)wrongMessage wrongPassword:(BOOL)wrongPassword {
    _invalidDataLabel.hidden = NO;
    if (wrongMessage) {
        [_emailTextFiled setBackgroundError];
        _invalidDataLabel.text = emailIsIncorrectMSG;
    }
    if (wrongPassword) {
        [_passwordTextField setBackgroundError];
        _invalidDataLabel.text = incorrectInputDataMSG;
    }
}



@end
