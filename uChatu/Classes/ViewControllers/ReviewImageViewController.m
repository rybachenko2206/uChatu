//
//  ReviewImageViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/6/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "ShareManager.h"
#import "AppDelegate.h"
#import "Utilities.h"
#import "Complaint.h"
#import "WebService.h"
#import "AuthorizationManager.h"
#import "PrefixHeader.pch"

#import "ReviewImageViewController.h"


@interface ReviewImageViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
@property (weak, nonatomic) IBOutlet UIButton *bottomShareButtonOutlet;

- (IBAction)imageWasTapped:(id)sender;
- (IBAction)shareButtonTapped:(id)sender;

@end


@implementation ReviewImageViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.backButtonItem;
//    self.navigationItem.rightBarButtonItem = self.shareBarButtonItem;
    
    _imageView.image = self.imageForReview;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.screenIsPortraitOnly = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.screenIsPortraitOnly = YES;
}


#pragma mark - Action methods
- (IBAction)shareBarButtonWasTapped:(id)sender {
    NSString *destructiveButtonTitle = nil;
    if (self.imFriend) {
        destructiveButtonTitle = @"Report Inappropriate";
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:destructiveButtonTitle
                                                    otherButtonTitles:@"Save Image", @"Share on Facebook", @"Share on Twitter", @"Send by Email", nil];
    [actionSheet showInView:self.view];
}

- (IBAction)backButtonTapped:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.screenIsPortraitOnly = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)imageWasTapped:(id)sender {
//    [self backButtonTapped:nil];
//    [self shareBarButtonWasTapped:nil];
}

- (IBAction)shareButtonTapped:(id)sender {
    [self shareBarButtonWasTapped:nil];
}


#pragma mark - Delegated methods:
#pragma mark - —UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.imFriend) {
        switch (buttonIndex) {
            case 0: {
                Complaint *complaintObj = [Complaint object];
                complaintObj.reporter = [AuthorizationManager sharedInstance].currentUser;
                complaintObj.photo = self.avatarPhoto ? self.avatarPhoto : self.imFriend.avatarPhoto;
                
                [[WebService sharedInstanse] sendComplaint:complaintObj completion:^(ResponseInfo *response) {
                    if (response.success) {
                        [Utilities showAlertViewWithTitle:@""
                                                  message:kThanksForComplaintMSG
                                        cancelButtonTitle:@"OK"];
                    }
                }];
                break;
            }  
                
            case 1:
                UIImageWriteToSavedPhotosAlbum(_imageForReview, nil, nil, nil);
                break;
                
            case 2:
                [[ShareManager sharedInstance] shareToFacebookFromViewController:self];
                break;
                
            case 3:
                [[ShareManager sharedInstance] shareToTwitterFromViewController:self];
                break;
                
            case 4:
                [[ShareManager sharedInstance] shareWithEmailFromViewController:self
                                                                  withComplaint:NO
                                                                  attachedImage:_imageForReview
                                                                    messageText:@""];;
                break;
                
            default:
                break;
        }
    } else {
        switch (buttonIndex) {
            case 0:
                UIImageWriteToSavedPhotosAlbum(_imageForReview, nil, nil, nil);
                break;
                
            case 1:
                [[ShareManager sharedInstance] shareToFacebookFromViewController:self];
                break;
                
            case 2:
                [[ShareManager sharedInstance] shareToTwitterFromViewController:self];
                break;
                
            case 3:
                [[ShareManager sharedInstance] shareWithEmailFromViewController:self
                                                                  withComplaint:NO
                                                                  attachedImage:_imageForReview
                                                                    messageText:@""];;
                break;
                
            default:
                break;
        }
    }
    
    
}

@end
