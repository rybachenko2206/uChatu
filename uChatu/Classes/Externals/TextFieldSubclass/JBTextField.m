//
//  JBTextField.m
//  Jobrain
//
//  Created by Sergey Zalozniy on 6/18/14.
//  Copyright (c) 2014 Amit Bar-Shai. All rights reserved.
//


#import "PrefixHeader.pch"

#import "JBTextField.h"

#define BOTTOM_LINE_COLOR [UIColor lightGrayColor]      //[UIColor colorWithRed:216.0f green:212.0f blue:90.0f alpha:206.0f]  //RGB(216.0f, 212.0f, 206.0f)
#define BOTTOM_LINE_HIGHLIGHTED_COLOR [UIColor redColor]//[UIColor colorWithRed:226.0f green:90.0f blue:90.0f alpha:1.0]                  //RGB(226.0f, 90.0f, 90.0f)

const NSInteger kTextFieldFontSize = 16.0f;
const NSInteger kTextFieldBottomLineHeight = 1.0f;


@interface JBTextField () {
    BOOL _bottomLineHidden;
}

@property (strong, nonatomic) UIView *bottonLine;

@end


@implementation JBTextField

#pragma mark - Interface methods

-(void) awakeFromNib {
	[super awakeFromNib];
	
	self.backgroundColor = [UIColor clearColor];
	self.font = [UIFont fontWithName:@"HelveticaNeue-medium" size:kTextFieldFontSize];
    self.textColor = [UIColor blackColor];
    self.borderStyle = UITextAutocapitalizationTypeNone;
	
	CGFloat textFieldHeight = CGRectGetHeight(self.frame);
	CGRect newFrame = self.bounds;
	newFrame.origin.y = textFieldHeight - kTextFieldBottomLineHeight;
	newFrame.size.height = kTextFieldBottomLineHeight;
    newFrame.size.width = 600;
    if (!self.bottomLineHidden) {
        self.bottonLine = [[UIView alloc] initWithFrame:newFrame];
        self.bottonLine.alpha = 1.0f;
        self.bottonLine.backgroundColor = BOTTOM_LINE_COLOR;
        [self addSubview:self.bottonLine];
    }
}


-(void) validate {
    if ([self isValid]) {
        [self setBackgroundNormal];
	} else {
		[self setBackgroundError];
    }
}


-(BOOL) isValid {
    BOOL isValid = YES;
    switch (self.textFieldType) {
		case TextFieldTypeEmail:
            isValid = [self isValidEmail];
			break;
			
		case TextFieldTypePassword:
            isValid = [self isValidPassword];
			break;
			
		case TextFieldTypeDefault:
            isValid = ![self textIsBlank];
			break;
        case TextFieldTypeWithoutValidation:
            break;
		default:
			NSLog(@"unknown textfield type: %d", _textFieldType);
			break;
	}
    
    [self setCheckIconVisible:isValid];
    
    return isValid;
}


-(BOOL) textIsBlank {
	NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
	if ([[self.text stringByTrimmingCharactersInSet:set] length] == 0) {
		return YES;
	}
	return NO;
}


-(BOOL) isValidEmail {
	NSString *emailRegex =
	@"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
	@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
	@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
	@"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
	@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
	@"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
	@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
	
	NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES[cd] %@", emailRegex];
    
	BOOL isValid = [regexPredicate evaluateWithObject:self.text];
	return isValid;
}


-(BOOL) isValidPassword {
    return (self.text.length >= 1);
}


-(void) setBottomLineHidden:(BOOL)bottomLineHidden {
    _bottomLineHidden = bottomLineHidden;
    self.bottonLine.hidden = _bottomLineHidden;
}


-(BOOL) bottomLineHidden {
    return _bottomLineHidden;
}


-(void) setBackgroundError {
    self.bottonLine.backgroundColor = BOTTOM_LINE_HIGHLIGHTED_COLOR;
}


-(void) setBackgroundNormal {
	self.bottonLine.backgroundColor = BOTTOM_LINE_COLOR;
}


#pragma mark - Setters methods

-(void) setTextFieldType:(TextFieldType)textFieldType {
	_textFieldType = textFieldType;
	
	switch (_textFieldType) {
		case TextFieldTypeEmail:
			break;
			
		case TextFieldTypePassword:
            self.secureTextEntry = YES;
			break;
			
		case TextFieldTypeDefault:
			break;
			
		default:
			NSLog(@"unknown textfield type: %d", _textFieldType);
			break;
	}
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 0 , 0 );
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 0 , 0 );
}

- (void)addCheckIcon:(NSString *)iconName {
	UIImage *icon = [UIImage imageNamed:iconName];
	CGFloat textFieldHeight = CGRectGetHeight(self.frame);
	UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, self.frame.size.width - textFieldHeight, textFieldHeight, textFieldHeight)];
	iconImageView.image = icon;
	iconImageView.contentMode = UIViewContentModeCenter;
	iconImageView.backgroundColor = [UIColor clearColor];
	self.rightView = iconImageView;
	self.leftViewMode = UITextFieldViewModeNever;
}

- (void)setCheckIconVisible:(BOOL)isVisible {
    self.rightViewMode = (isVisible)? UITextFieldViewModeAlways : UITextFieldViewModeNever;
}


#pragma mark - Private methods

-(void) setCustomIcon:(NSString *)iconName {
	UIImage *icon = [UIImage imageNamed:iconName];
	CGFloat textFieldHeight = CGRectGetHeight(self.frame);
	UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, textFieldHeight, textFieldHeight)];
	iconImageView.image = icon;
	iconImageView.contentMode = UIViewContentModeCenter;
	iconImageView.backgroundColor = [UIColor whiteColor];
	self.leftView = iconImageView;
	self.leftViewMode = UITextFieldViewModeAlways;
}


@end
