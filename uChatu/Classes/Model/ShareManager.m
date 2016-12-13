//
//  ShareManager.m
//  uChatu
//
//  Created by Roman Rybachenko on 7/18/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import "PrefixHeader.pch"
#import "Utilities.h"

#import "ShareManager.h"

@interface ShareManager () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) SLComposeViewController *composeController;
@property (nonatomic, strong) MFMailComposeViewController *mailComposeViewController;

@end


@implementation ShareManager

#pragma mark - Static methods

+ (ShareManager *)sharedInstance {
    static ShareManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [ShareManager new];
        sharedManager.composeController = [[SLComposeViewController alloc] init];
        sharedManager.mailComposeViewController = [[MFMailComposeViewController alloc] init];
        sharedManager.mailComposeViewController.mailComposeDelegate = (id<MFMailComposeViewControllerDelegate>)self;
        [sharedManager fillSLComposeViewController];

    });
    
    return sharedManager;
}

-(void) fillSLComposeViewController {
    [self.composeController setInitialText:@"Check out uChatu app. It is a new and awesome app. Download it today from uchatu.com"];
    [self.composeController addImage:[UIImage imageNamed:@"shr_socialShare_image"]];
    [self.composeController addURL:[NSURL URLWithString:@"http://uchatu.com"]];
}


#pragma mark - Delegated methods - MFMessageComposeViewControllerDelegate

-(void) messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result {
    NSString *successMessage = nil;
    switch (result) {
        case MessageComposeResultCancelled:
        {
            successMessage = @"Message Cancelled";
            break;
        }
        case MessageComposeResultSent:
        {
            successMessage = @"Message sent";
            break;
        }
        case MessageComposeResultFailed:
        {
            successMessage = @"Message Failed";
            break;
        }
            
        default:
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
    [Utilities showAlertViewWithTitle:@""
                              message:successMessage
                    cancelButtonTitle:@"OK"];
}

-(void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    NSString *successMessage = nil;
    switch (result) {
        case MFMailComposeResultCancelled:
            successMessage = @"Email Cancelled";
            $l("--- MFMailComposeResultCancelled");
            break;
        case MFMailComposeResultSaved:
            successMessage = @"Email Saved";
            $l("--- MFMailComposeResultSaved");
            break;
        case MFMailComposeResultSent:
            successMessage = @"Email Sent";
            $l("--- MFMailComposeResultSent");
            break;
        case MFMailComposeResultFailed:
            successMessage = @"Email Failed";
            $l("--- MFMailComposeResultFailed");
            break;
        default:
            $l("--- Email Not Sent");
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
    [Utilities showAlertViewWithTitle:@""
                              message:successMessage
                    cancelButtonTitle:@"OK"];
}


#pragma mark - Interface methods

- (void)shareWithEmailFromViewController:(UIViewController *)viewController withComplaint:(BOOL)isComplaint attachedImage:(UIImage *)attachedImage messageText:(NSString *)text {
    if (![MFMailComposeViewController canSendMail]) {
        [Utilities showAlertViewWithTitle:@""
                                  message:@"Your device doesn’t send email message!"
                        cancelButtonTitle:@"OK"];
        return ;
    }
    _mailComposeViewController = [[MFMailComposeViewController alloc] init];
    _mailComposeViewController.mailComposeDelegate = (id<MFMailComposeViewControllerDelegate>)self;
    
    NSString *emailSubject = @"uChatu";
    
    if (isComplaint) {
        NSArray *recipients = @[@"r.rybachenko@mozidev.com", @"rom_rybachenko@ukr.net"];
        //        NSArray *recipients = @[reportEmail];
        [_mailComposeViewController setToRecipients:recipients];
        
        emailSubject = @"uChatu, Report Inappropriate";
    }
    
    [_mailComposeViewController setSubject:emailSubject];
    
    if (text) {
        [_mailComposeViewController setMessageBody:text isHTML:YES];
    }
    
    if (attachedImage) {
        [_mailComposeViewController addAttachmentData:(UIImagePNGRepresentation(attachedImage))
                                             mimeType:@"image/png"
                                             fileName:[NSString stringWithFormat:@"%@.png", [Utilities getNewGUID]]];
    }
    
    
    [viewController presentViewController:_mailComposeViewController
                                 animated:YES
                               completion:nil];
    
}

- (void)sendMessageFromViewController:(UIViewController *)viewController {
    if(![MFMessageComposeViewController canSendText]) {
        [Utilities showAlertViewWithTitle:@"" message:@"Your device doesn't support SMS!" cancelButtonTitle:@"OK"];
        $l("--- MFMessageComposeViewController can not Send SMS ");
        return ;
    }
    
    NSString *message = @"Check out uChatu app. It is a new and awesome app. Download it today from http://uchatu.com";
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setBody:message];
    
    [viewController presentViewController:messageController animated:YES completion:nil];
}

- (void)shareToTwitterFromViewController:(UIViewController *)viewController {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        self.composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [self.composeController setInitialText:@"Check out uChatu app. It is a new and fun app. Download it today from uchatu.com"];
        [self.composeController addImage:[UIImage imageNamed:@"shr_socialShare_image"]];
        [viewController presentViewController:self.composeController animated:YES completion:nil];
        
        //        [self.composeController setCompletionHandler:^(SLComposeViewControllerResult result) {
        //            [Utilities handlePostResult:result];
        //        }];
        
    } else {
        NSString *cannotMessage = twitterCantPostMSG;
        [Utilities showAlertViewWithTitle:@"" message:cannotMessage cancelButtonTitle:@"OK"];
    }
}

- (void)shareToFacebookFromViewController:(UIViewController *)viewController {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        self.composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [self fillSLComposeViewController];
        [viewController presentViewController:self.composeController animated:YES completion:nil];
        
        //        [self.composeController setCompletionHandler:^(SLComposeViewControllerResult result) {
        //            [Utilities handlePostResult:result];
        //        }];
    } else {
        NSString *message = fbCantPostMSG;
        [Utilities showAlertViewWithTitle:@"" message:message cancelButtonTitle:@"OK"];
    }
}

@end
