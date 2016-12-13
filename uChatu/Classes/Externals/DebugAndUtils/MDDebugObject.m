//
//  MDDebugObject.m
//  MoziFramework
//
//  Created by s.zalozniy on 10/1/13.
//  Copyright (c) 2013 Mozi Development. All rights reserved.
//

#import "MDDebug.h"

#import "MDDebugObject.h"


#if __has_feature(objc_arc)
#error You need to disable ARC for MDDebugObject.
#endif


@interface MDDebugObject()

@property (nonatomic, assign) CFAbsoluteTime startTime;

@property (nonatomic, strong) NSString *classCaller;
@property (nonatomic, strong) NSString *functionCaller;
@property (nonatomic, assign) NSInteger lineNumber;

@end


@implementation MDDebugObject

#pragma mark - Instance initialization

-(instancetype) intitWith:(NSInteger)lineNumber {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.classCaller = [self getClassCaller];
    self.functionCaller = [self getFunctionCaller];
    self.lineNumber = lineNumber;
    self.startTime = CFAbsoluteTimeGetCurrent();
    
    PRINTFUNCTION(COLOR_NO, "%30s : %-4d ~~ Start             - %s", [self.classCaller UTF8String], self.lineNumber, [self.functionCaller UTF8String]);
    
    return self;
}


#pragma mark - Overridden methods

-(oneway void) release {
    if (self.retainCount == 1) {
        PRINTFUNCTION(COLOR_NO, "%30s : %-4d ~~ Finished in %.3f - %s", [self.classCaller UTF8String], self.lineNumber, CFAbsoluteTimeGetCurrent() - self.startTime, [self.functionCaller UTF8String]);
    }
    
    [super release];
}


#pragma mark - Static methods

-(NSString *) getClassCaller {
    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:2];
// Example: 1   UIKit                               0x00540c89 -[UIApplication _callInitializationDelegatesForURL:payload:suspended:] + 1163
    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
    [array removeObject:@""];
    
    return [[array objectAtIndex:3] stringByAppendingString:@".m"];
}


-(NSString *) getFunctionCaller {
    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:2];
    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
    [array removeObject:@""];
    
    return [array objectAtIndex:4];
}


@end
