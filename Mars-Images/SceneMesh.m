//
//  SceneMesh.m
//
//

#import "SceneMesh.h"

@interface SceneMesh ()

@end


@implementation SceneMesh

@synthesize vertexAttributeBuffer;
@synthesize vertexData;


/////////////////////////////////////////////////////////////////
// Designated initializer
- (id)initWithVertexAttributeData:(NSData *)vertexAttributes {
    if(nil != (self=[super init]))
    {
        self.vertexData = vertexAttributes;
    }
    
    return self;
}


/////////////////////////////////////////////////////////////////
// Initialize a new instance with the specified sources of
// vertex attributes and element indices. The somePositions
// and someNormals parameters (MWP someNormals removed)
// must both be valid pointers to at
// least countPositions number of coordinates where each
// coordinate has size (3 * GLfloat). If not NULL, someTexCoords0
// must be a valid pointer to countPositions of coordinates where
// each coordinate has size (2 * GLfloat). (MWP indices removed)
- (id)initWithPositionCoords:(const GLfloat *)somePositions
                  texCoords0:(const GLfloat *)someTexCoords0
           numberOfPositions:(size_t)countPositions {
    
    NSParameterAssert(NULL != somePositions);
    NSParameterAssert(0 < countPositions);
    
    NSMutableData *vertexAttributesData =
    [[NSMutableData alloc] init];
    
    // Accumulate vertex attributes into vertexAttributesData
    for (size_t i = 0; i < countPositions; i++) {
        SceneMeshVertex currentVertex;
        
        // Initialize the position coordinates
        currentVertex.position.x = somePositions[i * 3 + 0];
        currentVertex.position.y = somePositions[i * 3 + 1];
        currentVertex.position.z = somePositions[i * 3 + 2];
        
        // Initialize the texture coordinates if there are any
        if (NULL != someTexCoords0) {
            currentVertex.texCoords0.s = someTexCoords0[i * 2 + 0];
            currentVertex.texCoords0.t = someTexCoords0[i * 2 + 1];
        } else {
            currentVertex.texCoords0.s = 0.0f;
            currentVertex.texCoords0.t = 0.0f;
        }
        
        // Append the vertex attributes to data
        [vertexAttributesData appendBytes:&currentVertex
                                   length:sizeof(currentVertex)];
    }
    
    return [self initWithVertexAttributeData:vertexAttributesData];
}


/////////////////////////////////////////////////////////////////
// Cleanup resources
- (void)dealloc {
    //no data in this subclass to clean up
}


/////////////////////////////////////////////////////////////////
// This method prepares the current OpenGL ES 2.0 context for
// drawing with the receiver's vertex attributes and indices.
- (void)prepareToDraw {
    if (nil == self.vertexAttributeBuffer &&
       0 < [self.vertexData length]) {
        // vertex attiributes haven't been sent to GPU yet
        self.vertexAttributeBuffer =
        [[AGLKVertexAttribArrayBuffer alloc]
         initWithAttribStride:sizeof(SceneMeshVertex)
         numberOfVertices:[self.vertexData length] /
         sizeof(SceneMeshVertex)
         bytes:[self.vertexData bytes]
         usage:GL_STATIC_DRAW];
        
        // No longer need local data storage
        self.vertexData = nil;
    }
        
    // Prepare vertex buffer for drawing
    [self.vertexAttributeBuffer
     prepareToDrawWithAttrib:GLKVertexAttribPosition
     numberOfCoordinates:3
     attribOffset:offsetof(SceneMeshVertex, position)
     shouldEnable:YES];
    
    [self.vertexAttributeBuffer
     prepareToDrawWithAttrib:GLKVertexAttribTexCoord0
     numberOfCoordinates:2
     attribOffset:offsetof(SceneMeshVertex, texCoords0)
     shouldEnable:YES];
}


/////////////////////////////////////////////////////////////////
// Draw the entire mesh after it has been prepared for drawing.
// This method does not use vertex element indexing. Vertices
// in the range first to (first+count-1) are drawn in order
// using mode.
- (void)drawUnindexedWithMode:(GLenum)mode
            startVertexIndex:(GLint)first
            numberOfVertices:(GLsizei)count {
    [self.vertexAttributeBuffer drawArrayWithMode:mode
                                 startVertexIndex:first
                                 numberOfVertices:count];
}


/////////////////////////////////////////////////////////////////
// This method sends count sets of vertex attributes read from
// someVerts to the GPU. This method also marks the resulting
// vertex attribute array as a dynamic array prone to frequent
// updates.
- (void)makeDynamicAndUpdateWithVertices:
(const SceneMeshVertex *)someVerts
                        numberOfVertices:(size_t)count {
    NSParameterAssert(NULL != someVerts);
    NSParameterAssert(0 < count);
    
    if (nil == self.vertexAttributeBuffer) {
    // vertex attiributes haven't been sent to GPU yet
        self.vertexAttributeBuffer =
        [[AGLKVertexAttribArrayBuffer alloc]
         initWithAttribStride:sizeof(SceneMeshVertex)
         numberOfVertices:count 
         bytes:someVerts
         usage:GL_DYNAMIC_DRAW];
    } else {
        [self.vertexAttributeBuffer 
         reinitWithAttribStride:sizeof(SceneMeshVertex)
         numberOfVertices:count
         bytes:someVerts];
    }
}

@end
