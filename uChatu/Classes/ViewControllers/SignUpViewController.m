//
//  SignUpViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 11/26/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import "ResponseInfo.h"
#import "WebService.h"
#import "Utilities.h"
#import "PrefixHeader.pch"
#import "MBProgressHUD.h"
#import "Utilities.h"
#import "JBTextField.h"
#import "TermsOfServiceViewController.h"
#import "ReachabilityManager.h"
#import "AuthorizationManager.h"
#import "ImaginaryFriend.h"
#import "CDManagerVersionTwo.h"
#import "AddPhoneViewController.h"
#import "XMPPService.h"
#import "PFInstallation+Additions.h"

#import "SignUpViewController.h"


@interface SignUpViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *invalidDataLabel;
@property (weak, nonatomic) IBOutlet JBTextField *emailTextField;
@property (weak, nonatomic) IBOutlet JBTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet JBTextField *confirmPasswordTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraintEmailTFOutlet;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraintLabelImageOutlet;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraintSignUpButtonOutlet;

-(IBAction) signUp:(id)sender;
-(IBAction) termsOfService:(id)sender;
- (IBAction)privacy:(id)sender;

@end


@implementation SignUpViewController

#pragma mark - Interface methods

-(void) viewDidLoad {
    [super viewDidLoad];
    
    [self hideInvalidDataLabel];
    [self updateConstraintsIfNeeded];
    
    self.emailTextField.delegate = self;
    self.emailTextField.textFieldType = TextFieldTypeEmail;
    self.passwordTextField.delegate = self;
    self.passwordTextField.textFieldType = TextFieldTypePassword;
    self.confirmPasswordTextField.delegate = self;
    self.confirmPasswordTextField.textFieldType = TextFieldTypePassword;
    
    if (self.email) {
        _emailTextField.text = self.email;
    }
    
    self.navigationItem.title = @"Sign Up";
    
    UIImage *backButtonImage = [UIImage imageNamed:@"nvg_back_button"];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backButtonImage
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(backButtonTapped)];
    leftBarButtonItem.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}


#pragma mark - Action methods

-(void) backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction) signUp:(id)sender {
    [self.view endEditing:YES];
    
    if (![self verifyInputData]) {
        return;
    }
    
    [_passwordTextField setBackgroundNormal];
    [_confirmPasswordTextField setBackgroundNormal];
    
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] isExistUserWithEmail:[_emailTextField.text lowercaseString]
                                           completion:^(ResponseInfo *responseInfo) {
                                               
        if (responseInfo.objects.count) {
            [SVProgressHUD dismiss];
            [Utilities showAlertViewWithTitle:@""
                                      message:@"Rejected.\nUser with this email already registered"
                            cancelButtonTitle:@"OK"];
        } else {
            __weak typeof(self) weakSelf = self;
            [[WebService sharedInstanse] signUpWithUsername:[_emailTextField.text lowercaseString]
                                                      email:[_emailTextField.text lowercaseString]
                                                   password:_passwordTextField.text
                                                 completion:^(ResponseInfo *responseInfo) {
                                                     [SVProgressHUD dismiss];
                                                     PFUser *currUser = [PFUser currentUser];
                                                     if (responseInfo.success) {
                                                         [AuthorizationManager sharedInstance].currentUser = currUser;
                                                         [AuthorizationManager sharedInstance].currentUser.isUpdatedToVersionTwo = @(YES);
                                                         [AuthorizationManager sharedInstance].currentUser.isOnline = @(YES);
                                                         [[AuthorizationManager sharedInstance].currentUser saveInBackground];
                                                         [Lockbox setString:[_emailTextField.text lowercaseString]
                                                                     forKey:lastSuccessLoggedEmailKey];
                                                         
                                                         [[XMPPService sharedInstance] signUp];
                                                         
                                                         [[WebService sharedInstanse] savePFInstallationForUser:currUser
                                                                                                     completion:^(ResponseInfo *response) {}];
                                                         
                                                         [weakSelf writeToCoreDataNewUser:[AuthorizationManager sharedInstance].currentUser];
                                                         [Utilities requestAccesToAddressBookWithCompletion:^(BOOL finished) {
                                                             [weakSelf pushPhoneNumberVC];
                                                         }];
                                                     } else {
                                                         $l("error = %@", [responseInfo.error localizedDescription]);
                                                     }
                                                 }];
        }
    }];
}

-(IBAction) termsOfService:(id)sender {
    TermsOfServiceViewController *termsVC = [[UIStoryboard authentication] instantiateViewControllerWithIdentifier:@"TermsOfServiceViewController"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:termsVC];
    termsVC.isTermsOfService = YES;
    termsVC.isPrivacy = NO;
    [self presentViewController:navController animated:YES completion:nil];
}

- (IBAction)privacy:(id)sender {
    TermsOfServiceViewController *privacyVC = [[UIStoryboard authentication] instantiateViewControllerWithIdentifier:@"TermsOfServiceViewController"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:privacyVC];
    privacyVC.isTermsOfService = NO;
    privacyVC.isPrivacy = YES;
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - Delegated methods:

#pragma mark —UITextFieldDelegate

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    [self hideInvalidDataLabel];
    if (textField.tag == 0) {
        [_emailTextField setBackgroundNormal];
    }
    if (textField.tag == 1) {
        [_passwordTextField setBackgroundNormal];
    }
    if (textField.tag == 2) {
        [_confirmPasswordTextField setBackgroundNormal];
    }
    
    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    if (textField.tag == 0) {        // emailTextField
        [_passwordTextField becomeFirstResponder];
    } else if (textField.tag == 1) { // passwordTextField
        [_confirmPasswordTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    
    return YES;
}


#pragma mark - Private methods

-(BOOL) verifyInputData {
    if (!_emailTextField.text.length || !_passwordTextField.text.length || !_confirmPasswordTextField.text.length) {
        [self setRedBackgrounForEmptyTextField];
        [Utilities showAlertViewWithTitle:@"" message:alertEmptyFields cancelButtonTitle:@"OK"];
        return NO;
    }
    
    if (![Utilities isEmailValid:_emailTextField.text]) {
        [_emailTextField setBackgroundError];
        [self showInvalidDataLabelWithMessage:@"Email is incorrect"];
        return NO;
    }
    
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

-(void) setRedBackgrounForEmptyTextField {
    if (!_emailTextField.text.length) {
        [_emailTextField setBackgroundError];
    }
    if (!_passwordTextField.text.length) {
        [_passwordTextField setBackgroundError];
    }
    if (!_confirmPasswordTextField.text.length) {
        [_confirmPasswordTextField setBackgroundError];
    }
}

-(void) updateConstraintsIfNeeded {
    if (SCREEN_SIZE.height == 480) {
        self.topConstraintEmailTFOutlet.constant -= 20;
        self.bottomConstraintLabelImageOutlet.constant -= 15;
        self.bottomConstraintSignUpButtonOutlet.constant -= 10;
    }
}

-(void) hideInvalidDataLabel {
    _invalidDataLabel.hidden = YES;
}

-(void) showInvalidDataLabelWithMessage:(NSString *)message {
    _invalidDataLabel.hidden = NO;
    _invalidDataLabel.text = message;
}

- (void)writeToCoreDataNewUser:(PFUser *)user {
    NSManagedObjectContext *context = [CDManagerVersionTwo sharedInstance].managedObjectContext;
    CDUser *newUser = [CDUser userWithEmail:user.email
                                     userId:[Utilities getNewGUID]
                                  inContext:context];
    newUser.userId = user.objectId;
    newUser.phoneNumber = user.phoneNumber;
    
    if ([[CDManagerVersionTwo sharedInstance] saveContext]) {
        $l("All's well");
    };
}

- (void)pushPhoneNumberVC {
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        AddPhoneViewController *addPhoneVc = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"AddPhoneViewController"];
        addPhoneVc.presentationType = UCPresentationTypeSignUp;
        [self.navigationController pushViewController:addPhoneVc animated:YES];
    });
}


@end
