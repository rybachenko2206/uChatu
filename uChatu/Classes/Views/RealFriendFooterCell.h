//
//  RealFriendFooterCell.h
//  uChatu
//
//  Created by Roman Rybachenko on 2/23/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RealFriendFooterCell;


@protocol RealFriendFooterCellDelegate <NSObject>
- (void)inviteButtonWasPressed;
@end


@interface RealFriendFooterCell : UITableViewCell
@property (weak) id <RealFriendFooterCellDelegate> delegate;

+ (CGFloat)heightForCell;

@end
