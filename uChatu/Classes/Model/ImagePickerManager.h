//
//  ImagePicker.h
//  Mindr
//
//  Created by Roman Rybachenko on 7/30/14.
//  Copyright (c) 2014 Mozi Development. All rights reserved.
//


#import "PrefixHeader.pch"

@class ImagePickerManager;

@protocol ImagePickerDelegate <NSObject>

-(void) imagePickerChoseImage:(UIImage*)image;

@end


@interface ImagePickerManager : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) UIViewController *viewController;
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) UIImage *image;

@property (weak) id <ImagePickerDelegate> delegate;

-(void) createImagePickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType forViewController:(UIViewController *)viewController;

@end
