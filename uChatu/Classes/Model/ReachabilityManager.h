//
//  ReachabilityManager.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/15/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

@class Reachability;

#import <Foundation/Foundation.h>


@interface ReachabilityManager : NSObject

@property (strong, nonatomic) Reachability *reachability;

+(instancetype) sharedInstance;

-(BOOL) isReachable;


@end
