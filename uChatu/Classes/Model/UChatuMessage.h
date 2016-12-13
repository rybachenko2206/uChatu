//
//  UChatuMessage.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/13/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

@class ImaginaryFriend;
@class ChatRoom;
@class XMPPMessage;


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "CDChatMessage.h"

@interface UChatuMessage : NSObject

@property (nonatomic, strong) CDChatMessage *cdChatMessage;
@property (nonatomic, strong) ImaginaryFriend *ownerImaginaryFriend;
@property (nonatomic, assign) NSInteger thumbnailWidthInteger;
@property (nonatomic, assign) NSInteger thumbnailHeightInteger;

+ (UChatuMessage *)uChatuMessageWithCDChatMessage:(CDChatMessage *)cdChatMessage
                                  imaginaryFriend:(ImaginaryFriend *)imaginaryFriend;


@end
