//
//  ErrorManager.h
//  Jobrain
//
//  Created by Sergey Zalozniy on 6/19/14.
//  Copyright (c) 2014 Amit Bar-Shai. All rights reserved.
//


/*
 
 
 1000 - OK
 1500 - ERROR: {func_name}(): Access Denied. Please contact to Admin.
 2000 - ERROR
 2001 - ERROR: {func_name}(): Invalid TOKEN
 2002 - ERROR: {func_name}(): Data not found
 2003 - ERROR: {func_name}(): Exceeded the number of requests   not found in code
 2004 - Invalid phone number format (expects 12 digits)
 2033 - ERROR: {func_name}(): Incorrect digital_sign
 2005 - ERROR: {func_name}(): Incorrect Password or Password Confirmation
 2006 - ERROR: {func_name}(): Incorrect Email format
 2007 - ERROR: {func_name}(): Invalid First or Last Name
 2034 - ERROR: {func_name}(): Unsupported platform
 2008 - ERROR: {func_name}(): This Email already registered
 2009 - ERROR: {func_name}(): Invalid UDID
 2010 - ERROR: {func_name}(): Email already used
 2035 - ERROR: {func_name}(): Can not generate token
 2011 - ERROR: {func_name}(): The security code (CAPTCHA) is incorrect!
 2012 - ERROR: {func_name}(): Cannot send email
 2013 - ERROR: {func_name}(): Invalid Facebook Token
 2014 - ERROR: {func_name}(): Invalid Content ID
 2015 - ERROR: {func_name}(): Invalid SEX ID
 2016 - ERROR: {func_name}(): Invalid Timezone
 2017 - ERROR: {func_name}(): Incorrect Password
 2021 - ERROR: {func_name}(): Uploadd file not found in the _POST
 2023 - ERROR: {func_name}(): must be filled
 2024 - ERROR: {func_name}(): must be unique
 2025 - ERROR: {func_name}(): Confirm password is wrong
 2026 - ERROR: {func_name}(): You cannot delete yoursel
 2027 - ERROR: {func_name}(): Empty sounds-array cannot be processed
 2800 - ERROR: {func_name}(): DB Statement error
 2900 - ERROR: {func_name}(): Incorrect incoming variables

 
 2021 - ERROR: {func_name}(): Uploadd file not found in the _POST
 2022 - ERROR: {func_name}(): Unsupported Content Type
 2023 - ERROR: {func_name}(): Unsupported File Type '{param}'
 
 2951 - ERROR: {func_name}(): AmazonS3: Cannot get upload file {param}
 2952 - ERROR: {func_name}(): AmazonS3: Cannot get URL of uploaded file {param}
 
 */

typedef NS_ENUM(NSInteger, kStatusCode) {
	kStatusCodeOK = 1000,
	kStatusCodeAccessDenied = 1500,
	kStatusCodeError = 2000,
	kStatusCodeInvalidToken = 2001,
	kStatusCodeDataNotFound = 2002,
	kStatusCodeExceededNumberOfRequests = 2003,
	kStatusCodeInvalidPhoneNumberFormat = 2004,
	kStatusCodeIncorrectDigitalSign = 2033,
	kStatusCodeIncorrectPasswordOrPasswordConfirmation = 2005,
	kStatusCodeIncorrectEmailFormat = 2006,
	kStatusCodeInvalidFirstOrLastName = 2007,
	kStatusCodeUnsupportedPlatform = 2034,
	kStatusCodeEmailAlreadyRegistered = 2008,
	kStatusCodeInvalidUDID = 2009,
	kStatusCodeEmailAlreadyUsed = 2010,
	kStatusCodeCanNotGenerateToken = 2035,
	kStatusCodeSecurityCodeIncorrect = 2011,
	kStatusCodeCannotSendEmail = 2012,
	kStatusCodeInvalidFacebookToken = 2013,
	kStatusCodeInvalidContentId = 2014,
	kStatusCodeInvalidSexId = 2015,
	kStatusCodeInvalidTimezone = 2016,
	kStatusCodeIncorrectPassword = 2017,
	kStatusCodeUploadFileNotFound = 2021,
	kStatusCodeUnsupportedContentType = 2022,
	kStatusCodeUnsupportedFileType = 2023,
	kStatusCodeMustBeFilled = 2023,
	kStatusCodeMustBeUnique = 2024,
	kStatusCodeConfirmPasswordIsWrong = 2025,
	kStatusCodeYouCannotDeleteYourself = 2026,
	kStatusCodeEmptySoundsArrayCannotProcessed = 2027,
	kStatusCodeDBStatementError = 2800,
	kStatusCodeIncorrectIncomingVariables = 2900,
	kStatusCodeCannotGetUploadFile = 2951,
	kStatusCodeCannotGetURLOfUploadedFile = 2952,
};


@interface ErrorManager : NSObject

+(instancetype) sharedInstance;

+(void) showAlertWithError:(NSError *)error;

+(void) showAlertWithTitle:(NSString *)title;
+(void) showAlertWithTitle:(NSString *)title
                complition:(void(^)(void))complition;
+(void) showAlertWithTitle:(NSString *)title
                   message:(NSString *)message;
+(void) showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                complition:(void(^)(void))complition;
+(void) showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               buttonTitle:(NSString *)buttonTitle
                complition:(void(^)(void))complition;

+(void) showAlertWithStatusCode:(NSInteger)statusCode;
+(void) proceedServerErrorWithStatusCode:(NSInteger)statusCode;

@end
