//
//  ChangeNameViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/23/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>
#import "PrefixHeader.pch"
#import "CDUserSettings.h"
#import "WebService.h"
#import "ResponseInfo.h"
#import "AuthorizationManager.h"
#import "CoreDataManager.h"
#import "AuthorizationManager.h"
#import "ReachabilityManager.h"
#import "SharedDateFormatter.h"
#import "CDUser.h"
#import "CDManagerVersionTwo.h"
#import "MBProgressHUD.h"

#import "ChangeNameViewController.h"


@interface ChangeNameViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

- (IBAction)back:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end


@implementation ChangeNameViewController

#pragma mark - Interface methods

-(void) viewDidLoad {
    [super viewDidLoad];
    
    self.nameTextField.delegate = self;
    self.nameTextField.text = self.name;
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
    PFUser *currentUser = [AuthorizationManager sharedInstance].currentUser;
    if (![_nameTextField.text isEqualToString:currentUser.userName]) {
        currentUser.userName = _nameTextField.text;
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        [[WebService sharedInstanse] updateCurrentUserWithBlock:^(ResponseInfo *response) {
            if (response.success) {
                CDUser *currUser = [AuthorizationManager sharedInstance].currentCDUser;
                currUser.userName = _nameTextField.text;
                currUser.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
                [SVProgressHUD dismiss];
                if ([[CDManagerVersionTwo sharedInstance] saveContext]) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                    message:@"Name was changed"
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil, nil];
                    [alert show];
                } else {
                    $l(" --- saveContext Error. ");
                }
            } else {
                $l(" --- Update Current User Error. -> %@", [response.error localizedDescription]);
            }
        }];
        
        
    }
}

-(IBAction) cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Delegated methods - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}



#pragma mark - Delegated methods - UIAlertViewDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSTimeInterval delay = 0.2;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }
}

@end
