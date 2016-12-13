//
//  FindAccountViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 11/26/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import "WebService.h"
#import "Utilities.h"
#import "ResponseInfo.h"
#import "MBProgressHUD.h"
#import "PrefixHeader.pch"
#import "JBTextField.h"
#import "ReachabilityManager.h"

#import "FindAccountViewController.h"

@interface FindAccountViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIAlertView *accountFoundAlert;
@property (weak, nonatomic) IBOutlet UILabel *accountFoundLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topFoundAccountLabelConstraintOutlet;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topFindButtonConstrailnOutlet;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sendPasswordBottomConstraintOutlet;
@property (weak, nonatomic) IBOutlet UILabel *invalidDataLabel;
@property (weak, nonatomic) IBOutlet JBTextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *findButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *sendPasswordButtonOutlet;

-(IBAction) find:(id)sender;
-(IBAction) sendPassword:(id)sender;

@end

@implementation FindAccountViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Password Recovery";
    
    _emailTextField.delegate = self;
    _emailTextField.textFieldType = TextFieldTypeEmail;
    _emailTextField.text = self.email;
    
    [self hideInvalidDataLabel];
    [self hideAccountFoundLabel];
    self.sendPasswordButtonOutlet.hidden = YES;
    
    UIImage *backButtonImage = [UIImage imageNamed:@"nvg_back_button"];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backButtonImage
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(backButtonTapped)];
    leftBarButtonItem.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    self.accountFoundAlert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"An email has been sent to your account’s email address"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
}


#pragma mark - Action methods

-(void) backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction) find:(id)sender {
    [self.view endEditing:YES];
    if (![Utilities isEmailValid:_emailTextField.text]) {
        self.invalidDataLabel.hidden = NO;
        [_emailTextField setBackgroundError];
        return;
    }
    self.email = _emailTextField.text;
    
    if (![[ReachabilityManager sharedInstance] isReachable]) {
//        [Utilities showAlertViewWithTitle:@""
//                                  message:internetConnectionFailedMSG
//                        cancelButtonTitle:@"OK"];
        return;
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] isExistUserWithEmail:_emailTextField.text
                                           completion:^(ResponseInfo *responseInfo) {
                                               [SVProgressHUD dismiss];
                                               if (responseInfo.objects.count) {
                                                   [self accounFound];
                                               } else {
                                                   [Utilities showAlertViewWithTitle:@""
                                                                             message:@"No account is associated with this Email."
                                                                   cancelButtonTitle:@"OK"];
                                               }
                                           }];
}

-(IBAction) sendPassword:(id)sender {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] requestPasswordResetForEmail:self.email
                                                   completion:^(ResponseInfo *responseInfo) {
                                                       [SVProgressHUD dismiss];
                                                       if (responseInfo.success) {
                                                           [self.accountFoundAlert show];
                                                       } else {
                                                           $l("--- Error reset password -> %@", [responseInfo.error localizedDescription]);
                                                       }
                                                   }];
}


#pragma mark - Delegated methods - UITextFieldDelegate

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    [_emailTextField setBackgroundNormal];
    [self hideInvalidDataLabel];
    
    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark - Delegated methods - UIAlertViewDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self backButtonTapped];
    }
}


#pragma mark - Private methods

-(void) hideInvalidDataLabel {
    _invalidDataLabel.hidden = YES;
}

-(void) showAccountFoundLabel {
    _accountFoundLabel.hidden = NO;
}

-(void) hideAccountFoundLabel {
    _accountFoundLabel.hidden = YES;
}

-(void) accounFound {
    self.sendPasswordButtonOutlet.hidden = NO;
    [self showAccountFoundLabel];
    
    self.findButtonOutlet.hidden = YES;
    self.emailTextField.hidden = YES;
}

@end
