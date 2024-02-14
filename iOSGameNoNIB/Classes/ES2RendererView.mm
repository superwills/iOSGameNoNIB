#import "ES2RendererView.h"
#import "Shaders.h"
#include "matrix.h"

bool GL_OK() {
  GLenum err = glGetError() ;
  if( err != GL_NO_ERROR )
    printf( "GLERROR %d\n", err ) ;
  return err == GL_NO_ERROR ;
}

// uniform index
enum {
	UNIFORM_MODELVIEW_PROJECTION_MATRIX,
	NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// attribute index
enum VertexAttributes {
	Position,
	Color,
	NumberOfAttributes
};

// C-D
// |\|
// A-B
const GLfloat squareVertices[] = {
  -0.5f, -0.5f,
  0.5f,  -0.5f,
  -0.5f,  0.5f,
  0.5f,   0.5f,
};

const GLushort squareIndices[] = {
  0, 1, 2, 3
};

const GLubyte squareColors[] = {
  255,   0,   0, 255,
  0,   255,   0, 255,
  0,     0, 255, 255,
  255, 255, 255, 255,
};

@implementation ES2RendererView

// This is required to prevent system fuckup,
//
// -[CALayer setDrawableProperties:]: unrecognized selector sent to instance 0x8b18330
// *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[CALayer setDrawableProperties:]:
// 6.
+ (Class) layerClass {
  puts("6. [ES2RendererView layerClass]");
  return [CAEAGLLayer class];
}

// 5.
- (ES2RendererView*) init {
  puts("5. [ES2RendererView init]");
  self = [super init];
  if ( !self )  return self;
  
  context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  if( !context || ![EAGLContext setCurrentContext:context] || ![self loadShaders] )
  {
    return nil;
  }
  
  // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
  glGenFramebuffers(1, &defaultFramebufferId);  GL_OK();
  glGenRenderbuffers(1, &colorRenderbufferId);  GL_OK();
  glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebufferId);  GL_OK();
  glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbufferId);  GL_OK();
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbufferId);  GL_OK();
  
  // Generate the vertex/index buffer IDs
  glGenBuffers(1, &vertexBufferId);  GL_OK();
  glGenBuffers(1, &colorBufferId);  GL_OK();
  glGenBuffers(1, &indexBufferId);  GL_OK();
  
  if (!vertexBufferId || !colorBufferId || !indexBufferId) {
    puts("A BUFFER GEN FAILED");
    exit(1);
  }
  
  // Now we upload our data to the GPU. We do this ONCE, at the start of the program,
  // then redraw from these same vertices over and over.
  
  // I'm going to specify the vertex buffer data:
  glBindBuffer(GL_ARRAY_BUFFER, vertexBufferId);  GL_OK();
  
  // Specify the data using glBufferData:
  // Gotcha: The specification of data to glBufferData is DIFFERENT THAN glVertexAttribPointer
  // glBufferData DOES NOT have an entry for "number of elements"
  // I've created variables here to spell out how the values are found
  const int numberOfVertices = 4;
  int valuesPerVertex = 2;  // There are __2__ values per vertex for position data (x, y)
  glBufferData(
    GL_ARRAY_BUFFER,  // What type of buffer ("ARRAY"=vertex buffer, "ELEMENT_ARRAY"=index buffer)
    numberOfVertices * valuesPerVertex * sizeof(GLfloat), // Number of bytes to upload to the GPU
    squareVertices, // The pointer to the data array from which to copy the data
    GL_STATIC_DRAW  // The data array will never change, so no need to refresh it ever
  );
  GL_OK();
  
  glBindBuffer(GL_ARRAY_BUFFER, colorBufferId);  GL_OK();
  valuesPerVertex = 4;  // There are __4__ values per vertex for color data (rgba)
  glBufferData(GL_ARRAY_BUFFER, numberOfVertices * valuesPerVertex * sizeof(GLubyte), squareColors, GL_STATIC_DRAW);  GL_OK();
  
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferId);  GL_OK();
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, 4 * sizeof(GLushort), squareIndices, GL_STATIC_DRAW);  GL_OK();
  
  // Turn these off so you don't confuse OpenGL when drawing by having this still set
  glBindBuffer(GL_ARRAY_BUFFER, 0);  GL_OK();
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);  GL_OK();
  
	return self;
}

// 7.
- (BOOL) loadShaders {
	puts( "7. [ES2RendererView loadShaders]" );
	GLuint vertShader = 0, fragShader = 0;
	NSString *vertShaderPathname, *fragShaderPathname;
	
	// create shader program
	program = glCreateProgram();  GL_OK();
	
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
	glAttachShader(program, vertShader);  GL_OK();
	
	// attach fragment shader to program
	glAttachShader(program, fragShader);  GL_OK();
	
	// bind attribute locations
	// this needs to be done prior to linking
	glBindAttribLocation(program, VertexAttributes::Position, "position");  GL_OK();
	glBindAttribLocation(program, VertexAttributes::Color, "color");  GL_OK();
	
	// link program
	if (!linkProgram(program)) {
		destroyShaders(vertShader, fragShader, program);
		return NO;
	}
	
	// get uniform locations
	uniforms[UNIFORM_MODELVIEW_PROJECTION_MATRIX] = glGetUniformLocation(program, "modelViewProjectionMatrix");  GL_OK();
	
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

// 9.
- (void) layoutSubviews {
  puts( "9. [ES2RendererView layoutSubviews]" ) ;
	[self resizeFromLayer:(CAEAGLLayer*)self.layer];
  [self render];
}

// 10.
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer {
  puts("10. [ES2RendererView resizeFromLayer]");
	// Allocate color buffer backing based on the current layer size
  glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbufferId);  GL_OK();
  [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);  GL_OK();
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);  GL_OK();
	
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
    printf( "Failed to make complete framebuffer object %d", glCheckFramebufferStatus(GL_FRAMEBUFFER) );
    return NO;
  }
  
  return YES;
}

// 11.
- (void) render {
  //puts("11. [ES2RendererView render]");
  // Replace the implementation of this method to do your own custom drawing
  [EAGLContext setCurrentContext:context];
  
  glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebufferId);  GL_OK();
  glViewport(0, 0, backingWidth, backingHeight);  GL_OK();
  
  glClearColor(0.5f, 0.4f, 0.5f, 1.0f);  GL_OK();
  glClear(GL_COLOR_BUFFER_BIT);  GL_OK();

	// use shader program
	glUseProgram( program ) ;  GL_OK();
	
	// handle viewing matrices
	GLfloat proj[16], modelview[16], modelviewProj[16];
	// setup projection matrix (orthographic)
	mat4f_LoadOrtho(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 1.0f, proj);
	// setup modelview matrix (rotate around z)
	mat4f_LoadZRotation(rotz, modelview);
	// projection matrix * modelview matrix
	mat4f_MultiplyMat4f(proj, modelview, modelviewProj);
	//rotz += 1.f * M_PI / 180.0f;
	
	// update uniform values
	glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_PROJECTION_MATRIX], 1, GL_FALSE, modelviewProj);  GL_OK();

  enum RenderMode {VertexArray, VertexBuffer};
  RenderMode renderMode = RenderMode::VertexBuffer;
  
  switch( renderMode ) {
      
    case RenderMode::VertexArray:
    
      // To render data, we have to specify the vertex format of the data first.
      // The data has position & color attributes
      glVertexAttribPointer(
        VertexAttributes::Position, // integer attribute index
        2,                          // Number of data elements per data entry
        GL_FLOAT,                   // Data type of the data entries
        GL_FALSE,                   // Should the data be normalized (between 0 & 1 (can be used for integer color specs))
        0,                          // Stride (number of bytes to skip, used for interleaved data arrays)
        squareVertices              // Data pointer
      );  GL_OK();
      glEnableVertexAttribArray(VertexAttributes::Position);  GL_OK();
      
      // Enable the color vertex attribute
      glVertexAttribPointer(VertexAttributes::Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, squareColors);  GL_OK();
      glEnableVertexAttribArray(VertexAttributes::Color);  GL_OK();
      
      // Draw the vertex array
      glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
      break;
      
    case RenderMode::VertexBuffer:
      
      // When using vertex buffers, we use a 0 for the data pointer.
      glBindBuffer(GL_ARRAY_BUFFER, vertexBufferId);  GL_OK();
      glVertexAttribPointer(VertexAttributes::Position, 2, GL_FLOAT, GL_FALSE, 0, 0);  GL_OK();
      glEnableVertexAttribArray(VertexAttributes::Position);  GL_OK();
      
      // Enable the color vertex attribute
      glBindBuffer(GL_ARRAY_BUFFER, colorBufferId);  GL_OK();
      glEnableVertexAttribArray(VertexAttributes::Color);  GL_OK();
      glVertexAttribPointer(VertexAttributes::Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, 0);  GL_OK();
      
      // Draw either using the index buffer, or not using it!
      const bool useIndexBuffer = true;
      if (useIndexBuffer) {
        // If using the index buffer:
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferId);  GL_OK();
        glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, 0);  GL_OK();
      }
      else {
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);  GL_OK();
      }
      
      break;
  }
  
  glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbufferId);  GL_OK();
  [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void) dealloc {
  puts("[ES2RendererView dealloc]");
	// tear down GL
	if (defaultFramebufferId)
	{
		glDeleteFramebuffers(1, &defaultFramebufferId);  GL_OK();
		defaultFramebufferId = 0;
	}
	
	if (colorRenderbufferId)
	{
		glDeleteRenderbuffers(1, &colorRenderbufferId);  GL_OK();
		colorRenderbufferId = 0;
	}
	
	// realease the shader program object
	if (program)
	{
		glDeleteProgram(program);  GL_OK();
		program = 0;
	}
	
	// tear down context
	if([EAGLContext currentContext] == context)
     [EAGLContext setCurrentContext:nil];
	
	context = nil;

}

@end
