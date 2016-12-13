//
//  SynchronizeManager.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/17/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SynchronizeManager : NSObject

+ (SynchronizeManager *)sharedInstance;
- (void)synchronizeLocalDbWithParse:(NSArray *)parseImFrieds
                         completion:(void(^)(BOOL finished, NSArray *objects))comletion;

@end
