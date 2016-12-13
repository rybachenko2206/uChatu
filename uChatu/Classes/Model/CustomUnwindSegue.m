//  Created by Phillipus on 20/09/2013.
//  Copyright (c) 2013 Dada Beatnik. All rights reserved.
//

#import "CustomUnwindSegue.h"

@implementation CustomUnwindSegue

- (void)perform {
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    // Add view to super view temporarily
    [sourceViewController.view.superview insertSubview:destinationViewController.view atIndex:0];
    
//    CGRect viewFrame = [UIScreen mainScreen].bounds;
//    destinationViewController.view.frame = CGRectMake(- viewFrame.size.width, 65, viewFrame.size.width, viewFrame.size.height);
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         // Shrink!
//                         sourceViewController.view.frame = CGRectMake(viewFrame.size.width, 0, viewFrame.size.width, viewFrame.size.height);
//                         destinationViewController.view.frame = CGRectMake(0, 65, viewFrame.size.width, viewFrame.size.height);
                     }
                     completion:^(BOOL finished){
                         [destinationViewController.view removeFromSuperview]; // remove from temp super view
                         [sourceViewController dismissViewControllerAnimated:NO completion:NULL]; // dismiss VC
                     }];
}

@end
