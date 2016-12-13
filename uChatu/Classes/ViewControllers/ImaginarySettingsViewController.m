 //
//  ImagenarySettingsViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 11/19/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>
#import "Complaint.h"
#import "TPKeyboardAvoidingScrollView.h"
#import "WebService.h"
#import "ImagePickerManager.h"
#import "Utilities.h"
#import "PrefixHeader.pch"
#import "RoundedImageView.h"
#import "SharingViewController.h"
#import "CDManagerVersionTwo.h"
#import "SharedDateFormatter.h"
#import "AuthorizationManager.h"
#import "NSString+Calculation.h"
#import "ImaginaryFriend.h"
#import "ReachabilityManager.h"
#import "CDImaginaryFriend.h"
#import "MBProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "AvatarPhoto.h"
#import "ReviewImageViewController.h"
#import "ShareManager.h"

#import "ImaginarySettingsViewController.h"

static NSString * const kBiographyPlaceholder = @"BIOGRAPHY";

@interface ImaginarySettingsViewController () <UITextFieldDelegate, UIAlertViewDelegate, UITextViewDelegate, ImagePickerDelegate, UIActionSheetDelegate> {
    BOOL isNameEdited;
    BOOL isAgeEdited;
    BOOL isOccupationEdited;
    BOOL isPersonalityEdited;
    BOOL isAvatarChanged;
    BOOL isNewImaginaryFriend;
    BOOL isPublicTypeEdited;
    BOOL isBiographyEdited;
    BOOL isInfoWatching;
    
    BOOL isImagePickerControllerShown;
    
    PFUser *currentUser;
    
    UIBarButtonItem *backBarButtonItem;
    UIBarButtonItem *blockBarBtnItem;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topNameTextFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topAgeTextFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topOccupTextFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topPersTextFieldConstraint;

@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;
@property (weak, nonatomic) IBOutlet RoundedImageView *friendAvatarImageVeiw;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoOutlet;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *ageTextField;
@property (weak, nonatomic) IBOutlet UITextField *occupationTextField;
@property (weak, nonatomic) IBOutlet UITextField *personalityTextField;
@property (weak, nonatomic) IBOutlet UITextView *biographyTextView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButtonOutlet;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButtonOutlet;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveSelectedButtonOutlet;

@property (strong, nonatomic) UIActionSheet *choosePhotoActionSheet;

@property (nonatomic) ImagePickerManager *imagePicker;
@property (weak, nonatomic) IBOutlet UISegmentedControl *publicTypeSegmentedControlOutlet;
@property (nonatomic, strong) ImaginaryFriend *pImaginaryFriend;
@property (nonatomic, strong) AvatarPhoto *avatarImage;

- (IBAction)addPhoto:(id)sender;
- (IBAction)avatarImageTapped:(id)sender;
- (IBAction)publicTypeSegmentedControlTapped:(id)sender;
- (IBAction)backBarButtonPressed:(id)sender;
- (IBAction)saveBarButtonPressed:(id)sender;


@end

@implementation ImaginarySettingsViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Settings";
    
    [self updateConstraintsIfNeeded];
    
    if (!self.imaginaryFriend && !self.parseImaginaryFriend) {
        isNewImaginaryFriend = YES;
    } else if (self.parseImaginaryFriend) {
        isInfoWatching = YES;
        _publicTypeSegmentedControlOutlet.hidden = YES;
        _addPhotoOutlet.hidden = YES;
        self.title = @"Info";
    }
    
    blockBarBtnItem = [[UIBarButtonItem alloc]
                                        initWithImage:[UIImage imageNamed:@"blok_icon"]
                                        style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(blockButtonTapped)];
    blockBarBtnItem.tintColor = [UIColor blackColor];
    
    self.navigationItem.leftBarButtonItem = self.backButtonOutlet;
    
    _publicTypeSegmentedControlOutlet.tintColor = [UIColor colorWithRed:76/255.0
                                                                  green:217/255.0
                                                                   blue:100/255.0
                                                                  alpha:1.0];
    
    _nameTextField.delegate = self;
    _ageTextField.delegate = self;
    _occupationTextField.delegate = self;
    _personalityTextField.delegate = self;
    _biographyTextView.delegate = self;
    
    self.imagePicker = [[ImagePickerManager alloc] init];
    self.imagePicker.delegate = self;
    
    if (!isNewImaginaryFriend && !isInfoWatching) {
        if ([[ReachabilityManager sharedInstance] isReachable]) {
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
            [[WebService sharedInstanse] getImaginaryFriendWithObjectId:_imaginaryFriend.objectId
                                                        completionBlock:^(ResponseInfo *response){
                                                            [SVProgressHUD dismiss];
                                                            _pImaginaryFriend = [response.objects firstObject];
                                                        }];
        }
    }
    
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    currentUser = [AuthorizationManager sharedInstance].currentUser;
    
    if (isImagePickerControllerShown) {
        return;
    }
    
    if ([self isChangedFriendImage]) {
        [self updateTitleForAddPhotoButton];
    } else {
        [_addPhotoOutlet setTitle:@"ADD PHOTO" forState:UIControlStateNormal];
    }
    [self reloadUserData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (isImagePickerControllerShown) {
        isImagePickerControllerShown = NO;
        [self navigationItem];
    }
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
//    [self setNoForChangesFlags];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

-(UINavigationItem *) navigationItem {
    UINavigationItem *navItem = [super navigationItem];
    if (isImagePickerControllerShown) {
        return navItem;
    }
    if (isInfoWatching) {
        navItem.rightBarButtonItem = blockBarBtnItem;
    }
    
    if ([self isSettingsEdited]) {
        navItem.rightBarButtonItem = _saveSelectedButtonOutlet;
    } else {
        if (!isInfoWatching) {
            navItem.rightBarButtonItem = _saveButtonOutlet;
        }
    }
    
    return navItem;
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Action methods

- (IBAction)addPhoto:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    if (isInfoWatching) {
        return;
    }
    [self.view endEditing:YES];
    
    self.choosePhotoActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:@"Delete"
                                                     otherButtonTitles:@"Take Picture", @"Choose Picture", nil];
    self.choosePhotoActionSheet.tag = 1;
    [self.choosePhotoActionSheet showInView:self.view];
}

- (IBAction)avatarImageTapped:(id)sender {
    if (isInfoWatching) {
        [self showAvatarFullImage];
    } else {
        [self addPhoto:nil];
    }
}

- (IBAction)publicTypeSegmentedControlTapped:(id)sender {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return;
    }
    
    isPublicTypeEdited = YES;
    [self navigationItem];
    switch (_publicTypeSegmentedControlOutlet.selectedSegmentIndex) {
        case 0:
            _imaginaryFriend.publicType = @(ImaginaryFriendPublicTypeVisible);
            break;
        case 1:
            _imaginaryFriend.publicType = @(ImaginaryFriendPublicTypePrivate);
            break;
        default:
            break;
    }
}

- (IBAction)backBarButtonPressed:(id)sender {
    if ([self isSettingsEdited]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                            message:changesNotSavedMSG
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"OK", nil];
        alertView.tag = 1;
        [alertView show];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveBarButtonPressed:(id)sender {
    [self.view endEditing:YES];
    NSManagedObjectContext *context = [CDManagerVersionTwo sharedInstance].managedObjectContext;
    
    if (!self.imaginaryFriend) {
        self.imaginaryFriend = [CDImaginaryFriend imaginaryFriendWithObjectId:[Utilities getNewGUID]
                                                                    inContext:context];
    }
    if (isNameEdited) {
        self.imaginaryFriend.friendName = _nameTextField.text;
    }
    if (isAgeEdited) {
        NSNumber *age = [NSNumber numberWithInteger:[_ageTextField.text integerValue]];
        self.imaginaryFriend.friendAge = age;
    }
    if (isOccupationEdited) {
        self.imaginaryFriend.occupation = _occupationTextField.text;
    }
    if (isPersonalityEdited) {
        self.imaginaryFriend.personality = _personalityTextField.text;
    }
    if (isBiographyEdited) {
        if ([_biographyTextView.text isEqualToString:kBiographyPlaceholder]) {
            self.imaginaryFriend.biography = @"";
        } else {
            self.imaginaryFriend.biography = _biographyTextView.text;
        }
    }
    if (isPublicTypeEdited) {
        self.imaginaryFriend.publicType = @(_publicTypeSegmentedControlOutlet.selectedSegmentIndex);
    }
    if (isAvatarChanged) {
        UIImage *image = self.friendAvatarImageVeiw.image;
        NSString *imagePath = [Utilities pathToImageWithName:self.imaginaryFriend.avatarImageName
                                                            userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
        [Utilities saveImage:image atPath:imagePath];
    }
    
    if ([self isSettingsEdited]) {
        _imaginaryFriend.lastUpdated = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
        if (isNewImaginaryFriend) {
            if (!_nameTextField.text.length) {
                _imaginaryFriend.friendName = @"Imaginary Friend";
            }
            CDUser *currCDUser  = [AuthorizationManager sharedInstance].currentCDUser;
            _imaginaryFriend.user = currCDUser;
            
        }
        [self saveChanges];
    }
    
    if ([self isSettingsEdited] && !isNewImaginaryFriend) {
        
    }
    [self setNoForChangesFlags];
    [self navigationItem];
    [self reloadUserData];
}

-(void) userSettingsChanged {
    [self reloadUserData];
}

- (void)blockButtonTapped {
    NSString *blockButtonTitle = nil;
    if ([_parseImaginaryFriend isBlockedByUser:[AuthorizationManager sharedInstance].currentUser]) {
        blockButtonTitle = @"Unblock";
    } else {
        blockButtonTitle = @"Block";
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Report Inappropriate"
                                                    otherButtonTitles:blockButtonTitle, nil];
    actionSheet.tag = 2;
    [actionSheet showInView:self.view];
}


#pragma mark - Notification observers

-(void) keyboardDidHide:(NSNotification *) notification {
    [self navigationItem];
}


#pragma mark - Delegated methods 
#pragma mark - —UITextFieldDelegate

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return NO;
    }
    if (isInfoWatching) {
        return NO;
    }
    if (textField.tag == 1) {
        _ageTextField.text = @"";
    }
    
    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    return YES;
}

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField.tag == 0) {
        isNameEdited = YES;
    }
    if (textField.tag == 1) {
        isAgeEdited = YES;
    }
    if (textField.tag == 2) {
        isOccupationEdited = YES;
    }
    if (textField.tag == 3) {
        isPersonalityEdited = YES;
    }
    NSString *text = textField.text;
    text = [text stringByReplacingCharactersInRange:range withString:string];
    CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName : textField.font}];
    
    return (textSize.width < textField.bounds.size.width) ? YES : NO;
    
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag == 1) {
        NSString *yearWord = [textField.text integerValue] == 1 ? @"year" : @"years";
        textField.text = [NSString stringWithFormat:@"%ld %@", (long)[textField.text integerValue], yearWord];
    }
}


#pragma mark - —UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:internetConnectionFailedMSG
                        cancelButtonTitle:@"OK"];
        return NO;
    }
    
    if (isInfoWatching) {
        return NO;
    }
    if ([textView.text isEqualToString:kBiographyPlaceholder]) {
        _biographyTextView.text = @"";
        _biographyTextView.textColor = [UIColor blackColor];
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    isBiographyEdited = YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (!textView.text.length) {
        [self setPlaceholderForBiographyTextView];
    }
}


#pragma mark - —UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self backBarButtonPressed:nil];
        });
    } else if (alertView.tag == 3) {
        [self setNoForChangesFlags];
        [self navigationItem];
    } else if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [self saveBarButtonPressed:nil];
        }
        if (buttonIndex == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}


#pragma mark - —ImagePickerDelegate

-(void) imagePickerChoseImage:(UIImage *)image {
    isAvatarChanged = YES;
    self.friendAvatarImageVeiw.image = [Utilities generateThumbnailImageFromImage:image];
    [self updateTitleForAddPhotoButton];
    
    self.avatarImage = [AvatarPhoto avatarImageWithImage:image imaginaryFriend:_pImaginaryFriend];
}


#pragma mark - —UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 1) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            // remove existing image
            self.friendAvatarImageVeiw.image = [UIImage imageNamed:@"cht_emptyAvatar_image"];
            self.avatarImage = [AvatarPhoto avatarImageWithImage:nil imaginaryFriend:_pImaginaryFriend];
            isAvatarChanged = YES;
        } else if (buttonIndex == 1) {
            // take picture with camera
            isImagePickerControllerShown = YES;
            [self.imagePicker createImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera
                                                      forViewController:self];
        } else if (buttonIndex == 2) {
            // choose picture from Camera Roll
            isImagePickerControllerShown = YES;
            [self.imagePicker createImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                                      forViewController:self];
        }
    } else if (actionSheet.tag == 2) {
        if (buttonIndex == 0) {
            Complaint *complaintObj = [Complaint object];
            complaintObj.reporter = [AuthorizationManager sharedInstance].currentUser;
            complaintObj.inappropriateObject = self.parseImaginaryFriend;
            
            
            [[WebService sharedInstanse] sendComplaint:complaintObj completion:^(ResponseInfo *response) {
                if (response.success) {
                    [Utilities showAlertViewWithTitle:@""
                                              message:kThanksForComplaintProfileMSG
                                    cancelButtonTitle:@"OK"];
                }
            }];
        } else if (buttonIndex == 1) {
            if ([_parseImaginaryFriend isBlockedByUser:[AuthorizationManager sharedInstance].currentUser]) {
                // Unblock
                [_parseImaginaryFriend removeObject:[AuthorizationManager sharedInstance].currentUser.objectId forKey:[ImaginaryFriend blockedByUsersPropertyName]];
            } else {
                // block
                [_parseImaginaryFriend addUniqueObject:[AuthorizationManager sharedInstance].currentUser.objectId forKey:[ImaginaryFriend blockedByUsersPropertyName]];
            }
            
            [_parseImaginaryFriend saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                if (success) {
                    NSString *str = [_parseImaginaryFriend isBlockedByUser:[AuthorizationManager sharedInstance].currentUser] ? @"Blocked" : @"Unblocked";
                    [Utilities showAlertViewWithTitle:@"" message:str cancelButtonTitle:@"Ok"];
                } else {
                    [Utilities showAlertWithParseError:error];
                }
            }];
        }
    }
}


#pragma mark - Private methods

- (NSString *)createReportInappropriateString {
    return [NSString stringWithFormat:@"Report Inappropriate:\n Imaginary Friend with objectId = %@,\nname - %@\n\nInput description:\n", _parseImaginaryFriend.objectId, _parseImaginaryFriend.friendName];
}

- (void)showAvatarFullImage {
    if (!self.parseImaginaryFriend.avatarPhoto) {
        return;
    }
    
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] getAvatarPhotosForImaginaryFriend:self.parseImaginaryFriend
                                                        completion:^(ResponseInfo *response) {
                                                            [SVProgressHUD dismiss];
                                                            if (response.success) {
                                                                NSArray *photos = response.objects;
                                                                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId = %@", self.parseImaginaryFriend.avatarPhoto.objectId];
                                                                AvatarPhoto *photo = [[photos filteredArrayUsingPredicate:predicate] lastObject];
                                                                if (photo) {
                                                                    NSURL *fullImageURL = [NSURL URLWithString:photo.fullImage.url];
                                                                    SDWebImageManager *manager = [SDWebImageManager sharedManager];
                                                                    [manager downloadImageWithURL:fullImageURL
                                                                                          options:0
                                                                                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                                                             // progression tracking code
                                                                                         }
                                                                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                                                            if (image) {
                                                                                                [SVProgressHUD dismiss];
                                                                                                ReviewImageViewController *reviewImageVC = [[UIStoryboard chats] instantiateViewControllerWithIdentifier:@"ReviewImageViewController"];
                                                                                                reviewImageVC.imageForReview = image;
                                                                                                reviewImageVC.imFriend = self.parseImaginaryFriend;
                                                                                                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:reviewImageVC];
                                                                                                [self presentViewController:navController animated:YES completion:nil];
                                                                                            } else {
                                                                                                [Utilities showAlertViewWithTitle:@"Error!"
                                                                                                                          message:[error localizedDescription]
                                                                                                                cancelButtonTitle:@"Cancel"];
                                                                                            }
                                                                                        }];
                                                                }
                                                            } else {
                                                                $l("--- error - %@", [response.error localizedDescription]);
                                                            }
                                                            
                                                        }];
}

- (void)setPlaceholderForBiographyTextView {
    _biographyTextView.text = kBiographyPlaceholder;
    _biographyTextView.textColor = [UIColor colorWithRed:199/255.0f green:199/255.0f blue:205/255.0f alpha:1.0f];
}

- (void)setNoForChangesFlags {
    isNameEdited = NO;
    isAgeEdited = NO;
    isOccupationEdited = NO;
    isPersonalityEdited = NO;
    isAvatarChanged = NO;
    isPublicTypeEdited = NO;
    isBiographyEdited = NO;
}

- (BOOL)isChangedFriendImage {
    NSString *imageName = self.imaginaryFriend.avatarImageName;
    NSString *imagePath = [Utilities pathToImageWithName:imageName
                                                        userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
    UIImage *image = [Utilities getAvatarImageAtPath:imagePath];
    if (image) {
        return YES;
    }
    return NO;
}

-(void) updateTitleForAddPhotoButton {
    [_addPhotoOutlet setTitle:@"CHANGE PHOTO"
                     forState:UIControlStateNormal];
}

-(void) reloadUserData {
    if (!isInfoWatching) {
        _publicTypeSegmentedControlOutlet.selectedSegmentIndex = [_imaginaryFriend.publicType integerValue];
        
        NSString *imagePath = [Utilities pathToImageWithName:self.imaginaryFriend.avatarImageName
                                                            userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
        UIImage *image = [Utilities getAvatarImageAtPath:imagePath];
        self.friendAvatarImageVeiw.image = image ? image : [UIImage imageNamed:@"cht_emptyAvatar_image"];
        
        _ageTextField.text = [Utilities getAgeStringForValue:_imaginaryFriend.friendAge];
        
        _nameTextField.text = _imaginaryFriend.friendName;
        _personalityTextField.text = _imaginaryFriend.personality;
        _occupationTextField.text = _imaginaryFriend.occupation;
        _biographyTextView.text = _imaginaryFriend.biography;
        if (!_biographyTextView.text.length) {
            [self setPlaceholderForBiographyTextView];
        }
    } else {
        _publicTypeSegmentedControlOutlet.selectedSegmentIndex = [_parseImaginaryFriend.publicType integerValue];
        [self.friendAvatarImageVeiw sd_setImageWithURL:[NSURL URLWithString:_parseImaginaryFriend.avatar.url]
                                      placeholderImage:[UIImage imageNamed:@"cht_emptyAvatar_image"]];
        _nameTextField.text = _parseImaginaryFriend.friendName;
        _ageTextField.text = [Utilities getAgeStringForValue:_parseImaginaryFriend.friendAge];
        _personalityTextField.text = _parseImaginaryFriend.personality;
        _occupationTextField.text = _parseImaginaryFriend.occupation;
        if (!_parseImaginaryFriend.biography.length) {
            [self setPlaceholderForBiographyTextView];
        } else {
            _biographyTextView.text = _parseImaginaryFriend.biography;
        }
    }
}

-(BOOL) isSettingsEdited {
    if (isNameEdited || isAgeEdited || isOccupationEdited || isBiographyEdited ||
        isPersonalityEdited || isAvatarChanged || isPublicTypeEdited) {
        return YES;
    }
    return NO;
}

-(void) updateConstraintsIfNeeded {
    if (IPHONE_4) {
        _topNameTextFieldConstraint.constant = 18;
        _topAgeTextFieldConstraint.constant = 19;
        _topOccupTextFieldConstraint.constant = 19;
        _topPersTextFieldConstraint.constant = 19;
    } else if (IPHONE_6) {
        _topNameTextFieldConstraint.constant = 44;
        _topAgeTextFieldConstraint.constant = 34;
        _topOccupTextFieldConstraint.constant = 34;
        _topPersTextFieldConstraint.constant = 34;
    } else if (IPHONE_6PLUS) {
        _topNameTextFieldConstraint.constant = 54;
        _topAgeTextFieldConstraint.constant = 34;
        _topOccupTextFieldConstraint.constant = 34;
        _topPersTextFieldConstraint.constant = 34;
    }
}

- (void)showAlertSuccess {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success"
                                                        message:@"New Imaginary Friend was created"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
    if (isNewImaginaryFriend) {
        alertView.tag = 2;
    } else {
        alertView.title = @"Changes are saved.";
        alertView.message = @"";
        alertView.tag = 3;
    }
    [alertView show];
}

- (void)saveChanges {
    if (![[ReachabilityManager sharedInstance] isReachable]) {
        [Utilities showAlertViewWithTitle:@"" message:internetConnectionFailedMSG cancelButtonTitle:@"Cancel"];
        return;
    }
    if (!self.pImaginaryFriend) {
        _pImaginaryFriend = [ImaginaryFriend object];
    }
    _pImaginaryFriend.attachedToUser = [AuthorizationManager sharedInstance].currentUser;
    _pImaginaryFriend.friendName = _imaginaryFriend.friendName;
    _pImaginaryFriend.friendAge = _imaginaryFriend.friendAge;
    _pImaginaryFriend.occupation = _imaginaryFriend.occupation;
    _pImaginaryFriend.personality = _imaginaryFriend.personality;
    _pImaginaryFriend.coreDataObjectId = _imaginaryFriend.objectId;
    _pImaginaryFriend.avatarImageName = _imaginaryFriend.avatarImageName;
    _pImaginaryFriend.publicType = _imaginaryFriend.publicType;
    _pImaginaryFriend.biography = _imaginaryFriend.biography;
    if (isAvatarChanged || isNewImaginaryFriend) {
        UIImage *avatarImage = _friendAvatarImageVeiw.image;
        NSData *imgData = UIImagePNGRepresentation(avatarImage);
        PFFile *imageFile = [PFFile fileWithName:@"friendAvatar.png" data:imgData];
        _pImaginaryFriend.avatar = imageFile;
        NSString *pathToSave = [Utilities pathToImageWithName:[AuthorizationManager sharedInstance].currentCDUser.avatarImageName
                                                       userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
        [Utilities saveImage:avatarImage atPath:pathToSave];
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [[WebService sharedInstanse] saveImaginaryFriend:_pImaginaryFriend
                                     withAvatarPhoto:self.avatarImage
                                          completion:^(ResponseInfo *response) {
                                              [SVProgressHUD dismiss];
                                              if (response.error) {
                                                  $l(@" --- error - > %@", [response.error localizedDescription]);
                                              }
                                          }];
}

- (void)saveContext {
    if ([[CDManagerVersionTwo sharedInstance] saveContext]) {
        [self showAlertSuccess];
    } else {
        [Utilities showAlertViewWithTitle:@"Error!"
                                  message:@"Save to CoreData error"
                        cancelButtonTitle:@"OK"];
    }
}

@end
