//
//  JBTextField.h
//  Jobrain
//
//  Created by Sergey Zalozniy on 6/18/14.
//  Copyright (c) 2014 Amit Bar-Shai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    TextFieldTypeWithoutValidation = 0,
	TextFieldTypeDefault = 1,
	TextFieldTypeEmail = 2,
	TextFieldTypePassword = 3
} TextFieldType;


@interface JBTextField : UITextField

@property (nonatomic, assign) TextFieldType textFieldType;
@property (nonatomic, assign) BOOL bottomLineHidden;

-(void) setBackgroundNormal;
-(void) setBackgroundError;

-(void) validate;
-(BOOL) isValid;

-(BOOL) isValidEmail;
-(BOOL) isValidPassword;

-(BOOL) textIsBlank;


- (void)addCheckIcon:(NSString *)iconName;
- (void)setCheckIconVisible:(BOOL)isVisible;

@end
