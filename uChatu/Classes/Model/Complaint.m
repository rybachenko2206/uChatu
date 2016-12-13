//
//  Complaint.m
//  uChatu
//
//  Created by Roman Rybachenko on 7/24/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "Complaint.h"

@implementation Complaint

@dynamic complaintText;
@dynamic reporter;
@dynamic inappropriateObject;
@dynamic photo;

#pragma mark - Static methods

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"Complaint";
}

@end
