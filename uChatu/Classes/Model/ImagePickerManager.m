//
//  ImagePicker.m
//  Mindr
//
//  Created by Roman Rybachenko on 7/30/14.
//  Copyright (c) 2014 Mozi Development. All rights reserved.
//
#import <AssetsLibrary/AssetsLibrary.h>

#import "ImagePickerManager.h"


@implementation ImagePickerManager

-(void) createImagePickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType forViewController:(UIViewController *)viewController {
    
    self.viewController = viewController;
    self.imagePickerController = [[UIImagePickerController alloc] init];
    [self.imagePickerController setDelegate:self];
    self.imagePickerController.allowsEditing = YES;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera && ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        
        [myAlertView show];
        return; 
    }
    self.imagePickerController.sourceType = sourceType;
    [self.viewController presentViewController:self.imagePickerController animated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(imagePickerChoseImage:)]) {
        [self.delegate imagePickerChoseImage:self.image];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

@end
