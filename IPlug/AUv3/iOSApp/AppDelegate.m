 /*
 ==============================================================================
 
 This file is part of the iPlug 2 library. Copyright (C) the iPlug 2 developers. 
 
 See LICENSE.txt for  more info.
 
 ==============================================================================
*/

#import "AppDelegate.h"
#import "AppViewController.h"
#import "IPlugAUPlayer.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (AppViewController*) GetUIViewController
{
  UIViewController *topViewController = self.window.rootViewController;
  
  while (true)
  {
    if (topViewController.presentedViewController) {
      topViewController = topViewController.presentedViewController;
    } else if ([topViewController isKindOfClass:[UINavigationController class]]) {
      UINavigationController *nav = (UINavigationController *)topViewController;
      topViewController = nav.topViewController;
    } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
      UITabBarController *tab = (UITabBarController *)topViewController;
      topViewController = tab.selectedViewController;
    } else {
      break;
    }
  }
  
  return (AppViewController*)topViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  [viewController AUv3AppState: 0];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  [viewController AUv3AppState: 1];
  
  IPlugAUPlayer* player = (IPlugAUPlayer*)[viewController GetAUPlayer];
  
  [player stopEngine];
  [player deactivate];
  [viewController SetIOSAudioEngineState: 0];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  [viewController AUv3AppState: 2];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  [viewController AUv3AppState: 3];
  
  IPlugAUPlayer* player = (IPlugAUPlayer*)[viewController GetAUPlayer];
  
  [player activate];
  [player startEngine];
  [viewController SetIOSAudioEngineState: 1];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  [viewController AUv3AppState: 4];
}

@end
