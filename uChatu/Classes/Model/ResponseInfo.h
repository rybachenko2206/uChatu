//
//  ResponseInfo.h
//  uChatu
//
//  Created by Roman Rybachenko on 11/27/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import <Parse/Parse.h>

#import <Foundation/Foundation.h>

@interface ResponseInfo : NSObject

@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSArray *objects;
@property (nonatomic, strong) NSDictionary *additionalInfo;

@end
