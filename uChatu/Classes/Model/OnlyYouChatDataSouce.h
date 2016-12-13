//
//  OnlyYouChatDataSouce.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/9/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import "PrefixHeader.pch"



@interface OnlyYouChatDataSouce : NSObject <UITableViewDataSource>

@property (nonatomic, strong, readonly) NSArray *messages;

-(void) reloadData;
-(void) addMessage:(NSString *)message;
-(MessageCellType) messageCellTypeForRow:(NSInteger)row;

@end
