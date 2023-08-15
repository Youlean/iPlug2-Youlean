 /*
 ==============================================================================
 
 This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers. 
 
 See LICENSE.txt for  more info.
 
 ==============================================================================
*/

#import <CoreAudioKit/AUViewController.h>
#import "IPlugAUAudioUnit.h"
#import "IPlugAUViewController.h"
#include "IPlugPlatform.h"
#include "IPlugLogger.h"

#ifdef OS_IOS
#import "GenericUI.h"
#endif

#if !__has_feature(objc_arc)
#error This file must be compiled with Arc. Use -fobjc-arc flag
#endif

@interface IPlugAUViewController (AUAudioUnitFactory)
@end

#ifdef OS_IOS
#pragma mark - iOS
@implementation IPlugAUViewController

- (AUAudioUnit*) createAudioUnitWithComponentDescription:(AudioComponentDescription) desc error:(NSError **)error
{
  self.audioUnit = [[IPlugAUAudioUnit alloc] initWithComponentDescription:desc error:error];

  dispatch_async(dispatch_get_main_queue(), ^{
    
  // Open window if it is not alredy opened  
  if (![self.audioUnit isWindowOpen])
  {
    [self.audioUnit openWindow:self.view];
  }
    
  });
  
  [self audioUnitInitialized];
  
  return self.audioUnit;
}

#if PLUG_HAS_UI
- (void)viewWillLayoutSubviews
{
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  
  if (self.audioUnit)
  {
    CGRect drawableRect;
    drawableRect = self.view.bounds;
    
    [_audioUnit resize:drawableRect];
  }
  
  [super viewWillLayoutSubviews];
  
  [CATransaction commit];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  
  [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
  
  if (self.audioUnit)
  {
    [coordinator animateAlongsideTransition: nil completion: ^void (id<UIViewControllerTransitionCoordinatorContext>)
     {
      [self.audioUnit layoutUI];
    }];
  }
  
  [CATransaction commit];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL) animated
{
  [super viewWillAppear:animated];
  
  if (self.audioUnit)
  {
    [self.audioUnit openWindow:self.view];
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL) animated
{
  [super viewDidDisappear:animated];
  
  if (self.audioUnit)
  {
    [self.audioUnit closeWindow];
  }
}

#endif

- (AUAudioUnit*) getAudioUnit
{
  return self.audioUnit;
}

- (void) audioUnitInitialized
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.audioUnit)
    {
      int width = (int) [self.audioUnit width];
      int height = (int) [self.audioUnit height];
      self.preferredContentSize = CGSizeMake(width, height);
      self.view.backgroundColor = UIColor.blackColor;
      
      [self.audioUnit SetIsHostApp: NO];
    }
  });
}

@end

#else // macOS
#pragma mark - macOS
@implementation IPlugAUViewController

- (id) init
{
  self = [super initWithNibName:@"IPlugAUViewController"
                         bundle:[NSBundle bundleForClass:NSClassFromString(@"IPlugAUViewController")]];

  return self;
}

- (AUAudioUnit*) createAudioUnitWithComponentDescription:(AudioComponentDescription) desc error:(NSError **)error
{
  self.audioUnit = [[IPlugAUAudioUnit alloc] initWithComponentDescription:desc error:error];

  return self.audioUnit;
}

- (AUAudioUnit*) getAudioUnit
{
  return self.audioUnit;
}

- (void) audioUnitInitialized
{
  dispatch_async(dispatch_get_main_queue(), ^{
    int viewWidth = (int) [self.audioUnit width];
    int viewHeight = (int) [self.audioUnit height];
    self.preferredContentSize = CGSizeMake (viewWidth, viewHeight);
  });
}

- (void) setAudioUnit:(IPlugAUAudioUnit*) audioUnit
{
  _audioUnit = audioUnit;
  [self audioUnitInitialized];
}

- (void) viewWillAppear
{
  [_audioUnit openWindow:self.view];
}
@end

#endif

