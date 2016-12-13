//
//  UChatuMessage.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/13/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//
#import "PrefixHeader.pch"
#import "SharedDateFormatter.h"
#import "XMPP.h"
#import "NSXMLElement+XEP_0203.h"
#import "XMPPMessage+XEP0045.h"
#import "UChatuMessage.h"

@implementation UChatuMessage


#pragma mark - Static methods

+ (UChatuMessage *)uChatuMessageWithCDChatMessage:(CDChatMessage *)cdChatMessage
                               imaginaryFriend:(ImaginaryFriend *)imaginaryFriend {
    if (!cdChatMessage || !imaginaryFriend) {
        return nil;
    }
    UChatuMessage *msg = [UChatuMessage new];
    
    msg.cdChatMessage = cdChatMessage;
    msg.ownerImaginaryFriend = imaginaryFriend;
    
    return msg;
}


#pragma mark - Getter methods 

- (NSInteger)thumbnailHeightInteger {
    if (_thumbnailHeightInteger) {
        return _thumbnailHeightInteger;
    }
    _thumbnailHeightInteger = [self.cdChatMessage.thumbnailHeight integerValue];
    return _thumbnailHeightInteger;
}

- (NSInteger)thumbnailWidthInteger {
    if (_thumbnailWidthInteger) {
        return _thumbnailWidthInteger;
    }
    _thumbnailWidthInteger = [self.cdChatMessage.thumbnailWidth integerValue];
    return _thumbnailWidthInteger;
}


@end
