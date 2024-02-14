#import <UIKit/UIKit.h>
#import "ES2RendererView.h"

@interface GameAppDelegate : UIViewController <UIApplicationDelegate>
{
  ES2RendererView *renderer ;
  bool animating ;
  id displayLink ;
}

// 2.
- (id) init;

// 3.
- (void) applicationDidFinishLaunching:(UIApplication *)application;
- (void) applicationWillResignActive:(UIApplication *)application;
// 12.
- (void) applicationDidBecomeActive:(UIApplication *)application;
- (void) applicationWillTerminate:(UIApplication *)application;
- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application;

// 4.
- (void) loadView;

// 8.
- (void) startAnimation;
- (void) stopAnimation;

// 13.
- (void) drawView:(id)sender;

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
