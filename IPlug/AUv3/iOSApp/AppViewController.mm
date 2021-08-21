 /*
 ==============================================================================
 
 This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers. 
 
 See LICENSE.txt for  more info.
 
 ==============================================================================
*/

#import "AppViewController.h"
#import "IPlugAUPlayer.h"
#import "IPlugAUAudioUnit.h"

#include "config.h"
#include "IGraphics.h"

#import "IPlugAUViewController.h"
#import <CoreAudioKit/CoreAudioKit.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with Arc. Use -fobjc-arc flag
#endif

@interface AppViewController ()
{
  IPlugAUPlayer* player;
  IPlugAUViewController* iplugViewController;
  IBOutlet UIView *auView;
}
@end

@implementation AppViewController

- (void) SetIOSAudioEngineState:(int) state
{
  iplug::igraphics::IGraphics::EIOSAudioEngineState stateEnum = (iplug::igraphics::IGraphics::EIOSAudioEngineState)state;
  
  IPlugAUAudioUnit* au = (IPlugAUAudioUnit*) self->player.currentAudioUnit;
  [au SetIOSAudioEngineState: stateEnum];
}

- (void) AUv3AppState:(int) state
{
  IPlugAUAudioUnit* au = (IPlugAUAudioUnit*) self->player.currentAudioUnit;
  
  if (au)
  {
    [au AUv3AppState: state];
  }
}

- (void)AppOpenedWithURL:(NSURL *)url
{
  IPlugAUAudioUnit* au = (IPlugAUAudioUnit*) self->player.currentAudioUnit;

  if (au)
  {
    [au AppOpenedWithURL: url];
  }
}


- (void*) GetAUPlayer
{
  return (__bridge void*)player;
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  
#if PLUG_HAS_UI
  NSString* storyBoardName = [NSString stringWithFormat:@"%s-iOS-MainInterface", PLUG_NAME];
  UIStoryboard* storyboard = [UIStoryboard storyboardWithName:storyBoardName bundle: nil];
  iplugViewController = [storyboard instantiateViewControllerWithIdentifier:@"main"];
  [self addChildViewController:iplugViewController];
#endif
  
  AudioComponentDescription desc;

#if PLUG_TYPE==0
#if PLUG_DOES_MIDI_IN
  desc.componentType = kAudioUnitType_MusicEffect;
#else
  desc.componentType = kAudioUnitType_Effect;
#endif
#elif PLUG_TYPE==1
  desc.componentType = kAudioUnitType_MusicDevice;
#elif PLUG_TYPE==2
  desc.componentType = 'aumi';
#endif

  desc.componentSubType = PLUG_UNIQUE_ID;
  desc.componentManufacturer = PLUG_MFR_ID;
  desc.componentFlags = 0;
  desc.componentFlagsMask = 0;

  [AUAudioUnit registerSubclass: IPlugAUAudioUnit.class asComponentDescription:desc name:@"Local AUv3" version: UINT32_MAX];

  player = [[IPlugAUPlayer alloc] initWithComponentType:desc.componentType];

  [player loadAudioUnitWithComponentDescription:desc completion:^{
    self->iplugViewController.audioUnit = (IPlugAUAudioUnit*) self->player.currentAudioUnit;

    AVAudioEngine *engine = [self->player getAudioEngine];
    [self->iplugViewController.audioUnit setAVAudioEngine:(__bridge void *) engine];
    [self->iplugViewController.audioUnit SetIsHostApp: YES];
    [self embedPlugInView];
    [self->iplugViewController.audioUnit SetIOSAudioEngineState: iplug::igraphics::IGraphics::EIOSAudioEngineState::kActive];
  }];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"LaunchBTMidiDialog" object:nil];
  
  AVAudioSession *session = [AVAudioSession sharedInstance];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(AudioInterruption:)
                                               name:AVAudioSessionInterruptionNotification
                                             object:session];
}

- (void)AudioInterruption:(NSNotification *)notification
{
  NSNumber *interruptionType = [[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey];
  //NSNumber *interruptionOption = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];

  IPlugAUAudioUnit* au = (IPlugAUAudioUnit*) self->player.currentAudioUnit;
  IPlugAUPlayer* auPlayer = (IPlugAUPlayer*)player;
  
  switch (interruptionType.unsignedIntegerValue)
  {
    case AVAudioSessionInterruptionTypeBegan:
    {
      // • Audio has stopped, already inactive
      // • Change state of UI, etc., to reflect non-playing state
      [auPlayer stopEngine];
      [auPlayer deactivate];
      
      [au SetIOSAudioEngineState: iplug::igraphics::IGraphics::EIOSAudioEngineState::kPaused];
      
      break;
    }
    case AVAudioSessionInterruptionTypeEnded:
    {
      // • Make session active
      // • Update user interface
      // • AVAudioSessionInterruptionOptionShouldResume option
      [auPlayer activate];
      [auPlayer startEngine];

      [au SetIOSAudioEngineState: iplug::igraphics::IGraphics::EIOSAudioEngineState::kResumed];
      
      // Delay start because this notification is fired before call is ended and it's audio engine is stopped. 1s-3s should be fine
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1), dispatch_get_main_queue(), ^{
        [auPlayer activate];
        [auPlayer startEngine];
      });
//      if (interruptionOption.unsignedIntegerValue == AVAudioSessionInterruptionOptionShouldResume)
//      {
//        // Here you should continue playback.
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3), dispatch_get_main_queue(), ^{
//          [auPlayer restart];
//        });
//      }
    
      break;
    }
    default:
      break;
  }
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
  //  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}
  
  [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
  
  [coordinator animateAlongsideTransition: nil completion: ^void (id<UIViewControllerTransitionCoordinatorContext>)
   {
    IPlugAUAudioUnit* au = (IPlugAUAudioUnit*) self->player.currentAudioUnit;
    [au layoutUI];
  }];
}

-(void) receiveNotification:(NSNotification*) notification
{
  if ([notification.name isEqualToString:@"LaunchBTMidiDialog"])
  {
    NSDictionary* dic = notification.userInfo;
    NSNumber* x = (NSNumber*) dic[@"x"];
    NSNumber* y = (NSNumber*) dic[@"y"];
   
    CABTMIDICentralViewController* vc = [[CABTMIDICentralViewController alloc] init];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController* ppc = nc.popoverPresentationController;
    ppc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    ppc.sourceView = self.view;
    ppc.sourceRect = CGRectMake([x floatValue], [y floatValue], 1., 1.);
    
    [self presentViewController:nc animated:YES completion:nil];
  }
}

- (void) embedPlugInView
{
#if PLUG_HAS_UI
  UIView* view = iplugViewController.view;
  view.frame = auView.bounds;
  [auView addSubview: view];

  view.translatesAutoresizingMaskIntoConstraints = NO;

  NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)];
  [auView addConstraints: constraints];

  constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)];
  [auView addConstraints: constraints];

#endif
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
}

- (UIRectEdge) preferredScreenEdgesDeferringSystemGestures
{
  return UIRectEdgeAll;
}
@end

