//
//  MosaicViewController.m
//  Mars-Images
//
//  Created by Mark Powell on 12/30/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import "MosaicViewController.h"
#import "MarsImageNotebook.h"

#import "AGLKContext.h"
#import "Math.h"

@implementation MosaicViewController

static const double x_axis[] = X_AXIS;
static const double y_axis[] = Y_AXIS;
//static const double z_axis[] = Z_AXIS;

static const double POSITIVE_VERTICAL_LIMIT = M_PI_2 - 0.001;
static const double NEGATIVE_VERTICAL_LIMIT = -M_PI_2 + 0.001;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    motionActive = NO;
    UIImage* icon = [UIImage imageNamed:@"71-compass.png"];
    _flipButton = [[UIBarButtonItem alloc]
                                   initWithImage:icon
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(toggleMotion:)];
 	_motionManager = [[CMMotionManager alloc] init];
    _motionQueue = [[NSOperationQueue alloc] init];
   
    self.navigationItem.rightBarButtonItem = _flipButton;
    // Listen for MWPhoto notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMWPhotoLoadingDidEndNotification:)
                                                 name:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                               object:nil];

    GLKView* view = (GLKView*)self.view;
    NSAssert([view isKindOfClass:[GLKView class]], @"View controller does not contain a GLKView.");
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    _eyePosition = GLKVector3Make(0.0, 0.0, 0.0);
    _lookAtPosition = GLKVector3Make(0.0, 0.0, -1.0);
    _upVector = GLKVector3Make(0.0, 1.0, 0.0);
    _scale = 1.0f;
    
    view.context = [[AGLKContext alloc]
                    initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [AGLKContext setCurrentContext:view.context];
    
    [self setupBaseEffect];

    _scene = [[MarsScene alloc] init];
    
    // Set the background color stored in the current context
    ((AGLKContext *)view.context).clearColor = GLKVector4Make(
                                                              0.0f, // Red
                                                              0.0f, // Green
                                                              0.0f, // Blue
                                                              1.0f);// Alpha
    
    // Enable depth testing and blending with the frame buffer
    [((AGLKContext *)view.context) enable:GL_DEPTH_TEST];
    [((AGLKContext *)view.context) enable:GL_CULL_FACE];
    [((AGLKContext *)view.context) enable:GL_BLEND];
    
    glDepthMask(GL_TRUE);

    NSArray* latestRMC = [[MarsImageNotebook instance] getLatestRMC];
    NSArray* notesForRMC = [[MarsImageNotebook instance] notesForRMC: latestRMC];
    [_scene addImagesToScene: notesForRMC];
    
    [self setupRotationScroller];
    [self resetScroll];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:pinchGesture];
    
    _azimuthLabel.text = @"Azimuth: 90.0";
    _elevationLabel.text = @"Elevation: 0.0";
}

- (void) setupRotationScroller {
    _rotationScroller = [[InfiniteScrollView alloc] initWithFrame:self.view.bounds];

    [_rotationScroller setDelegate:self];
    [_rotationScroller setRecenterDelegate:self];
    
    [self.view addSubview:_rotationScroller];
}

-(void) update {
    double forwardVector[] = {0.0, 0.0, -1.0f};
    double rotAz[4], rotEl[4];
    double look1[3], look2[3];
    [Math quatva:y_axis a:_rotationX toQ:rotAz];
    [Math quatva:x_axis a:_rotationY toQ:rotEl];
    [Math multqv:rotEl v:forwardVector toU:look1];
    [Math multqv:rotAz v:look1 toU:look2];
    self.lookAtPosition = GLKVector3Make(look2[0], look2[1], look2[2]);
}

- (void) glkView: (GLKView *)view drawInRect: (CGRect)rect {
    
    // Calculate the aspect ratio for the scene and setup a
    // perspective projection
    const GLfloat aspectRatio = (GLfloat)view.drawableWidth / (GLfloat)view.drawableHeight;

    // Clear back frame buffer colors (erase previous drawing)
    // Clear back frame buffer (erase previous drawing)
    [((AGLKContext *)view.context) clear:GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT];
    
    // Configure the point of view including animation
    [self preparePointOfViewWithAspectRatio:aspectRatio];

    [_scene drawImages: _baseEffect];
    
    GLenum error = glGetError();
    if (GL_NO_ERROR != error) {
        NSLog(@"GL Error: 0x%x", error);
    }
}

- (void) setupBaseEffect {
    _baseEffect = [[GLKBaseEffect alloc] init];
//    _baseEffect.useConstantColor = GL_TRUE;
//    _baseEffect.constantColor = GLKVector4Make(1.f, 1.f, 1.f, 1.f);
    
    _baseEffect.light0.enabled = GL_TRUE;
    _baseEffect.light0.ambientColor = GLKVector4Make(1.0f, // Red
                                                     1.0f, // Green
                                                     1.0f, // Blue
                                                     1.0f);// Alpha
    _baseEffect.light0.diffuseColor = GLKVector4Make(1.0f, // Red
                                                     1.0f, // Green
                                                     1.0f, // Blue
                                                     1.0f);// Alpha
    _baseEffect.light0.position = GLKVector4Make(0.f,
                                                 0.f,
                                                 0.f,
                                                 1.f);
    _baseEffect.light0.constantAttenuation = 0.0f; //WTF WHY DID THIS WORK???!?!!!??!! I HATE NOT KNOWING WHY!!!
}

- (void) preparePointOfViewWithAspectRatio: (GLfloat)aspectRatio
{
    // Do this here instead of -viewDidLoad because we don't
    // yet know aspectRatio in -viewDidLoad.
    self.baseEffect.transform.projectionMatrix =
    GLKMatrix4MakePerspective(
                              GLKMathDegreesToRadians(80.f/_scale),// /* old field of view was 85.0f */
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

- (void) viewWillDisappear: (BOOL)animated {
    [_motionManager stopDeviceMotionUpdates];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                  object:nil];

}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    GLKView *view = (GLKView*)self.view;
    [AGLKContext setCurrentContext:view.context];
    
    [_scene deleteImages];

    ((GLKView*)self.view).context = nil;
    [EAGLContext setCurrentContext:nil];
}

- (void) handleMWPhotoLoadingDidEndNotification: (NSNotification *)notification {
    id <MWPhoto> photo = [notification object];
    if ([photo underlyingImage]) {
        // Successful load
        [_scene makeTexture:[photo underlyingImage] withTitle:((MarsPhoto*)photo).note.title grayscale:[((MarsPhoto*)photo) isGrayscale]];
    }
}

- (void) toggleMotion:(id)sender {
    motionActive = !motionActive;
    if (motionActive) {
        _motionManager.deviceMotionUpdateInterval = 0.1f;
        if (([CMMotionManager availableAttitudeReferenceFrames] & CMAttitudeReferenceFrameXTrueNorthZVertical) != 0) {
            [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical
                                                                toQueue: _motionQueue
                                                            withHandler: ^(CMDeviceMotion *motion, NSError *error) {
                                                                [self processMotion:motion];
                                                            }];
        }
        [_motionManager startDeviceMotionUpdatesToQueue:_motionQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
            [self processMotion:motion];
        }];
        _flipButton.tintColor = [UIColor colorWithRed:0.722 green:0.882 blue:0.169 alpha:1];

    } else {
        [_motionManager stopDeviceMotionUpdates];
//        [self resetScroll];
        _flipButton.tintColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    }
}

- (void) processMotion: (CMDeviceMotion*) motion {
//    NSLog(@"Roll: %.2f Pitch: %.2f Yaw: %.2f", motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw);
//    _rotationY = motion.attitude.roll - M_PI_2;
    _rotationY = -(motion.attitude.roll + M_PI_2);
//    _rotationX = motion.attitude.yaw - M_PI;
    _rotationX = motion.attitude.yaw + M_PI;
    NSLog(@"Rotation X: %.2f Y: %.2f", _rotationX, _rotationY);
    dispatch_async(dispatch_get_main_queue(), ^{
        _lastRotationX = _rotationX;
        _lastRotationY = _rotationY;
        [self updateHeadingDisplay];
    });
}

-(void) handlePinch: (UIPinchGestureRecognizer*)sender {
    // Constants to adjust the max/min values of zoom
    if (sender.state == UIGestureRecognizerStateBegan) {
        _lastScale = _scale;
    }
    const float kMaxScale = 16.0;
    const float kMinScale = 0.75;
    float newScale = _lastScale * [sender scale];
    newScale = MIN(newScale, kMaxScale);
    newScale = MAX(newScale, kMinScale);
    _scale = newScale;

    if (sender.state == UIGestureRecognizerStateEnded) {
        _lastScale = _scale;
    }
    [self resetScroll];
}

#pragma mark - UIScrollViewDelegate

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(angle) ((angle) / M_PI * 180.0)
- (void) scrollViewDidScroll: (UIScrollView *) scrollView
{
    if (self.isRecentering || motionActive)
        return;
    
//    if (_lastRotationX != _rotationX || _lastRotationY != _rotationY) {
//        NSLog(@"Rotation x, y: %f, %f", _rotationX, _rotationY);
//    }
    // update the model's rotation based on the scroll view's offset
    CGPoint offset = [self.rotationScroller contentOffset];
    _rotationX = _lastRotationX + DEGREES_TO_RADIANS((_lastContentOffset.x - offset.x)*0.2/_scale);
    _rotationY = _lastRotationY + DEGREES_TO_RADIANS((_lastContentOffset.y - offset.y)*0.2/_scale);
    if (_rotationY > POSITIVE_VERTICAL_LIMIT) _rotationY = POSITIVE_VERTICAL_LIMIT;
    if (_rotationY < NEGATIVE_VERTICAL_LIMIT) _rotationY = NEGATIVE_VERTICAL_LIMIT;
    [self updateHeadingDisplay];
}

- (void) scrollViewWillBeginDragging: (UIScrollView *) scrollView
{
    [self startDisplayLinkIfNeeded];
}

- (void) scrollViewDidEndDecelerating: (UIScrollView *) scrollView
{
    [self stopDisplayLink];
}

- (void) scrollViewDidEndDragging: (UIScrollView *) scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        [self stopDisplayLink];
}

#pragma mark - InfiniteScrollViewDelegate

- (void) willRecenterScrollView: (InfiniteScrollView *) infiniteScrollView
{
    [self setRecentering:YES];
}

- (void) didRecenterScrollView: (InfiniteScrollView *) infiniteScrollView
{
    [self setRecentering:NO];
    [self resetScroll];
}

- (void)resetScroll
{
    _lastContentOffset = _rotationScroller.contentOffset;
    _lastRotationX = _rotationX;
    _lastRotationY = _rotationY;
}

#pragma mark - Display Link
- (void) startDisplayLinkIfNeeded
{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:UITrackingRunLoopMode];
    }
}

- (void) stopDisplayLink
{
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void) render: (CADisplayLink*) displayLink {
    GLKView* view = (GLKView*)self.view;
    [self update];
    [view display];
}

- (void) updateHeadingDisplay {
    float azDegrees = RADIANS_TO_DEGREES(M_PI*2-_rotationX+M_PI_2);
    while (azDegrees < 0) {azDegrees += 360; }
    while (azDegrees > 360) {azDegrees -= 360; }
    float elDegrees = RADIANS_TO_DEGREES(_rotationY);
    _azimuthLabel.text = [NSString stringWithFormat:@"Azimuth: %03.1f", azDegrees];
    _elevationLabel.text = [NSString stringWithFormat:@"Elevation: %03.1f", elDegrees];
}

@end
