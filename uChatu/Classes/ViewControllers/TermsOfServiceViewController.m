//
//  TermsOfServiceViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/13/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import "TermsOfServiceViewController.h"

@interface TermsOfServiceViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation TermsOfServiceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    if (self.isTermsOfService) {
        self.title = @"Terms Of Service";
    } else if (self.isPrivacy) {
        self.title = @"Privacy";
    }
    
    UIBarButtonItem *backBtnItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nvg_backModally_button_image"]
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(backButtonItemTapped)];
    backBtnItem.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = backBtnItem;
    
    [self loadContentToWebView];
}


#pragma mark - Action methods

-(void) backButtonItemTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Delegated methods - UITextViewDelegate

-(BOOL) textViewShouldBeginEditing:(UITextView *)textView {
    return NO;
}


#pragma mark - Private methods

-(void) loadContentToWebView {
    NSURL *url = nil;
    if (self.isTermsOfService) {
        url = [[NSBundle mainBundle] URLForResource:@"Terms_of_Use_uChatu_v3" withExtension:@"html"];
    } else if (self.isPrivacy) {
        url = [[NSBundle mainBundle] URLForResource:@"Privacy_uChatu_v3" withExtension:@"html"];
    }
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

@end
