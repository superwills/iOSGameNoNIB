#import "ES2Renderer.h"
#import "Shaders.h"
#include "matrix.h"

// uniform index
enum {
	UNIFORM_MODELVIEW_PROJECTION_MATRIX,
	NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// attribute index
enum
{
	ATTRIB_VERTEX,
	ATTRIB_COLOR,
	NUM_ATTRIBUTES
};

@implementation ES2Renderer

// This is required to prevent system fuckup,
//
// -[CALayer setDrawableProperties:]: unrecognized selector sent to instance 0x8b18330
// *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[CALayer setDrawableProperties:]: 
+ (Class) layerClass
{
  return [CAEAGLLayer class];
}

// Create an ES 2.0 context
- (ES2Renderer*) init
{
	if( self = [super init] )
	{
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if( !context || ![EAGLContext setCurrentContext:context] || ![self loadShaders] )
		{
      return nil;
    }
    
		// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
		glGenFramebuffers(1, &defaultFramebuffer);
		glGenRenderbuffers(1, &colorRenderbuffer);
		glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
	}
	
	return self;
}
- (void) layoutSubviews
{
  puts( "layoutSubviews" ) ;
	[self resizeFromLayer:(CAEAGLLayer*)self.layer];
  [self render];
}
- (void)render
{
  // Replace the implementation of this method to do your own custom drawing
  const GLfloat squareVertices[] = {
    -0.5f, -0.5f,
    0.5f,  -0.5f,
    -0.5f,  0.5f,
    0.5f,   0.5f,
  };
  const GLubyte squareColors[] = {
    255, 255,   0, 255,
    0,   255, 255, 255,
    0,     0,   0,   0,
    255,   0, 255, 255,
  };

  [EAGLContext setCurrentContext:context];
  
  glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
  glViewport(0, 0, backingWidth, backingHeight);
  
  glClearColor(0.5f, 0.4f, 0.5f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);

	// use shader program
	glUseProgram( program ) ;
	
	// handle viewing matrices
	GLfloat proj[16], modelview[16], modelviewProj[16];
	// setup projection matrix (orthographic)
	mat4f_LoadOrtho(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 1.0f, proj);
	// setup modelview matrix (rotate around z)
	mat4f_LoadZRotation(rotz, modelview);
	// projection matrix * modelview matrix
	mat4f_MultiplyMat4f(proj, modelview, modelviewProj);
	rotz += 1.f * M_PI / 180.0f;
	
	// update uniform values
	glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_PROJECTION_MATRIX], 1, GL_FALSE, modelviewProj);
	
	// update attribute values
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, 1, 0, squareColors); //enable the normalized flag
  glEnableVertexAttribArray(ATTRIB_COLOR);
	
	// draw
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  
  glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
  [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (BOOL)loadShaders {
	
	GLuint vertShader, fragShader;
	NSString *vertShaderPathname, *fragShaderPathname;
	
	// create shader program
	program = glCreateProgram();
	
	// create and compile vertex shader
	vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"vertexShader" ofType:@"vsh"];
	if (!compileShader(&vertShader, GL_VERTEX_SHADER, 1, vertShaderPathname)) {
		destroyShaders(vertShader, fragShader, program);
		return NO;
	}
	
	// create and compile fragment shader
	fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"fragmentShader" ofType:@"fsh"];
	if (!compileShader(&fragShader, GL_FRAGMENT_SHADER, 1, fragShaderPathname)) {
		destroyShaders(vertShader, fragShader, program);
		return NO;
	}
	
	// attach vertex shader to program
	glAttachShader(program, vertShader);
	
	// attach fragment shader to program
	glAttachShader(program, fragShader);
	
	// bind attribute locations
	// this needs to be done prior to linking
	glBindAttribLocation(program, ATTRIB_VERTEX, "position");
	glBindAttribLocation(program, ATTRIB_COLOR, "color");
	
	// link program
	if (!linkProgram(program)) {
		destroyShaders(vertShader, fragShader, program);
		return NO;
	}
	
	// get uniform locations
	uniforms[UNIFORM_MODELVIEW_PROJECTION_MATRIX] = glGetUniformLocation(program, "modelViewProjectionMatrix");
	
	// release vertex and fragment shaders
	if (vertShader) {
		glDeleteShader(vertShader);
		vertShader = 0;
	}
	if (fragShader) {
		glDeleteShader(fragShader);
		fragShader = 0;
	}
	
	return YES;
}

- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer
{
	// Allocate color buffer backing based on the current layer size
  glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
  [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
    printf( "Failed to make complete framebuffer object %d", glCheckFramebufferStatus(GL_FRAMEBUFFER) );
    return NO;
  }
	
  return YES;
}

- (void) dealloc
{
	// tear down GL
	if (defaultFramebuffer)
	{
		glDeleteFramebuffers(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
	
	if (colorRenderbuffer)
	{
		glDeleteRenderbuffers(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	
	// realease the shader program object
	if (program)
	{
		glDeleteProgram(program);
		program = 0;
	}
	
	// tear down context
	if([EAGLContext currentContext] == context)
     [EAGLContext setCurrentContext:nil];
	
	context = nil;
	
}

@end
