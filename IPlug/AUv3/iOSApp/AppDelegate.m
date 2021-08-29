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
  
  if ([topViewController isKindOfClass:[AppViewController class]])
    return (AppViewController*)topViewController;
  
  while (![topViewController isKindOfClass:[AppViewController class]])
  {
    if (topViewController.presentedViewController)
    {
      topViewController = topViewController.presentedViewController;
    }
    else if ([topViewController isKindOfClass:[UINavigationController class]])
    {
      UINavigationController *nav = (UINavigationController *)topViewController;
      topViewController = nav.topViewController;
    }
    else if ([topViewController isKindOfClass:[UITabBarController class]])
    {
      UITabBarController *tab = (UITabBarController *)topViewController;
      topViewController = tab.selectedViewController;
    }
    else
    {
      return nil;
    }
  }
  
  return (AppViewController*)topViewController;
}

//- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
//{
//  AppViewController *viewController = [self GetUIViewController];
//
//  if (viewController)
//    [viewController AppOpenedWithURL:url];
//  return YES;
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  
  if (viewController)
    [viewController AUv3AppState: 0];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  
  if (viewController)
    [viewController AUv3AppState: 1];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  
  if (viewController)
    [viewController AUv3AppState: 2];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  
  if (viewController)
    [viewController AUv3AppState: 3];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  AppViewController *viewController = [self GetUIViewController];
  
  if (viewController)
    [viewController AUv3AppState: 4];
}

@end
