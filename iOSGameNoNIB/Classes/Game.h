#import <UIKit/UIKit.h>
#import "ES2Renderer.h"

@interface Game : UIViewController <UIApplicationDelegate>
{
  ES2Renderer* renderer ;
	bool animating ;
	id displayLink ;
}

- (void) startAnimation;
- (void) stopAnimation;
- (void) drawView:(id)sender;
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event ;
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event ;
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event ;
- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event ;
@end
