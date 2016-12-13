//
//  SharedDateFormatter.h
//  Mindr
//
//  Created by Roman Rybachenko on 5/27/14.
//  Copyright (c) 2014 Mozi Development. All rights reserved.
//



//#define DATE_FORMAT_1 @"EEEE dd/MM/YYYY"
#define DATE_FORMAT_TIME @"hh:mm a"
#define DATE_FORMAT_THIS_WEEK_DAY @"EEEE"
#define DEFAULT_DATE_FORMAT @"EEE, MMM dd"
#define DATE_FORMAT_FULL @"dd.MM.yyyy, HH:mm:ss"


#import "PrefixHeader.pch"

@interface SharedDateFormatter : NSObject

+(NSDateFormatter *) sharedInstance;

+(NSDate*) dateFromString:(NSString*)string withFormat:(NSString*)format;
+(NSString*) getStringFromDate:(NSDate*)date withFormat:(NSString*)dateFormat;

+(NSDate *) dateForLastModifiedFromDate:(NSDate *)date;
+(NSString *) stringCreatedAtFromDate:(NSDate *)date;
+(BOOL) isDateInToday:(NSDate *)date;
+(BOOL) isDateInYesterday:(NSDate *)date;

@end
