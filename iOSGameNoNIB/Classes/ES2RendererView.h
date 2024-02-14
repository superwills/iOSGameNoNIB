#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface ES2RendererView : UIView
{
	EAGLContext *context;
	
	// The pixel dimensions of the CAEAGLLayer
	GLint backingWidth;
	GLint backingHeight;
	
	// The OpenGL names for the framebuffer and renderbuffer used to render to this view
	GLuint defaultFramebufferId, colorRenderbufferId;
  
  GLuint vertexBufferId, colorBufferId, indexBufferId;
	
	// the shader program object
	GLuint program;
	
	GLfloat rotz;
	
}

- (ES2RendererView*) init;
- (BOOL) loadShaders;
- (void) layoutSubviews;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;
- (void) render;
- (void) dealloc;

@end

