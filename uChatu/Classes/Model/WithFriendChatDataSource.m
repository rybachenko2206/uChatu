//
//  WithFriendChatDataSource.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/10/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import <Parse/Parse.h>
#import "OnlyYouMessageCell.h"
#import "FriendMessageCell.h"
#import "CoreDataManager.h"
#import "CDMessage.h"
#import "CDImaginaryFriend.h"
#import "AuthorizationManager.h"
#import "SharedDateFormatter.h"
#import "CDChatRoom.h"
#import "CDChatMessage.h"
#import "ReviewImageViewController.h"
#import "CDPhoto.h"

#import "WithFriendChatDataSource.h"


@interface WithFriendChatDataSource () {
    
}

@property (nonatomic, strong, readwrite) NSArray *messages;
@end


@implementation WithFriendChatDataSource

#pragma mark - Instance initialization

-(instancetype) init {
    self = [super init];
    
    if (!self) {
        return nil;
    }
//    PFUser *currUser = [PFUser currentUser];
//    _userSettings = [[CoreDataManager sharedInstance] userSettingsWithUserId:currUser.objectId email:currUser.email];
    
    return self;
}


#pragma mark - Delegated methods - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messages count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDChatMessage *cdMessage = [self.messages objectAtIndex:indexPath.row];
    MessageType mType = [cdMessage.messageType integerValue];
    static NSString *friendCellIdentifier = @"FriendMessageCell";
    static NSString *userCellIdentifier = @"OnlyYouMessageCell";
    CDImaginaryFriend *imaginaryFriend = [self.chatRoom.imaginaryFriends anyObject];
    if ([imaginaryFriend.lastOpenedChatAsUser boolValue]) {
        
        if (mType == MessageTypeFriendToUser) {
            FriendMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:friendCellIdentifier forIndexPath:indexPath];
            [cell setContentWithCDChatMessage:cdMessage imaginaryFriend:imaginaryFriend];
            return cell;
        } else if (mType == MessageTypeUserToFriend) {
            OnlyYouMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:userCellIdentifier forIndexPath:indexPath];
            [cell setContentWithCDChatMessage:cdMessage];
            return cell;
        } else {
            $l("--- Error! Wrong messageType!");
        }
        
    } else {
        
        if (mType == MessageTypeFriendToUser) {
            OnlyYouMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:userCellIdentifier forIndexPath:indexPath];
            [cell setContentWithCDChatMessage:cdMessage];
            return cell;
        } else if (mType == MessageTypeUserToFriend) {
            FriendMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:friendCellIdentifier forIndexPath:indexPath];
            [cell setContentWithCDChatMessage:cdMessage imaginaryFriend:imaginaryFriend];
            return cell;
        } else {
            $l("--- Error! Wrong messageType!");
        }
        
    }
    return nil;
}


#pragma mark - Interface methods

- (void)reloadData {
    self.messages = [self.chatRoom.messages allObjects];
    if (self.messages.count) {
        NSSortDescriptor *sortDescr = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
        self.messages = [self.messages sortedArrayUsingDescriptors:@[sortDescr]];
    }
}

- (void)addMessage:(NSString *)message
       messageType:(MessageType)messageType
          chatRoom:(CDChatRoom *)chatRoom
   imaginaryFriend:(CDImaginaryFriend *)imaginaryFriend
     attachedImage:(UIImage *)attachImg {
    
    NSDate *createdDate = [SharedDateFormatter dateForLastModifiedFromDate:[NSDate date]];
    [[CDManagerVersionTwo sharedInstance] insertNewMessageWithMessageText:message
                                                              messageType:messageType
                                                                createdAt:createdDate
                                                                 chatRoom:chatRoom
                                                            attachedImage:attachImg
                                                       forImaginaryFriend:imaginaryFriend];
}

@end
