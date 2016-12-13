//
//  SharedDateFormatter.m
//  Mindr
//
//  Created by Roman Rybachenko on 5/27/14.
//  Copyright (c) 2014 Mozi Development. All rights reserved.
//

#import "SharedDateFormatter.h"

@implementation SharedDateFormatter

#pragma mark Static methods

+(NSDateFormatter *) sharedInstance {
    static NSDateFormatter *staticDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticDateFormatter = [NSDateFormatter new];
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
        [staticDateFormatter setLocale:usLocale];
    });
    
    return staticDateFormatter;
}


#pragma mark Instance initialization

+(NSDate*) dateFromString:(NSString*)string withFormat:(NSString*)format {
    [[SharedDateFormatter sharedInstance] setDateFormat:format];
    NSDate *date = [[SharedDateFormatter sharedInstance] dateFromString:string];
    return date;
}

+(NSString*) getStringFromDate:(NSDate*)date withFormat:(NSString*)dateFormat {
    [[SharedDateFormatter sharedInstance] setDateFormat:dateFormat];
    return [[SharedDateFormatter sharedInstance] stringFromDate:date];
}

+(NSDate *) dateForLastModifiedFromDate:(NSDate *)date {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.second = 0;
    NSDate *newDate = [[NSCalendar currentCalendar] dateByAddingComponents:components
                                                                    toDate:date
                                                                   options:0];
    
    return newDate;
}

+(NSString *) stringCreatedAtFromDate:(NSDate *)date {
    if (!date) {
        return @"unknown date";
    }
    NSString *dateStr = nil;
    
    if ([SharedDateFormatter isDateInToday:date]) {
        dateStr = [SharedDateFormatter getStringFromDate:date
                                              withFormat:DATE_FORMAT_TIME];
        return dateStr;
    } else if ([SharedDateFormatter isDateInYesterday:date]) {
        dateStr = @"Yesterday";
        return dateStr;
    } else {
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        [gregorian setFirstWeekday:1];
        NSDate *today = [NSDate date];
        NSDateComponents *todaysComponents = [gregorian components:NSWeekCalendarUnit fromDate:today];
        NSUInteger todaysWeek = [todaysComponents week];
        
        NSDateComponents *otherComponents =
        [gregorian components:NSWeekCalendarUnit fromDate:date];
        NSUInteger anotherWeek = [otherComponents week];
        
        if (anotherWeek == todaysWeek) {
            dateStr = [SharedDateFormatter getStringFromDate:date withFormat:DATE_FORMAT_THIS_WEEK_DAY];
            return dateStr;
        } else {
            dateStr = [SharedDateFormatter getStringFromDate:date withFormat:DEFAULT_DATE_FORMAT];
            return dateStr;
        }
    }
    
    return dateStr;
}

+(BOOL) isDateInToday:(NSDate *)date {
    BOOL isToday = NO;
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *today = [NSDate date];
    NSDateComponents *todaysComponents = [gregorian components:NSDayCalendarUnit fromDate:today];
    NSUInteger todaysDay = [todaysComponents day];
    
    NSDateComponents *otherComponents =
    [gregorian components:NSDayCalendarUnit fromDate:date];
    NSUInteger anotherDay = [otherComponents day];
    
    isToday = (todaysDay == anotherDay) ? YES : NO;
    
    return isToday;
}

+(BOOL) isDateInYesterday:(NSDate *)date {
    BOOL isYesterday = NO;
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *today = [NSDate date];
    NSDateComponents *todaysComponents = [gregorian components:NSDayCalendarUnit fromDate:today];
    NSUInteger todaysDay = [todaysComponents day];
    
    NSDateComponents *otherComponents =
    [gregorian components:NSDayCalendarUnit fromDate:date];
    NSUInteger anotherDay = [otherComponents day];
    
    isYesterday = (todaysDay - anotherDay == 1) ? YES : NO;
    
    return isYesterday;
}


@end
