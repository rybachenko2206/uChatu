//
//  ReachabilityManager.m
//  uChatu
//
//  Created by Roman Rybachenko on 12/15/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//


#import "Reachability.h"
#import "PrefixHeader.pch"

#import "ReachabilityManager.h"

@implementation ReachabilityManager

#pragma mark Static methods

+(instancetype) sharedInstance {
    static ReachabilityManager *reachabilityManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reachabilityManager = [[ReachabilityManager alloc] init];
    });
    
    return reachabilityManager;
}


#pragma mark - Interface methods

-(BOOL) isReachable {
    [ReachabilityManager sharedInstance].reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus nwStatus = [[ReachabilityManager sharedInstance].reachability currentReachabilityStatus];
    return nwStatus == NotReachable ? NO : YES;
}



@end
