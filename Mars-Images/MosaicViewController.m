//
//  MosaicViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 12/30/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MosaicViewController.h"

@implementation MosaicViewController

typedef struct {
    GLKVector3 positionCoords;
}
SceneVertex;

static const SceneVertex vertices[] =
{
    {{-0.5f, -0.5f, -2.0}},
    {{ 0.5f, -0.5f, -2.0}},
    {{-0.5f,  0.5f, -2.0}}
};

- (void)resetScroll
{
    _lastContentOffset = _rotationScroller.contentOffset;
    _lastRotation = _rotation;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    GLKView* view = (GLKView*)self.view;
    NSAssert([view isKindOfClass:[GLKView class]], @"View controller does not contain a GLKView.");
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext: view.context];

    _baseEffect = [[GLKBaseEffect alloc] init];
    _baseEffect.useConstantColor = GL_TRUE;
    _baseEffect.constantColor = GLKVector4Make(1.f, 1.f, 1.f, 1.f);
    
    _baseEffect.light0.enabled = GL_TRUE;
    _baseEffect.light0.ambientColor = GLKVector4Make(
                                                         0.9f, // Red
                                                         0.9f, // Green
                                                         0.9f, // Blue
                                                         1.0f);// Alpha
    _baseEffect.light0.diffuseColor = GLKVector4Make(
                                                         1.0f, // Red
                                                         1.0f, // Green
                                                         1.0f, // Blue
                                                         1.0f);// Alpha
    
    _eyePosition = GLKVector3Make(0.0, 0.0, 0.0);
    _lookAtPosition = GLKVector3Make(0.0, 0.0, -1.0);
    _upVector = GLKVector3Make(0.0, 1.0, 0.0);

    glClearColor(0.f,0.f,0.f,1.f);
    
    glGenBuffers(1, &vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    _rotationScroller = [[InfiniteScrollView alloc] initWithFrame:self.view.bounds];
    [_rotationScroller setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [_rotationScroller setBackgroundColor:[UIColor clearColor]];
    [_rotationScroller setShowsHorizontalScrollIndicator:NO];
    [_rotationScroller setContentSize:CGSizeMake(10000, 0)]; [_rotationScroller setContentOffset:CGPointMake(5000,0)];
    [_rotationScroller setDelegate:self];
    [_rotationScroller setRecenterDelegate:self];
    [self.view addSubview:_rotationScroller];
    [self resetScroll];
}

-(void) update {
//    NSLog(@"Rotation: %3.3f", _rotation); //rotate camera yaw with scroll view rotation
    self.lookAtPosition = GLKVector3Make(-sinf(_rotation),
                                         0.0,
                                         -cosf(_rotation));
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    // Calculate the aspect ratio for the scene and setup a
    // perspective projection
    const GLfloat aspectRatio = (GLfloat)view.drawableWidth / (GLfloat)view.drawableHeight;

    // Clear back frame buffer colors (erase previous drawing)
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    // Configure the point of view including animation
    [self preparePointOfViewWithAspectRatio:aspectRatio];

    _baseEffect.light0.position = GLKVector4Make(
                                                     0.4f,
                                                     0.4f,
                                                     -0.3f,
                                                     0.0f);// Directional light
    [_baseEffect prepareToDraw];
    glDepthMask(true);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL);
    glDrawArrays(GL_TRIANGLES, 0, 3);

    GLenum error = glGetError();
    if(GL_NO_ERROR != error)
    {
        NSLog(@"GL Error: 0x%x", error);
    }
}

- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio
{
    // Do this here instead of -viewDidLoad because we don't
    // yet know aspectRatio in -viewDidLoad.
    self.baseEffect.transform.projectionMatrix =
    GLKMatrix4MakePerspective(
                              GLKMathDegreesToRadians(85.0f),// Standard field of view
                              aspectRatio,
                              0.1f,   // Don't make near plane too close
                              20.0f); // Far arbitrarily far enough to contain scene
    
    self.baseEffect.transform.modelviewMatrix =
    GLKMatrix4MakeLookAt(
                         self.eyePosition.x,      // Eye position
                         self.eyePosition.y,
                         self.eyePosition.z,
                         self.lookAtPosition.x,   // Look-at position
                         self.lookAtPosition.y,
                         self.lookAtPosition.z,
                         self.upVector.x,         // Up direction
                         self.upVector.y,
                         self.upVector.z);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    GLKView *view = (GLKView*)self.view;
    [EAGLContext setCurrentContext: view.context];
    
    if (vertexBufferID != 0) {
        glDeleteBuffers(1, &vertexBufferID);
        vertexBufferID = 0;
    }
    ((GLKView*)self.view).context = nil;
    [EAGLContext setCurrentContext:nil];
//    [self.motionManager stopDeviceMotionUpdates];
//    self.motionManager = nil;
}

#pragma mark - UIScrollViewDelegate

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.isRecentering)
        return;
    
    // update the model's rotation based on the scroll view's offset
    CGPoint offset = [self.rotationScroller contentOffset];
    _rotation = _lastRotation + DEGREES_TO_RADIANS((_lastContentOffset.x - offset.x)*0.2);
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self startDisplayLinkIfNeeded];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self stopDisplayLink];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        [self stopDisplayLink];
}

#pragma mark - InfiniteScrollViewDelegate

-(void)willRecenterScrollView:(InfiniteScrollView *)infiniteScrollView
{
    [self setRecentering:YES];
}

-(void)didRecenterScrollView:(InfiniteScrollView *)infiniteScrollView
{
    [self setRecentering:NO];
    [self resetScroll];
}

#pragma mark - Display Link
-(void)startDisplayLinkIfNeeded
{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:UITrackingRunLoopMode];
    }
}

-(void)stopDisplayLink
{
    [_displayLink invalidate];
    _displayLink = nil;
}

-(void)render:(CADisplayLink*)displayLink {
    GLKView* view = (GLKView*)self.view;
    [self update];
    [view display];
}

@end
