//
//  AudioPlayer.h
//  uChatu
//
//  Created by Roman Rybachenko on 3/24/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioPlayer : NSObject


+ (void)playWithTrackName:(NSString*)trackName;
+ (void)stop;
+ (BOOL)isPlaying;

@end
