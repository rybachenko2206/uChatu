//
//  AvatarImage.m
//  uChatu
//
//  Created by Roman Rybachenko on 4/16/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//


#import "PrefixHeader.pch"
#import "ImaginaryFriend.h"
#import "AvatarPhoto.h"

@implementation AvatarPhoto

@dynamic thumbnailImage;
@dynamic fullImage;
@dynamic imaginaryFriend;

#pragma mark - Static methods

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"AvatarPhoto";
}

+ (AvatarPhoto *)avatarImageWithImage:(UIImage *)image imaginaryFriend:(ImaginaryFriend *)imFriend {
    AvatarPhoto *avImg = [AvatarPhoto object];
    
    UIImage *thmbImage = image == nil ? [UIImage imageNamed:@"cht_emptyAvatar_image"] : [Utilities generateThumbnailImageFromImage:image];
    UIImage *fullImage = image == nil ? [UIImage imageNamed:@"cht_emptyAvatar_image"] :[Utilities generateFullScreenImageFromImage:image];
    
    NSData *thmbData = UIImagePNGRepresentation(thmbImage);
    PFFile *thmbFile = [PFFile fileWithName:@"thumbnailImage.png" data:thmbData];
    avImg.thumbnailImage = thmbFile;
    
    NSData *fullImgData = UIImagePNGRepresentation(fullImage);
    PFFile *fullImgFile = [PFFile fileWithName:@"fullImage.png" data:fullImgData];
    avImg.fullImage = fullImgFile;
    
    avImg.imaginaryFriend = imFriend;
    
    return avImg;
}


@end
