//
//  MySettingsViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 11/19/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import "UIImage+Resize.h"
#import <Parse/Parse.h>
#import "TPKeyboardAvoidingScrollView.h"
#import "PrefixHeader.pch"
#import "RoundedImageView.h"
#import "WebService.h"
#import "AuthorizationManager.h"
#import "Utilities.h"
#import "ImagePickerManager.h"
#import "JBTextField.h"
#import "SharingViewController.h"
#import "NewPasswordViewController.h"
#import "CDManagerVersionTwo.h"
#import "SharedDateFormatter.h"
#import "MBProgressHUD.h"
#import "ResponseInfo.h"
#import "ReachabilityManager.h"
#import "ChangeEmailViewController.h"
#import "ChangeNameViewController.h"
#import "CDUser.h"
#import "AddPhoneViewController.h"
#import "XMPPService.h"
#import "MySettingsViewController.h"
#import "PFInstallation+Additions.h"


@interface MySettingsViewController () <UITextFieldDelegate, ImagePickerDelegate, UIActionSheetDelegate> {
    
    BOOL isImagePickerControllerShowed;

    PFUser *currentUser;
    CDUser *currentCDUser;
}

@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoutTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topNameTextFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topEmailTextFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topPasswordTextFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topPhoneNumberConstraint;

@property (strong, nonatomic) UIActionSheet *choosePhotoActionSheet;

@property (weak, nonatomic) IBOutlet RoundedImageView *avatarImageView;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet JBTextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet JBTextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoOutlet;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareButtonOutlet;

@property (nonatomic) ImagePickerManager *imagePicker;

-(IBAction) logout:(id)sender;
- (IBAction)addPhoto:(id)sender;

- (IBAction)avatarImageTapGesRec:(id)sender;
- (IBAction)shareBarButtonPressed:(id)sender;


@end

@implementation MySettingsViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    
    if (!IPHONE_4) {
        self.scrollView.scrollEnabled = NO;
    }
    [self updateConstraintsIfNeeded];
    
    self.title = @"My Settings";
    
    self.navigationItem.leftBarButtonItem = _shareButtonOutlet;
    
    self.nameTextField.delegate = self;
    self.emailTextField.delegate = self;
    self.emailTextField.textFieldType = TextFieldTypeEmail;
    self.passwordTextField.delegate = self;
    self.passwordTextField.allowsEditingTextAttributes = NO;
    
    self.phoneNumberTextField.delegate = self;
    
    self.imagePicker = [[ImagePickerManager alloc] init];
    self.imagePicker.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userAvatarWasDownloaded:)
                                                 name:kAvatarImageWasDownloaded
                                               object:nil];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (isImagePickerControllerShowed) {
        isImagePickerControllerShowed = NO;
        return;
    }
    
    currentUser = [AuthorizationManager sharedInstance].currentUser;
    currentCDUser = [AuthorizationManager sharedInstance].currentCDUser;
    [self updateCurrentCDUserWithUser:currentUser];
    
    if ([self isChangedImage]) {
        [self updateTitleForAddPhotoButton];
    } else {
        [_addPhotoOutlet setTitle:@"ADD PHOTO" forState:UIControlStateNormal];
    }
    [self reloadUserData];
    
    [[WebService sharedInstanse] getUserAvatarImageForUser:currentUser withBlock:^(ResponseInfo *response) {
        if (response.success) {
            UIImage *image = [response.objects lastObject];
            if (image) {
                NSString *pathToSave = [Utilities pathToImageWithName:currentCDUser.avatarImageName userId:currentCDUser.userId];
                [Utilities saveImage:image atPath:pathToSave];
                
                currentCDUser.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
                [[CDManagerVersionTwo sharedInstance] saveContext];
                _avatarImageView.image = image;
            }
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                      selector:@selector(keyboardDidHide:)
                          name:UIKeyboardDidHideNotification
                        object:nil];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
}

//-(UINavigationItem *) navigationItem {
//    UINavigationItem *navItem = [super navigationItem];
//    navItem.leftBarButtonItem = nil;
//    navItem.rightBarButtonItem = nil;
//    
//    navItem.leftBarButtonItem = _shareButtonOutlet;
//    
//    return navItem;
//}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Action methods

-(IBAction) logout:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    [_scrollView setContentOffset:CGPointMake(0, 0)
                         animated:YES];
    [[XMPPService sharedInstance] disconnect];
    [[AuthorizationManager sharedInstance] setCurrentUserOnline:NO];
    [AuthorizationManager sharedInstance].userAvatarImage = nil;
    [[WebService sharedInstanse] logOut];
    [AuthorizationManager presentLoginViewControllerForViewController:self animated:YES];
    
    NSTimeInterval delay = 0.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutButtonTappedNotification object:nil];
    });
}

- (IBAction)addPhoto:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    self.choosePhotoActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:@"Delete"
                                                     otherButtonTitles:@"Take Picture", @"Choose Picture", nil];
    [self.choosePhotoActionSheet showInView:self.view];
}

- (IBAction)avatarImageTapGesRec:(id)sender {
    [self addPhoto:nil];
}

- (IBAction)shareBarButtonPressed:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    SharingViewController *sharingVC = [[UIStoryboard authentication] instantiateViewControllerWithIdentifier:@"SharingViewController"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:sharingVC];
    navController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navController animated:YES completion:nil];
}




#pragma mark - Notification observers

-(void) keyboardDidHide:(NSNotification *) notification {
    [self navigationItem];
}

- (void)userAvatarWasDownloaded:(id)object {
    NSNotification *notification = object;
    NSString *objectId = notification.object;
    if ([objectId isEqualToString:[AuthorizationManager sharedInstance].currentUser.objectId]) {
        [self reloadUserData];
    }
}


#pragma mark - Delegated methods

#pragma mark - —UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"Cancel"];
        return NO;
    }
    if (textField.tag == 0) {
        ChangeNameViewController *changeNameVC = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"ChangeNameViewController"];
        changeNameVC.name = currentCDUser.userName;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:changeNameVC];
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navController animated:YES completion:nil];
    }
    if (textField.tag == 1) {
        ChangeEmailViewController *changeMailVC = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"ChangeEmailViewController"];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:changeMailVC];
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navController animated:YES completion:nil];
    }
    if (textField.tag == 2) {
        NewPasswordViewController *newPasswordVC = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"NewPasswordViewController"];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newPasswordVC];
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navController animated:YES completion:nil];
    }
    if (textField.tag == 3) {
        AddPhoneViewController *addPhoneVC = [[UIStoryboard settings] instantiateViewControllerWithIdentifier:@"AddPhoneViewController"];
        addPhoneVC.presentationType = UCPresentationTypeSettings;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addPhoneVC];
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:navController animated:YES completion:nil];
    }
    return NO;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self navigationItem];
    
    return YES;
}


#pragma mark —ImagePickerDelegate

-(void) imagePickerChoseImage:(UIImage *)image {
    UIImage *newImage = [Utilities generateThumbnailImageFromImage:image];
    self.avatarImageView.image = newImage;
    [self updateTitleForAddPhotoButton];
    if (!newImage) {
        return;
    }
    if ([[ReachabilityManager sharedInstance] isReachable]) {
        [[WebService sharedInstanse] uploadUserAvatarImage:newImage withBlock:^(ResponseInfo *response) {
            if (response.success) {
                NSString *pathToSave = [Utilities pathToImageWithName:currentCDUser.avatarImageName userId:currentCDUser.userId];
                [Utilities saveImage:_avatarImageView.image atPath:pathToSave];
                
                currentCDUser.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
                [[CDManagerVersionTwo sharedInstance] saveContext];
            } else {
                $l("Save user avatar error -> %@", [response.error localizedDescription]);
                [Utilities showAlertViewWithTitle:@"save error"
                                          message:[response.error localizedDescription]
                                 cancelButtonTitle:@"Cancel"];
            }
        }];
    }
    
    NSString *pathToSave = [Utilities pathToImageWithName:currentCDUser.avatarImageName userId:currentCDUser.userId];
    [Utilities saveImage:_avatarImageView.image atPath:pathToSave];
    
    currentCDUser.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
    [[CDManagerVersionTwo sharedInstance] saveContext];
}


#pragma mark UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // remove existing image
        self.avatarImageView.image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
    } else if (buttonIndex == 1) {
        // take picture with camera
        isImagePickerControllerShowed = YES;
        [self.imagePicker createImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera
                                                  forViewController:self];
    } else if (buttonIndex == 2) {
        // choose picture from Camera Roll
        isImagePickerControllerShowed = YES;
        [self.imagePicker createImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                                  forViewController:self];
    }
}

#pragma mark - Private methods

-(BOOL) checkEmailVaild {
    if ([Utilities isEmailValid:_emailTextField.text]) {
        return YES;
    }
    
    return NO;
}

-(void) reloadUserData {
    self.nameTextField.text = currentCDUser.userName;
    self.phoneNumberTextField.text = currentCDUser.phoneNumber;
    self.emailTextField.text = currentUser.email;

    UIImage *image = [Utilities getImageWithName:currentCDUser.avatarImageName];
    self.avatarImageView.image = image ? image : [UIImage imageNamed:@"cht_emptyAvatar_image"];

    [self navigationItem];
}

-(BOOL) isChangedImage {
    return [AuthorizationManager sharedInstance].currentUser.photo ? YES : NO;
}

-(void) updateTitleForAddPhotoButton {
    [_addPhotoOutlet setTitle:@"CHANGE PHOTO" forState:UIControlStateNormal];
}

-(void) updateConstraintsIfNeeded {
    if (IPHONE_4) {
        _topNameTextFieldConstraint.constant = 16;
        _topEmailTextFieldConstraint.constant = 19;
        _topPasswordTextFieldConstraint.constant = 19;
//        _logoutTopConstraint.constant = 16;
    } else if (IPHONE_5) {
        _topNameTextFieldConstraint.constant = 26;
        _topEmailTextFieldConstraint.constant = 22;
        _topPasswordTextFieldConstraint.constant = 22;
        _topPhoneNumberConstraint.constant = 22;
        _logoutTopConstraint.constant = 30;
    } else if (IPHONE_6) {
        _topNameTextFieldConstraint.constant = 44;
        _topEmailTextFieldConstraint.constant = 36;
        _topPasswordTextFieldConstraint.constant = 36;
        _logoutTopConstraint.constant = 50;
    } else if (IPHONE_6PLUS) {
        _topNameTextFieldConstraint.constant = 54;
        _topEmailTextFieldConstraint.constant = 36;
        _topPasswordTextFieldConstraint.constant = 36;
        _logoutTopConstraint.constant = 150;
    }
}

- (void)updateCurrentCDUserWithUser:(PFUser *)user {
    if ([user.updatedAt compare:currentCDUser.lastUpdated] == NSOrderedDescending) {
        currentCDUser.userName = user.userName;
        currentCDUser.phoneNumber = user.phoneNumber;
        currentCDUser.email = user.email;
        currentCDUser.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
        [[CDManagerVersionTwo sharedInstance] saveContext];
        
        UIImage *image = [AuthorizationManager sharedInstance].userAvatarImage;
        if (image) {
            _avatarImageView.image = image;
            NSString *pathToSave = [Utilities pathToImageWithName:currentCDUser.avatarImageName userId:currentCDUser.userId];
            [Utilities saveImage:image atPath:pathToSave];
            
            currentCDUser.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
            [[CDManagerVersionTwo sharedInstance] saveContext];
        }
    }
}


@end
