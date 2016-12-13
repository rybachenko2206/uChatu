//
//  XMPPChatDataSource.h
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/12/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface XMPPChatDataSource : NSObject <UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSNumber *isCompanionOnline;

@end
