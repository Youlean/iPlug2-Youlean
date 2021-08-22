 /*
 ==============================================================================
 
 This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers. 
 
 See LICENSE.txt for  more info.
 
 ==============================================================================
*/

#import "IPlugAUPlayer.h"
#include "config.h"

#if !__has_feature(objc_arc)
#error This file must be compiled with Arc. Use -fobjc-arc flag
#endif

@implementation IPlugAUPlayer
{
  AVAudioEngine* audioEngine;
  AVAudioUnit* avAudioUnit;
  UInt32 componentType;
}

- (instancetype) initWithComponentType: (UInt32) unitComponentType
{
  self = [super init];
  
  if (self) {
    audioEngine = [[AVAudioEngine alloc] init];
    componentType = unitComponentType;
    audioPlayerDidInit = NO;
  }
  
#if TARGET_OS_IPHONE
  NSError* error = nil;
  BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
  
  if (success == NO)
    NSLog (@"Error setting category: %@", [error localizedDescription]);
#endif

  return self;
}

- (void) loadAudioUnitWithComponentDescription:(AudioComponentDescription)desc
                                   completion:(void (^) (void))completionBlock
{
  [AVAudioUnit instantiateWithComponentDescription:desc options:0
                                 completionHandler:^(AVAudioUnit* __nullable audioUnit, NSError* __nullable error)
                                 {
                                   [self onAudioUnitInstantiated:audioUnit error:error completion:completionBlock];
                                 }];
}

- (void) onAudioUnitInstantiated:(AVAudioUnit* __nullable) audioUnit error:(NSError* __nullable) error completion:(void (^) (void))completionBlock
{
  if (audioUnit == nil)
    return;
  
  avAudioUnit = audioUnit;
  
  self.currentAudioUnit = avAudioUnit.AUAudioUnit;
  
  AVAudioSession* session = [AVAudioSession sharedInstance];
  [session setCategory: AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
  [session setPreferredSampleRate:44100. error:&error];
  [session setPreferredIOBufferDuration:0.005 error:&error];
  
  AVAudioMixerNode* mainMixer = [audioEngine mainMixerNode];
  mainMixer.outputVolume = 1;
  
  completionBlock();
}

- (void) initAudioPlayer
{
  if (audioPlayerDidInit)
    return;
  
  audioPlayerDidInit = true;
  
  AVAudioSession* session = [AVAudioSession sharedInstance];
  
  double inputNodeSamplerate = [audioEngine.inputNode inputFormatForBus:0].sampleRate;
  
  AVAudioFormat* formatI = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:inputNodeSamplerate channels:(int)session.inputNumberOfChannels];
  
  AVAudioFormat* formatO = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:inputNodeSamplerate channels:(int)session.outputNumberOfChannels];
  
  [audioEngine attachNode:avAudioUnit];
  
#if PLUG_TYPE==0
  [audioEngine connect:audioEngine.inputNode to:avAudioUnit format: formatI];
#endif
  [audioEngine connect:avAudioUnit to:audioEngine.outputNode format: formatO];
  
  [self activate];
  [self startEngine];
}

- (AVAudioEngine *)getAudioEngine
{
  return audioEngine;
}

- (AVAudioUnit*) getAVAudioUnit
{
  return avAudioUnit;
}

- (void) activate
{
  NSError* error = nil;
  AVAudioSession* session = [AVAudioSession sharedInstance];
  [session setCategory: AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];

  BOOL success = [[AVAudioSession sharedInstance] setActive:YES error:nil];
  
  if (success == NO)
    NSLog (@"Error setting category: %@", [error localizedDescription]);
}

- (void) deactivate
{
  NSError* error = nil;
  BOOL success = [[AVAudioSession sharedInstance] setActive:NO error:nil];
  
  if (success == NO)
    NSLog (@"Error setting category: %@", [error localizedDescription]);
}

- (void) startEngine
{
  NSError* error = nil;
  
  BOOL success = [audioEngine startAndReturnError:&error];
  
  if (!success)
    NSLog (@"engine failed to start: %@", error);
}

- (void) stopEngine
{
  [audioEngine stop];
}
@end
