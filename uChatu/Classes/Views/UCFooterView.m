//
//  UCFooterSeparator.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/3/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "UCFooterView.h"

@interface UCFooterView ()

@property (strong, nonatomic) IBOutlet UIView *contentView;

- (IBAction)inviteTap:(id)sender;

@end

@implementation UCFooterView


#pragma mark Static methods

+(CGFloat)footerHeight {
    return 68.0f;
}

#pragma mark Instance initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"UCFooterView" owner:self options:nil];
        [self addSubview:_contentView];
    }
    return self;
}


#pragma mark Overriden methods

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    _contentView.frame = rect;
    [self layoutIfNeeded];
}

- (IBAction)inviteTap:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTapInviteButton)]) {
        [self.delegate didTapInviteButton];
    }
}
@end
