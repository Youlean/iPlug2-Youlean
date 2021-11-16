 /*
 ==============================================================================
 
 This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers. 
 
 See LICENSE.txt for  more info.
 
 ==============================================================================
*/

#import "IPlugAUPlayer.h"
#include "IPlugConstants.h"
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
  
#if PLUG_TYPE == 1
  [session setCategory: AVAudioSessionCategoryPlayback error:&error];
#else
  AVAudioSessionPortDescription *routePort = session.currentRoute.outputs.firstObject;
  NSString *portType = routePort.portType;
  
  NSLog(@"PortType %@", portType);
  
  [session setCategory: AVAudioSessionCategoryPlayAndRecord error:&error];
  [session  overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
#endif
  
  [session setPreferredSampleRate:iplug::DEFAULT_SAMPLE_RATE error:nil];
  [session setPreferredIOBufferDuration:128.0/iplug::DEFAULT_SAMPLE_RATE error:nil];
  AVAudioMixerNode* mainMixer = [audioEngine mainMixerNode];
  mainMixer.outputVolume = 1;
  
#ifndef IPLUG_DISABLE_AU_PLAYER_AUTO_START
  [self initAudioPlayer];
#endif

  completionBlock();
}

- (void) initAudioPlayer
{
  if (audioPlayerDidInit)
    return;
  
  audioPlayerDidInit = true;
  
  AVAudioSession* session = [AVAudioSession sharedInstance];
  AVAudioMixerNode* mainMixer = [audioEngine mainMixerNode];
  
  [audioEngine attachNode:avAudioUnit];
  
#if PLUG_TYPE != 1
  AVAudioFormat* micInputFormat = [[audioEngine inputNode] inputFormatForBus:0];
  AVAudioFormat* pluginInputFormat = [avAudioUnit inputFormatForBus:0];
#endif
  
  AVAudioFormat* pluginOutputFormat = [avAudioUnit outputFormatForBus:0];
  
  NSLog(@"Session SR: %i", int(session.sampleRate));
  NSLog(@"Session IO Buffer: %i", int((session.IOBufferDuration * session.sampleRate)+0.5));
  
#if PLUG_TYPE != 1
  NSLog(@"Mic Input SR: %i", int(micInputFormat.sampleRate));
  NSLog(@"Mic Input Chans: %i", micInputFormat.channelCount);
  NSLog(@"Plugin Input SR: %i", int(pluginInputFormat.sampleRate));
  NSLog(@"Plugin Input Chans: %i", pluginInputFormat.channelCount);
#endif
  
#if PLUG_TYPE != 1
  if (micInputFormat != nil)
    [audioEngine connect:audioEngine.inputNode to:avAudioUnit format: micInputFormat];
#endif
  
  auto numOutputBuses = [avAudioUnit numberOfOutputs];
  
  if (numOutputBuses > 1)
  {
    // Assume all output buses are the same format
    for (int busIdx=0; busIdx<numOutputBuses; busIdx++)
    {
      [audioEngine connect:avAudioUnit to:mainMixer fromBus: busIdx toBus:[mainMixer nextAvailableInputBus] format:pluginOutputFormat];
    }
  }
  else
  {
    [audioEngine connect:avAudioUnit to:audioEngine.outputNode format: pluginOutputFormat];
  }

  [self activate];
  [self startEngine];
}

- (void) channelRouteChanged
{
  AVAudioSession* session = [AVAudioSession sharedInstance];
  AVAudioMixerNode* mainMixer = [audioEngine mainMixerNode];
  
#if PLUG_TYPE != 1
  AVAudioFormat* micInputFormat = [[audioEngine inputNode] inputFormatForBus:0];
  AVAudioFormat* pluginInputFormat = [avAudioUnit inputFormatForBus:0];
#endif
  
  AVAudioFormat* pluginOutputFormat = [avAudioUnit outputFormatForBus:0];
  
  NSLog(@"Session SR: %i", int(session.sampleRate));
  NSLog(@"Session IO Buffer: %i", int((session.IOBufferDuration * session.sampleRate)+0.5));
  
#if PLUG_TYPE != 1
  NSLog(@"Mic Input SR: %i", int(micInputFormat.sampleRate));
  NSLog(@"Mic Input Chans: %i", micInputFormat.channelCount);
  NSLog(@"Plugin Input SR: %i", int(pluginInputFormat.sampleRate));
  NSLog(@"Plugin Input Chans: %i", pluginInputFormat.channelCount);
#endif
  
#if PLUG_TYPE != 1
  if (micInputFormat != nil)
    [audioEngine connect:audioEngine.inputNode to:avAudioUnit format: micInputFormat];
#endif
  
  auto numOutputBuses = [avAudioUnit numberOfOutputs];
  
  if (numOutputBuses > 1)
  {
    // Assume all output buses are the same format
    for (int busIdx=0; busIdx<numOutputBuses; busIdx++)
    {
      [audioEngine connect:avAudioUnit to:mainMixer fromBus: busIdx toBus:[mainMixer nextAvailableInputBus] format:pluginOutputFormat];
    }
  }
  else
  {
    [audioEngine connect:avAudioUnit to:audioEngine.outputNode format: pluginOutputFormat];
  }
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

- (BOOL) engineRunning
{
  return [audioEngine isRunning];
}
@end
