//
//  Utils.h
//  ReceiptBank
//
//  Created by Max Odnovolyk on 11/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


@interface MDUtils : NSObject

+(NSString *) applicationDocumentsDirectory;
+(NSString *) applicationUserTempDirectory;
+(NSString *) applicationCacheDirectory;

+(NSData *) md5digest:(NSString *)str;
+(NSString *) md5:(NSString *)str;

+(NSString *) encodeBase64WithString:(NSString *)strData;
+(NSString *) encodeBase64WithData:(NSData *)objData;
+(NSData *) decodeBase64WithString:(NSString *)strBase64;

+(UIColor *) colorWithInt:(NSUInteger)rgbInteger;
+(NSNumber *) numberWithColor:(UIColor *)color;

+(CGFloat) fround:(CGFloat)number;

@end