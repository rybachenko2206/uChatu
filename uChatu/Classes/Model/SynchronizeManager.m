//
//  SynchronizeManager.m
//  uChatu
//
//  Created by Roman Rybachenko on 2/17/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Parse/Parse.h>
#import "CDImaginaryFriend.h"
#import "ImaginaryFriend.h"
#import "PrefixHeader.pch"
#import "CDManagerVersionTwo.h"

#import "SynchronizeManager.h"


@implementation SynchronizeManager

#pragma mark - Static methods

+ (SynchronizeManager *)sharedInstance {
    static SynchronizeManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [SynchronizeManager new];
        
    });
    
    return sharedManager;
}

- (void)synchronizeLocalDbWithParse:(NSArray *)parseImFrieds completion:(void(^)(BOOL finished, NSArray *objects))comletion {
    if (!parseImFrieds.count) {
        return;
    }
    
    NSManagedObjectContext *context = [CDManagerVersionTwo sharedInstance].managedObjectContext;
    
    NSMutableArray *updatedObjectIds = [NSMutableArray new];
    for (ImaginaryFriend *imFriend in parseImFrieds) {
        NSString * objId = [CDImaginaryFriend updateCDImaginaryFriendFromParse:imFriend
                                                inContext:context];
        if (objId) {
            [updatedObjectIds addObject:objId];
        }
    }
    
    if (![[CDManagerVersionTwo sharedInstance] saveContext]) {
        $l("Save context error!");
    }
    
    comletion(YES, updatedObjectIds);
}


#pragma mark - Private methods

+ (CDImaginaryFriend *)imaginaryFriendWitnObjectId:(NSString *)objectId fromArray:(NSArray *)array {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%k == %@", objectIdKey, objectId];
    CDImaginaryFriend *imFriend = [[array filteredArrayUsingPredicate:predicate] lastObject];
    return imFriend;
}

+ (void)synchronizeParseImaginaryFriend:(ImaginaryFriend *)pImFriend withCDImaginaryFriend:(CDImaginaryFriend *)cdImFriend {
    if ([pImFriend.updatedAt compare:cdImFriend.lastUpdated] == NSOrderedSame) {
        return;
    } else {
        NSString *objId = [CDImaginaryFriend updateCDImaginaryFriendFromParse:pImFriend
                                                                    inContext:[CDManagerVersionTwo sharedInstance].managedObjectContext];
        if (!objId) {
            $l(" ---- Error");
        }
    }
}

@end
