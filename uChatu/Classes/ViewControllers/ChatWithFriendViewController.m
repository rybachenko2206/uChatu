//
//  ChatWithFriendViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/10/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import "RoundedImageView.h"
#import "OnlyYouMessageCell.h"
#import "FriendMessageCell.h"
#import "PrefixHeader.pch"
#import "CDMessage.h"
#import "NotificationButton.h"
#import "WithFriendChatDataSource.h"
#import "CDUserSettings.h"
#import "AuthorizationManager.h"
#import "CDManagerVersionTwo.h"
#import "CDChatRoom.h"
#import "ImagePickerManager.h"
#import "CDPhoto.h"
#import "ReviewImageViewController.h"
#import "UIStoryboard+Multiple.h"

#import "ChatWithFriendViewController.h"


@interface ChatWithFriendViewController () <UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, ImagePickerDelegate> {
    RoundedImageView *avatarIconImageView;
    BOOL keyboardIsShown;
}


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoButtonRightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *photoButtonOutlet;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageTFRightConstraint;

@property (nonatomic, assign) NSInteger friendUnreadMessagesCount;
@property (nonatomic, assign) NSInteger youUnreadMessagesCount;

@property (nonatomic, strong) CDImaginaryFriend *imaginaryFriend;
@property (nonatomic, strong) UIImage *addedImage;

@property (nonatomic, strong, readonly) WithFriendChatDataSource *dataSource;

@property (strong, nonatomic) UIActionSheet *addPhotoActionSheet;

@property (weak, nonatomic) IBOutlet UIImageView *addImageVew;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *imaginaryFriendLabelOutlet;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imagFrNotifButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *yourNotifButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *youLabelCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imFrNameLabelCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageViewBottomConstraint;

@property (weak, nonatomic) IBOutlet NotificationButton *yourNotificationButtonOutlet;
@property (weak, nonatomic) IBOutlet NotificationButton *imaginaryFriendsNotifButtonOutlet;

@property (weak, nonatomic) IBOutlet UIButton *imaginaryFriendTabButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *youTabButtonOutlet;
@property (nonatomic) ImagePickerManager *imagePicker;

- (IBAction)backButtonTapped:(id)sender;
- (IBAction)imaginaryFriendButtonTapped:(id)sender;
- (IBAction)youButtonTapped:(id)sender;
- (IBAction)sendButtonTapped:(id)sender;
- (IBAction)addPhotoButtonTapped:(id)sender;
- (IBAction)tableViewWasTapped:(id)sender;

@end


@implementation ChatWithFriendViewController

#pragma mark - Instance initialization

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (!self) {
        return nil;
    }
    _dataSource = [[WithFriendChatDataSource alloc] init];
    self.friendUnreadMessagesCount = 0;
    self.youUnreadMessagesCount = 0;
    
    self.imagePicker = [[ImagePickerManager alloc] init];
    self.imagePicker.delegate = self;
    
    return self;
}


#pragma mark - Interface methods

-(void) viewDidLoad {
    [super viewDidLoad];
    
    self.imaginaryFriend = [self.chatRoom.imaginaryFriends anyObject];
    if (!self.imaginaryFriend.lastOpenedChatAsUser || [self.imaginaryFriend.lastOpenedChatAsUser boolValue]) {
        self.imaginaryFriend.lastOpenedChatAsUser = @(YES);
        [self youButtonTapped:nil];
    } else {
        [self imaginaryFriendButtonTapped:nil];
    }
    
    [self setNavigationBarStyle];
    [self updateConstraintsIfNeeded];
    
    
    self.messageTextField.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = _dataSource;
    _dataSource.chatRoom = self.chatRoom;
    
    _imaginaryFriendLabelOutlet.text = _imaginaryFriend.friendName.length > 0 ? _imaginaryFriend.friendName : @"Imaginary Friend";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive:)
                                                 name: UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userAvatarIsDownloaded:)
                                                 name:kAvatarImageWasDownloaded
                                               object:nil];
}


-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(attachedImageWasTapped:)
                                                 name:kAttachedImageWasTappedNotification
                                               object:nil];
    
    [self.dataSource reloadData];
    [self updateNotificationButtonsTitle];
    
    if (_messageTextField.text.length >= 1) {
        _addImageVew.hidden = YES;
    }
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(keyboardWillShow:)
                          name:UIKeyboardWillShowNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(keyboardWillHide:)
                          name:UIKeyboardWillHideNotification
                        object:nil];
    
    [self scrollToBottom];
}


-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self
                             name:UIKeyboardWillShowNotification
                           object:nil];
    
    [defaultCenter removeObserver:self
                             name:UIKeyboardWillHideNotification
                           object:nil];
    
    [[CDManagerVersionTwo sharedInstance] saveContext];
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}


#pragma mark - Action methods

-(IBAction) backButtonTapped:(id)sender {
    if ([_messageTextField isFirstResponder]) {
        [_messageTextField resignFirstResponder];
        double delay = 0.35;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES
                                     completion:nil];
        });
    } else {
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
    }
}

- (IBAction)imaginaryFriendButtonTapped:(id)sender {
    [_imaginaryFriendTabButtonOutlet setBackgroundImage:[UIImage imageNamed:@"cht_selectedTabBackground_image"]
                                                  forState:UIControlStateNormal];
    [_youTabButtonOutlet setBackgroundImage:nil
                                   forState:UIControlStateNormal];
    _imaginaryFriend.lastOpenedChatAsUser = @(NO);
    [[CDManagerVersionTwo sharedInstance] saveContext];
    [self updateInfoAtNavigationBar];
    
    self.friendUnreadMessagesCount = 0;
    [self updateNotificationButtonsTitle];
    
    [self.messageTextField resignFirstResponder];
    
    [self.dataSource reloadData];
    [self.tableView reloadData];
    _messageTextField.text = @"";
}

- (IBAction)youButtonTapped:(id)sender {
    [_imaginaryFriendTabButtonOutlet setBackgroundImage:nil
                                               forState:UIControlStateNormal];
    [_youTabButtonOutlet setBackgroundImage:[UIImage imageNamed:@"cht_selectedTabBackground_image"]
                                   forState:UIControlStateNormal];
    _imaginaryFriend.lastOpenedChatAsUser = @(YES);
    [self updateInfoAtNavigationBar];
    
    self.youUnreadMessagesCount = 0;
    [self updateNotificationButtonsTitle];
    
    [self.messageTextField resignFirstResponder];
    
    [self.dataSource reloadData];
    [self.tableView reloadData];
    _messageTextField.text = @"";
}

- (IBAction)sendButtonTapped:(id)sender {
    [self showPhotoButtonAnimated];
    [self sendMessage];
    [self scrollToBottom];
}

- (IBAction)addPhotoButtonTapped:(id)sender {
    self.addPhotoActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:@"Take Picture", @"Choose Picture", nil];
    [self.addPhotoActionSheet showInView:self.view];
}

- (IBAction)tableViewWasTapped:(id)sender {
    [self hideKeyboardIfTableViewWasTapped];
}


#pragma mark - Notification observers

- (void)userAvatarIsDownloaded:(NSNotification *)notification {
    [self updateInfoAtNavigationBar];
}

-(void) willResignActive:(NSNotification *)notification {
    [self.messageTextField resignFirstResponder];
}

-(void) keyboardWillHide:(NSNotification *)notification {
    _addImageVew.hidden = NO;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3f
                     animations:^{
                         weakSelf.messageViewBottomConstraint.constant = 0;
                         [weakSelf.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [self scrollToBottom];
                     }];
    
    keyboardIsShown = NO;
    if (_photoButtonOutlet.alpha == 0) {
        [self showPhotoButtonAnimated];
    }
}

-(void) keyboardWillShow:(NSNotification *)notification {
    _addImageVew.hidden = YES;
    
    NSDictionary* userInfo = [notification userInfo];
    
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat constantValue = keyboardSize.height;
    
    NSTimeInterval animationDuration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateKeyframesWithDuration:animationDuration
                                   delay:0.0
                                 options:curve
                              animations:^{
                                  weakSelf.messageViewBottomConstraint.constant = constantValue;
                                  [weakSelf.view layoutIfNeeded];
                              }
                              completion:^(BOOL finished){
                                  [self scrollToBottom];
                              }];
    
    keyboardIsShown = YES;
}

- (void)attachedImageWasTapped:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[CDPhoto class]]) {
        return;
    }
    CDPhoto *photo = notification.object;
    
    ReviewImageViewController *reviewImageVC = [[UIStoryboard chats] instantiateViewControllerWithIdentifier:@"ReviewImageViewController"];
    UIImage *image = [Utilities getImageWithName:photo.fullPhotoName];
    reviewImageVC.imageForReview = image;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:reviewImageVC];
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - Delegated methods:

#pragma mark - —UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self hideKeyboardIfTableViewWasTapped];
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDChatMessage *message = self.dataSource.messages[indexPath.row];
    MessageType mType = [message.messageType integerValue];
    
    if ([_imaginaryFriend.lastOpenedChatAsUser boolValue]) {
        if (mType == MessageTypeUserToFriend) {
            return [OnlyYouMessageCell heightForCellWithMessage:message];
        } else if (mType == MessageTypeFriendToUser) {
            return [FriendMessageCell heightForCellWithMessage:message];
        } else {
            $l("--- Error! Wrong message type");
        }
    } else {
        if (mType == MessageTypeUserToFriend) {
            return [FriendMessageCell heightForCellWithMessage:message];
        } else if (mType == MessageTypeFriendToUser) {
            return [OnlyYouMessageCell heightForCellWithMessage:message];
        } else {
            $l("--- Error! Wrong message type");
        }
    }
    
    return 0;
}


#pragma mark - —UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self hidePhotoButtonAnimated];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self hidePhotoButtonAnimated];
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
    NSString *trimmedString = [textField.text stringByTrimmingCharactersInSet:charSet];
    if ([trimmedString isEqualToString:@""]) {
        textField.text = @"";
    }
    
    [self showPhotoButtonAnimated];
    [self sendMessage];
    
    return YES;
}

#pragma mark - —UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // take picture with camera
        [self.imagePicker createImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera
                                                  forViewController:self];
    } else if (buttonIndex == 1) {
        // choose picture from Camera Roll
        [self.imagePicker createImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                                  forViewController:self];
    }
}

#pragma mark - —ImagePickerDelegate

-(void) imagePickerChoseImage:(UIImage *)image {
    self.addedImage = image;
    [self sendMessage];
}


#pragma mark - Private methods

- (void)hideKeyboardIfTableViewWasTapped {
    if (![_messageTextField isFirstResponder]) {
        return;
    }
    _messageTextField.text = @"";
    [_messageTextField resignFirstResponder];
    [self showPhotoButtonAnimated];
}

-(void) addMessageNotification {
    if ([_imaginaryFriend.lastOpenedChatAsUser boolValue]) {
        self.friendUnreadMessagesCount ++;
    } else {
        self.youUnreadMessagesCount ++;
    }
    [self updateNotificationButtonsTitle];
}

-(void) updateNotificationButtonsTitle {
    [self.yourNotificationButtonOutlet setNotificationCount:_youUnreadMessagesCount];
    [self.imaginaryFriendsNotifButtonOutlet setNotificationCount:_friendUnreadMessagesCount];
}

-(void) sendMessage {
    if (!self.messageTextField.text.length && !self.addedImage) {
        return;
    }
    [self showPhotoButtonAnimated];
    MessageType mesgType = [_imaginaryFriend.lastOpenedChatAsUser boolValue] ? MessageTypeUserToFriend : MessageTypeFriendToUser;
    [self.dataSource addMessage:self.messageTextField.text
                    messageType:mesgType
                       chatRoom:self.chatRoom
                imaginaryFriend:_imaginaryFriend
                  attachedImage:_addedImage];
    
    self.messageTextField.text = @"";
    self.addedImage = nil;
    
    [self addMessageNotification];
    
    [self.dataSource reloadData];
    [self.tableView reloadData];
}


-(void) setNavigationBarStyle {
    self.title = @"You";
    self.navigationController.navigationBar.translucent = NO;
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName : SAVE_BUTTON_ACTIVE_COLOR,
                                 NSFontAttributeName            : NAVIGATION_BAR_TITLE_FONT};
    [self.navigationController.navigationBar setTitleTextAttributes:attributes];
    
    [self updateInfoAtNavigationBar];
}

-(void) updateInfoAtNavigationBar {
    if (!avatarIconImageView) {
        avatarIconImageView = [[RoundedImageView alloc] initWithFrame:CGRectMake(0, 0, 37, 37)];
        [avatarIconImageView awakeFromNib];
    }
    
    if ([_imaginaryFriend.lastOpenedChatAsUser boolValue]) {
        self.title = @"You";
        NSString *imgName = _imaginaryFriend.user.avatarImageName;
        UIImage *image = [Utilities getImageWithName:imgName];
        if (!image) {
            image = [AuthorizationManager sharedInstance].userAvatarImage;
        }
        avatarIconImageView.image = image;
    } else {
        NSString *friendsName = _imaginaryFriend.friendName;
        self.title = friendsName.length > 1 ? friendsName : @"Imaginary friend";
        NSString *path = [Utilities pathToImageWithName:_imaginaryFriend.avatarImageName
                                                       userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
        UIImage *image = [Utilities getAvatarImageAtPath:path];
        image = image ? image : [UIImage imageNamed:@"cht_emptyAvatar_image"];
        avatarIconImageView.image = image;
    }
    
    UIBarButtonItem *userIcon = [[UIBarButtonItem alloc] initWithCustomView:avatarIconImageView];
    self.navigationItem.rightBarButtonItem = userIcon;
}

-(void) updateConstraintsIfNeeded {
    if (IPHONE_6PLUS) {
        _imFrNameLabelCenterXConstraint.constant = 122;
        _youLabelCenterXConstraint.constant = -105;
    } else if (IPHONE_6) {
        _imFrNameLabelCenterXConstraint.constant = 110;
        _youLabelCenterXConstraint.constant = -85;
    }
}

-(void) scrollToBottom {
    if (self.dataSource.messages.count == 0) {
        return;
    }
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataSource.messages.count-1 inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
    
}

- (void)hidePhotoButtonAnimated {
    [UIView animateWithDuration:0.5 animations:^{
        _photoButtonRightConstraint.constant = -44;
        _messageTFRightConstraint.constant = 4;
        [self.view layoutIfNeeded];
        _photoButtonOutlet.alpha = 0;
    }];
}

- (void)showPhotoButtonAnimated {
    [UIView animateWithDuration:0.5 animations:^{
        _messageTFRightConstraint.constant = 50;
        _photoButtonRightConstraint.constant = 2;
        [self.view layoutIfNeeded];
        _photoButtonOutlet.alpha = 1;
    }];
}

@end
