//
//  AddPhoneViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/21/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "JBTextField.h"
#import "SelectCCodeViewController.h"
#import "AuthorizationManager.h"
#import "WebService.h"
#import "ReachabilityManager.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "CDManagerVersionTwo.h"
#import "CDUser.h"
#import "SVProgressHUD.h"

#import "AddPhoneViewController.h"


@interface AddPhoneViewController () <UITextFieldDelegate, UIAlertViewDelegate, SelectCCodeViewControllerDelegate> {
    NSDictionary *_country;
    NSString *phoneNumberStr;
}

@property (weak, nonatomic) IBOutlet UITextField *countryCodeTextField;
@property (weak, nonatomic) IBOutlet JBTextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

- (IBAction)continueButtonTapped:(id)sender;
- (IBAction)skipButtonTapped:(id)sender;

@end


@implementation AddPhoneViewController

#pragma mark - Interface methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Phone Number";
    
    self.countryCodeTextField.delegate = self;
    self.phoneNumberTextField.delegate = self;
    
    self.infoLabel.text = @"The number is needed to find\nyour friends for chat & role-play";
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupButtonTitlesForPresentationType:_presentationType];
}


-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}


-(void)setPresentationType:(UCPresentationType)presentationType {
    _presentationType = presentationType;
    [self setupButtonTitlesForPresentationType:presentationType];
}


#pragma mark Private methods

-(void)setupButtonTitlesForPresentationType:(UCPresentationType)type {
    [_saveButton setTitle:[self saveButtonTitleForPresentationType:type] forState:UIControlStateNormal];
    [_cancelButton setTitle:[self cancelButtonTitleForPresentationType:type] forState:UIControlStateNormal];
}


-(NSString *)saveButtonTitleForPresentationType:(UCPresentationType)type {
    switch (type) {
        case UCPresentationTypeSettings:    return @"SAVE";
        case UCPresentationTypeSignUp:      return @"CONTINUE";
        default:                            return nil;
    }
}


-(NSString *)cancelButtonTitleForPresentationType:(UCPresentationType)type {
    switch (type) {
        case UCPresentationTypeSettings:    return @"CANCEL";
        case UCPresentationTypeSignUp:      return @"SKIP";
        default:                            return nil;
    }
}


#pragma mark - Action methods

- (IBAction)continueButtonTapped:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
//        [Utilities showAlertViewWithTitle:@""
//                                  message:internetConnectionFailedMSG
//                        cancelButtonTitle:@"OK"];
        return;
    }
    if (![self isPrintedPhoneNumber]) {
        [Utilities showAlertViewWithTitle:@"" message:phoneNumInvalidMSG cancelButtonTitle:@"Cancel"];
        return;
    }
    if (!_country[kCountryCode]) {
        [Utilities showAlertViewWithTitle:@"Warning!"
                                  message:choosePhoneNumberMSG
                        cancelButtonTitle:@"Cancel"];
        return;
    }
    
    phoneNumberStr = [NSString stringWithFormat:@"(+%@) %@", _country[kCountryCode], _phoneNumberTextField.text];
    [self showAlertConfirmNumber];
}

- (IBAction)skipButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Delegated methods:
#pragma mark - —UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField.tag == 0) {
        SelectCCodeViewController *selectCodeVC = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"SelectCCodeViewController"];
        selectCodeVC.delegate = self;
        [self.navigationController pushViewController:selectCodeVC animated:YES];
        return NO;
    }
    return YES;
}


#pragma mark - —SelectCCodeViewControllerDelegate

- (void)countrySelected:(NSDictionary *)country {
    _country = country;
    
    if (!country) {
        return;
    }
    
    self.countryCodeTextField.text = [NSString stringWithFormat:@"%@ (+%@)", country[kCountryName], country[kCountryCode]];
}


#pragma mark - —UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self savePhoneNumber];
    }
}

#pragma mark - Private methods

- (void)showAlertConfirmNumber {
    NSString *message = [NSString stringWithFormat:@"%@\n%@", checkCorrectPhoneNumMSG, phoneNumberStr];
    UIAlertView *checkNumAlert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"OK", nil];
    [checkNumAlert show];
}

- (void)savePhoneNumber {
    __weak typeof(self) weakSelf = self;
    
    PFUser *currUser = [AuthorizationManager sharedInstance].currentUser;
    NSString *phoneNum = [NSString stringWithFormat:@"+%@%@", _country[kCountryCode], _phoneNumberTextField.text];
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] isExistUserWithPhone:phoneNum completion:^(ResponseInfo *response) {
        if (response.objects.count) {
            [SVProgressHUD dismiss];
            [Utilities showAlertViewWithTitle:@""
                                      message:@"Rejected.\nUser with this phone number already registered"
                            cancelButtonTitle:@"OK"];
        } else {
            currUser.phoneNumber = phoneNum;
            currUser.shortPhoneNumber = [Utilities shortPhoneNumberFromNumber:phoneNum];
            currUser.countryCode = _country[kCountryCode];
            [[WebService sharedInstanse] updateCurrentUserWithBlock:^(ResponseInfo *response) {
                [SVProgressHUD dismiss];
                if (response.success) {
                    [AuthorizationManager sharedInstance].currentCDUser.phoneNumber = phoneNumberStr;
                    [[CDManagerVersionTwo sharedInstance] saveContext];
                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
                } else {
                    $l("error -> %@", [response.error localizedDescription]);
                }
            }];
        }
    }];
    
    
}

- (BOOL)isPrintedPhoneNumber {
    if (!_phoneNumberTextField.text.length) {
        return NO;
    }
    return YES;
}

@end
