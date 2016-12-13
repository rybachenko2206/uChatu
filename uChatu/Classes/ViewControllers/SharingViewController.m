//
//  SharingViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/1/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//



#import "PrefixHeader.pch"
#import "Utilities.h"
#import "ShareManager.h"

#import "SharingViewController.h"

@interface SharingViewController () {
    UIBarButtonItem *leftBarButtonItem;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topEmailButtonConstraint;
@property (weak, nonatomic) IBOutlet UIButton *messageButtonOutlet;

- (IBAction)emailButtonTapped:(id)sender;
- (IBAction)messageButtonTapped:(id)sender;
- (IBAction)twitterButtonTapped:(id)sender;
- (IBAction)facebookButtonTapped:(id)sender;

@end

@implementation SharingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Share";
    
    leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nvg_backModally_button_image"]
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(backButtonTapped)];
    leftBarButtonItem.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    [self updateConstraintsIfNeeded];
}


#pragma mark - Action methods

-(void) backButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)emailButtonTapped:(id)sender {
    [[ShareManager sharedInstance] shareWithEmailFromViewController:self
                                                      withComplaint:NO
                                                      attachedImage:nil
                                                        messageText:@"Check out uChatu app. It is a new and awesome app. Download it today from http://uchatu.com"];
}

- (IBAction)messageButtonTapped:(id)sender {
    [[ShareManager sharedInstance] sendMessageFromViewController:self];
}

- (IBAction)twitterButtonTapped:(id)sender {
    [[ShareManager sharedInstance] shareToTwitterFromViewController:self];
}

- (IBAction)facebookButtonTapped:(id)sender {
    [[ShareManager sharedInstance] shareToFacebookFromViewController:self];
}


#pragma mark - Private methods

-(void) updateConstraintsIfNeeded {
    if (IPHONE_4) {
        _topEmailButtonConstraint.constant = 100;
    } else if (IPHONE_6 || IPHONE_6PLUS) {
        _topEmailButtonConstraint.constant = 200;
    }
}

@end
