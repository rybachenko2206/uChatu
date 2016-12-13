//
//  NSArray+RandomObjects.m
//  uChatu
//
//  Created by Vitalii Krayovyi on 3/4/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "NSArray+RandomObjects.h"

@implementation NSArray (RandomObjects)

-(NSArray *)randomItemsWithLimit:(int)limit {
    // if array contains less objects,
    // it makes no sense to get random objects from it
    if (self.count <= limit) {
        return [self shuffledArray];
    }
    
    NSMutableArray *randomItems = [NSMutableArray new];
    for (int i = 0; i < limit; i++) {
        
        uint32_t randomIndex = 0;
        
        do {
            randomIndex = arc4random_uniform((int)self.count);
        } while ([randomItems containsObject:self[randomIndex]]);
        
        [randomItems addObject:self[randomIndex]];
    }
    
    return randomItems;
}


- (NSArray *)shuffledArray {
    NSMutableArray *mutableCopy = [self mutableCopy];
    NSUInteger count = [mutableCopy count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [mutableCopy exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
    
    return mutableCopy;
}

@end
