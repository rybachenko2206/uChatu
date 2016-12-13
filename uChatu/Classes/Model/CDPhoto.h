//
//  CDPhoto.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/5/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class CDChatMessage;

@interface CDPhoto : NSManagedObject

@property (nonatomic, retain) NSString * thumbnailPhotoName;
@property (nonatomic, retain) NSString * fullPhotoName;
@property (nonatomic, retain) NSNumber * thumbnailHeight;
@property (nonatomic, retain) NSNumber * thumbnailWidth;
@property (nonatomic, retain) CDChatMessage *message;

+ (CDPhoto *)newCDPhotoWithImage:(UIImage *)image inContext:(NSManagedObjectContext *)context;

@end
