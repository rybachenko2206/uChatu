//
//  CustomTabBarViewController.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/3/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//



#import "AppDelegate.h"
#import "PrefixHeader.pch"
#import "NotificationButton.h"

#import "CustomTabBarViewController.h"

@interface CustomTabBarViewController ()

@property (weak, nonatomic) IBOutlet NotificationButton *notificationButton;

@end

@implementation CustomTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(unreadMessageCountChanged:)
                                                 name:kUnreadMessageCountChanged
                                               object:nil];
    self.notificationButton.hidden = YES;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}


#pragma mark - Notification observers

- (void)unreadMessageCountChanged:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[NSNumber class]]) {
        return;
    }
    
    NSUInteger msgCount = [notification.object integerValue];
    [self.notificationButton setTitle:[NSString stringWithFormat:@"%lu", (long)msgCount]
                             forState:UIControlStateNormal];
    self.notificationButton.hidden = msgCount > 0 ? NO : YES;
    
}


-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
