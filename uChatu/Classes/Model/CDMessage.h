//
//  CDMessage.h
//  uChatu
//
//  Created by Roman Rybachenko on 12/9/14.
//  Copyright (c) 2014 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDMessage : NSManagedObject

@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSNumber * messageType;

@end
