//
//  SceneMesh.h
//  
//

#import <GLKit/GLKit.h>
#import "AGLKVertexAttribArrayBuffer.h"

/////////////////////////////////////////////////////////////////
// Type used to store vertex attributes
typedef struct
{
   GLKVector3 position;
   GLKVector2 texCoords0;
}
SceneMeshVertex;


@interface SceneMesh : NSObject

@property (strong, nonatomic, readwrite) AGLKVertexAttribArrayBuffer *vertexAttributeBuffer;
@property (strong, nonatomic, readwrite) NSData *vertexData;


- (id)initWithVertexAttributeData:(NSData *)vertexAttributes;

- (id)initWithPositionCoords:(const GLfloat *)somePositions
   texCoords0:(const GLfloat *)someTexCoords0
   numberOfPositions:(size_t)countPositions;
   
- (void)prepareToDraw;

- (void)drawUnindexedWithMode:(GLenum)mode
   startVertexIndex:(GLint)first
   numberOfVertices:(GLsizei)count;

- (void)makeDynamicAndUpdateWithVertices:
   (const SceneMeshVertex *)someVerts
   numberOfVertices:(size_t)count;

@end
