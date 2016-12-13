//
//  ChatsListViewController.h
//  uChatu
//
//  Created by Roman Rybachenko on 11/19/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <UIKit/UIKit.h>


@interface ChatsListViewController : UIViewController

@property (nonatomic, assign, readonly) BOOL isEditing;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
