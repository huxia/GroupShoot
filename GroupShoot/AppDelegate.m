//
//  AppDelegate.m
//  GKSession
//
//  Created by Huizhe Xiao on 13-9-28.
//  Copyright (c) 2013年 Huizhe Xiao. All rights reserved.
//

#import "AppDelegate.h"
#import "HostViewController.h"
#import "ClientViewController.h"
@interface AppDelegate() <UIAlertViewDelegate>
@end
@implementation AppDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	UIViewController* c = nil;
	if (buttonIndex == alertView.cancelButtonIndex) {
		c = [[ClientViewController alloc] initWithNibName:@"ClientViewController" bundle:nil];
	}else{
		c = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil];
		
	}
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	UINavigationController* nv = [[UINavigationController alloc] initWithRootViewController:c];
	nv.navigationBar.translucent = NO;
	self.window.rootViewController = nv;
	[self.window addSubview:nv.view];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
	[[[UIAlertView alloc] initWithTitle:@"Select" message:nil delegate:self cancelButtonTitle:@"I'm a Client" otherButtonTitles:@"I'm a Host", nil] show];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
