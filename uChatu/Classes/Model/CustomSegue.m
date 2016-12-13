//  Created by Phillipus on 19/09/2013.
//  Copyright (c) 2013 Dada Beatnik. All rights reserved.
//

#import "CustomSegue.h"

@implementation CustomSegue

- (void)perform {
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    // Add the destination view as a subview, temporarily
    [sourceViewController.view addSubview:destinationViewController.view];
    
    CGRect viewFrame = [UIScreen mainScreen].bounds;
    destinationViewController.view.frame = CGRectMake(viewFrame.size.width, -65, viewFrame.size.width, viewFrame.size.height);
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // Grow!
                         destinationViewController.view.frame = CGRectMake(0, -65, viewFrame.size.width, viewFrame.size.height);
                         
                     }
                     completion:^(BOOL finished){
                         [destinationViewController.view removeFromSuperview]; // remove from temp super view
                         [sourceViewController presentViewController:destinationViewController animated:NO completion:NULL]; // present VC
                     }];
}

@end
