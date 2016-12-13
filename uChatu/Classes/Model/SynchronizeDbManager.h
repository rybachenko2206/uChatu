//
//  SynchronizeDbManager.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/11/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SynchronizationFinished) (BOOL success, NSError *error);

@interface SynchronizeDbManager : NSObject

+ (SynchronizeDbManager *)sharedInstance;

- (void)transferDataFromOldToNewDatabaseWithComletion:(SynchronizationFinished)comletion;

@end
