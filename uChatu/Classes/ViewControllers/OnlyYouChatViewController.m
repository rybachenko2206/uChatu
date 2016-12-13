//
//  OnlyYouChatViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/8/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>
#import "CustomUnwindSegue.h"
#import "RoundedImageView.h"
#import "OnlyYouMessageCell.h"
#import "OnlyYouAnswerCell.h"
#import "OnlyYouChatDataSouce.h"
#import "PrefixHeader.pch"
#import "CDMessage.h"
#import "CDUserSettings.h"
#import "Utilities.h"
#import "CoreDataManager.h"

#import "OnlyYouChatViewController.h"

@interface OnlyYouChatViewController () <UITableViewDelegate, UITextFieldDelegate> {
    RoundedImageView *avatarIconImageView;
    BOOL keyboardIsShown;
}

@property (nonatomic, strong, readonly) OnlyYouChatDataSouce *dataSource;

@property (weak, nonatomic) IBOutlet UIImageView *addImageView;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageViewBottomConstraint;

- (IBAction)sendButtonTapped:(id)sender;
- (IBAction)back:(id)sender;

@end


@implementation OnlyYouChatViewController

#pragma mark - Instance initialization

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (!self) {
        return nil;
    }
    _dataSource = [OnlyYouChatDataSouce new];
    
    return self;
}

-(void) viewDidLoad {
    [super viewDidLoad];
    
    [self setNavigationBarStyle];
    
    self.messageTextField.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = _dataSource;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive:)
                                                 name: UIApplicationWillResignActiveNotification
                                               object:nil];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.dataSource reloadData];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Action methods

- (IBAction)sendButtonTapped:(id)sender {
    
    [self sendMessage];
    [self scrollToBottom];
}

- (IBAction)back:(id)sender {
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


#pragma mark - Notification observers

-(void) willResignActive:(NSNotification *)notification {
    [self.messageTextField resignFirstResponder];
}

-(void) keyboardWillHide:(NSNotification *)notification {
    _addImageView.hidden = NO;
    
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
}


-(void) keyboardWillShow:(NSNotification *)notification {
    _addImageView.hidden = YES;
    
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


#pragma mark - Delegated methods - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self sendMessage];
    
    return YES;
}


#pragma mark - Delegated methods - UITableViewDelegate

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDMessage *cdMessage = self.dataSource.messages[indexPath.row];
    
    if ([self.dataSource messageCellTypeForRow:indexPath.row] == MessageCellTypeAnswer) {
        return [OnlyYouAnswerCell heightForCellWithMessage:cdMessage.message];
    } else if ([self.dataSource messageCellTypeForRow:indexPath.row] == MessageCellTypeMessage) {
        return [OnlyYouMessageCell heightForCellWithMessage:cdMessage.message];
    } else {
        $l("--- Error! Undefined celltype!");
    }
   
    return 0;
}


#pragma mark - Private methods

-(void) setNavigationBarStyle {
    self.title = @"You";
    self.navigationController.navigationBar.translucent = NO;
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName : SAVE_BUTTON_ACTIVE_COLOR,
                                 NSFontAttributeName            : NAVIGATION_BAR_TITLE_FONT};
    [self.navigationController.navigationBar setTitleTextAttributes:attributes];
    
    [self addAvatarImageToNavigationBar];
}

-(void) sendMessage {
    if (self.messageTextField.text.length == 0) {
        return;
    }
    [self.dataSource addMessage:self.messageTextField.text];
    
    self.messageTextField.text = @"";
    
    [self.dataSource reloadData];
    [self.tableView reloadData];
}

-(void) addAvatarImageToNavigationBar {
    avatarIconImageView = [[RoundedImageView alloc] initWithFrame:CGRectMake(0, 0, 37, 37)];
    [avatarIconImageView awakeFromNib];
    
    PFUser *currUser = [PFUser currentUser];
    CDUserSettings *userSettings = [[CoreDataManager sharedInstance] userSettingsWithUserId:currUser.objectId email:currUser.email];
    UIImage *image = [Utilities getUserAvatarImageForUserWithId:userSettings.userId];
    avatarIconImageView.image = image;
    UIBarButtonItem *userIcon = [[UIBarButtonItem alloc] initWithCustomView:avatarIconImageView];
    self.navigationItem.rightBarButtonItem = userIcon;
}

-(void) scrollToBottom {
    if (self.dataSource.messages.count == 0) {
        return;
    }
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataSource.messages.count-1 inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
    
}


@end
