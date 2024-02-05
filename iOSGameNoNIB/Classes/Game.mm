#import "Game.h"
#import "ES2Renderer.h"

@implementation Game

// This app shows how to use Game in a more modern way.
// It eliminates the iOS 3.2 backwards compatibility code that
// had a workaround for DisplayLink not being present, and eliminates
// the ES1Renderer class entirely.
//
// 

// You need this synthesize call, to be able to call self.window in this class.
@synthesize window ;

// We replaced the initWithCoder method with this regular init one
- (id) init
{
  puts( "INIT (WITHOUT CODER)" ) ;
  
  if( (self = [super init]) )
	{
    // Allocate the window, make it visible, hook up the root view controller as THIS.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = self ; 
  }
  
  return self ;
}


// Touches
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [[touches objectEnumerator] nextObject] ;
  CGPoint pt = [touch locationInView:self.view] ;
  printf( "touchesBegan %lu (%.1f %.1f)\n", [touches count], pt.x, pt.y ) ;
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [[touches objectEnumerator] nextObject] ;
  CGPoint pt = [touch locationInView:self.view] ;
  printf( "touchesMoved %lu (%.1f %.1f)\n", [touches count], pt.x, pt.y ) ;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [[touches objectEnumerator] nextObject] ;
  CGPoint pt = [touch locationInView:self.view] ;
  printf( "touchesEnded %lu (%.1f %.1f)\n", [touches count], pt.x, pt.y ) ;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [[touches objectEnumerator] nextObject] ;
  CGPoint pt = [touch locationInView:self.view] ;
  printf( "touchesCancelled %lu (%.1f %.1f)\n", [touches count], pt.x, pt.y ) ;
}

// Drawing
- (void) drawView:(id)sender
{
  [renderer render];
}

- (void) startAnimation
{
  puts( "CALL TO START ANIM" ) ;
	if( !animating )
	{
    puts( "STARTING ANIMATION" ) ;
	  displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];

    // Force 60fps, interval=1 means 60 fps
    [displayLink setFrameInterval:1];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		
		animating = 1 ;
	} else puts ( "WAS ANIM, NOT RESTARTING" ) ;
}

- (void)stopAnimation
{
	if( animating )
	{
    animating = 0 ;
    [displayLink invalidate];
    displayLink = nil;
	}
}

- (void) loadView
{
  // This is how you provide a programmatic view.
  // The VIEW IS the ES2Renderer.  This is better architecture imo.
  puts( "LOADING VIEW" ) ;
  renderer = [[ES2Renderer alloc] init];
  self.view = renderer ;
  self.view.multipleTouchEnabled = true ; // Enable multitouch!  This is so important.
  self.view.contentScaleFactor = [[UIScreen mainScreen] scale] ;
    
  CAEAGLLayer *eaglLayer = (CAEAGLLayer *)renderer.layer;
  eaglLayer.opaque = TRUE;
  eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
  
  animating = 0 ;
  displayLink = nil ;
}

- (void) applicationDidFinishLaunching:(UIApplication *)application
{
  // Override point for customization after application launch.
  puts( "APP DID FINISH LAUNCHING" ) ;
  [self startAnimation];
}

- (void) applicationWillResignActive:(UIApplication *)application
{
  puts( "APP WILL RESIGN ACTIVE" ) ;
	[self stopAnimation];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
  puts( "APP DID BECOME ACTIVE" ) ;
	[self startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  puts( "APP WILL TERM" ) ;
	[self stopAnimation];
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
  puts( "Received memory warning!" ) ; // this only happens ONCE .. like after that your
  // app just gets terminated (regardless of how you respond on this first warning.)
}

@end
