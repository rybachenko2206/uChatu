//
//  AudioPlayer.m
//  uChatu
//
//  Created by Roman Rybachenko on 3/24/15.
//  Copyright (c) 2015 Roman Rybachenko. All rights reserved.
//

#import "PrefixHeader.pch"

#import "AudioPlayer.h"

static AVAudioPlayer *avSound;
static NSString *playingTrackName;

@implementation AudioPlayer

+ (void)playWithTrackName:(NSString *)trackName {
    if (!trackName) {
        return;
    }
//    playingTrackName = trackName;
    trackName = [[NSBundle mainBundle] pathForResource:trackName ofType:@"mp3"];
    
    NSError *error = nil;
    avSound = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:trackName]
                                                     error:&error];
    if (error) {
        $l("---- error = %@", error.localizedDescription);
    }
    [self setVolume:[self volume]];
    [avSound setNumberOfLoops:1];
    [avSound play];
}

+ (void)stop {
    [avSound stop];
}

+ (BOOL)isPlaying {
    
    return avSound.isPlaying ? YES : NO;
}

+ (void)setVolume:(float)volume {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:volume] forKey:@"MusicVolume"];
    [avSound setVolume:volume];
}

+ (float)volume {
    NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:@"MusicVolume"];
    return num ? num.floatValue: 1.0;
}

@end
