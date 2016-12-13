//
//  CDPhoto.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/5/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "Utilities.h"
#import "AuthorizationManager.h"

#import "CDPhoto.h"
#import "CDChatMessage.h"


@implementation CDPhoto

@dynamic thumbnailPhotoName;
@dynamic fullPhotoName;
@dynamic thumbnailHeight;
@dynamic thumbnailWidth;
@dynamic message;

#pragma mark - Static methods

+ (CDPhoto *)newCDPhotoWithImage:(UIImage *)image inContext:(NSManagedObjectContext *)context {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[CDPhoto class] description] inManagedObjectContext:context];
    CDPhoto *newPhoto = [[CDPhoto alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
    newPhoto.thumbnailPhotoName = [Utilities getNewGUID];
    newPhoto.fullPhotoName = [Utilities getNewGUID];
    
    UIImage *thmbImage = [Utilities generateThumbnailImageFromImage:image];
    UIImage *fullImage = [Utilities generateFullScreenImageFromImage:image];
    
    newPhoto.thumbnailWidth = @(thmbImage.size.width);
    newPhoto.thumbnailHeight = @(thmbImage.size.height);
    
    NSString *imagePath = [Utilities pathToImageWithName:newPhoto.thumbnailPhotoName
                                                  userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
    [Utilities saveImage:thmbImage atPath:imagePath];
    
    imagePath = [Utilities pathToImageWithName:newPhoto.fullPhotoName
                                        userId:[AuthorizationManager sharedInstance].currentCDUser.userId];
    [Utilities saveImage:fullImage atPath:imagePath];
    
    return newPhoto;
}

@end
