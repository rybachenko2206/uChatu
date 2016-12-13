//
//  OnlyYouChatDataSouce.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/9/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>
#import "OnlyYouMessageCell.h"
#import "OnlyYouAnswerCell.h"
#import "CoreDataManager.h"
#import "CDMessage.h"

#import "OnlyYouChatDataSouce.h"

@interface OnlyYouChatDataSouce ()

@property (nonatomic, strong, readwrite) NSArray *messages;

@end


@implementation OnlyYouChatDataSouce

#pragma mark - Instance initialization

-(instancetype) init {
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    return self;
}

#pragma mark - Delegated methods - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messages count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDMessage *cdMessage = self.messages[indexPath.row];
    if ([self messageCellTypeForRow:indexPath.row] == MessageCellTypeMessage) {
        OnlyYouMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OnlyYouMessageCell" forIndexPath:indexPath];
        $l(" --- cell.messageLabel.frame = %@", NSStringFromCGRect(cell.messageLabel.frame));
        $l("isMessgLabelHidden = %d", cell.messageLabel.hidden);
//        [cell setContentWithCDMessage:cdMessage];
        
        return cell;
    } else if ([self messageCellTypeForRow:indexPath.row] == MessageCellTypeAnswer) {
        OnlyYouAnswerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OnlyYouAnswerCell" forIndexPath:indexPath];
        [cell setContentWithCDMessage:cdMessage];
        
        return cell;
    } else {
        $l("--- Error! Undefined celltype!");
    }
    
    return nil;
}


#pragma mark - Interface methods

-(void) reloadData {
    PFUser *currUser = [PFUser currentUser];
    self.messages = [[CoreDataManager sharedInstance] getAllMessagesForUserId:currUser.objectId
                                                                  messageType:MessageTypeUserToUser];
}

-(void) addMessage:(NSString *)message {
    PFUser *cUser = [PFUser currentUser];
    
    [[CoreDataManager sharedInstance] insertNewMessageWithUserId:cUser.objectId
                                                     messageText:message
                                                     messageType:MessageTypeUserToUser
                                                       createdAt:[NSDate date]];
}


-(MessageCellType) messageCellTypeForRow:(NSInteger)row {
    MessageCellType messageCellType = MessageCellTypeUndefined;
    NSInteger count = self.messages.count;
    if (count % 2 == 0) {
        messageCellType = row % 2 == 1 ? MessageCellTypeMessage : MessageCellTypeAnswer;
    } else {
        messageCellType = row % 2 == 0 ? MessageCellTypeMessage : MessageCellTypeAnswer;
    }
    
    return messageCellType;
}


@end
