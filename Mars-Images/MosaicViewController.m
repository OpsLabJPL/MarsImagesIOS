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
#import "ImageUtility.h"
#import "Math.h"
#import <ActionSheetStringPicker.h>

#define NEAR_DISTANCE 0.1f
#define FAR_DISTANCE 8.0f

#define SMALLEST_SIZE 32

@implementation MosaicViewController

typedef enum {
    BACK_BUTTON,
    GOTO_BUTTON,
    FORWARD_BUTTON
} Buttons;

static const double x_axis[] = X_AXIS;
static const double y_axis[] = Y_AXIS;
//static const double z_axis[] = Z_AXIS;

static const double POSITIVE_VERTICAL_LIMIT = M_PI_2 - 0.001;
static const double NEGATIVE_VERTICAL_LIMIT = -M_PI_2 + 0.001;

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    motionActive = NO;
    UIImage* icon = [UIImage imageNamed:@"compass.png"];
    _flipButton = [[UIBarButtonItem alloc]
                                   initWithImage:icon
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(toggleMotion:)];
 	_motionManager = [[CMMotionManager alloc] init];
    _motionQueue = [[NSOperationQueue alloc] init];
   
    self.navigationItem.rightBarButtonItem = _flipButton;

    GLKView* view = (GLKView*)self.view;
    NSAssert([view isKindOfClass:[GLKView class]], @"View controller does not contain a GLKView.");
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    _eyePosition = GLKVector3Make(0.0, 0.0, 0.0);
    _lookAtPosition = GLKVector3Make(0.0, 0.0, -1.0);
    _upVector = GLKVector3Make(0.0, 1.0, 0.0);
    _scale = 1.0f;
    _frustum = AGLKFrustumMakeFrustumWithParameters([self computeFOVRadians], 1.0f, NEAR_DISTANCE, FAR_DISTANCE);
    view.context = [[AGLKContext alloc]
                    initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [AGLKContext setCurrentContext:view.context];
    
    [self setupBaseEffect];

    _scene = [[MarsScene alloc] init];
    _scene.viewController = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];

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
#if TARGET_IPHONE_SIMULATOR
    //Simulator
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
#else
    //device
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
#endif
    glDepthMask(GL_TRUE);
    
    _bestTextureResolutionsForCameras = NSMutableDictionary.new;
    
    NSArray* rmc = [[MarsImageNotebook instance] getNearestRMC];
    [self updateCaption:rmc];
    
    [self setupRotationScroller];
    [self resetScroll];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:pinchGesture];
    
    _azimuthLabel.text = @"Azimuth: 0.0";
    _elevationLabel.text = @"Elevation: 0.0";
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    [_hud setLabelText:@"Loading"];
    
    _segmentedControl = [[UISegmentedControl alloc] init];
    [_segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"left_arrow.png"] atIndex:BACK_BUTTON animated:NO];
    [_segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"binoculars.png"] atIndex:GOTO_BUTTON animated:NO];
    [_segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"right_arrow.png"] atIndex:FORWARD_BUTTON animated:NO];
    _segmentedControl.momentary = YES;
    [_segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    [_segmentedControl sizeToFit];
    [_segmentedControl addTarget:self action:@selector(segmentedControlButtonPressed:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = _segmentedControl;

    //we are initially at the most recent location, don't allow user to go forward
    NSArray* nextRMC = [[MarsImageNotebook instance] getNextRMC:rmc];
    if (nextRMC == nil) {
        [_segmentedControl setEnabled:NO forSegmentAtIndex:FORWARD_BUTTON];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSArray* rmc = [[MarsImageNotebook instance] getNearestRMC];
    [_scene addImagesToScene: rmc];
}

- (void) updateCaption:(NSArray*)rmc {
    int site = ((NSNumber*)[rmc objectAtIndex:0]).intValue;
    int drive = ((NSNumber*)[rmc objectAtIndex:1]).intValue;
    _caption.text = [NSString stringWithFormat:@"%@ at location %d-%d", [MarsImageNotebook instance].missionName, site, drive];
}

- (IBAction)chooseLocation:(id)sender {
    NSArray *locations = [[MarsImageNotebook instance] getNamedLocations].allKeys;
    
    [ActionSheetStringPicker showPickerWithTitle:@"Select a Location"
                                            rows:locations
                                initialSelection:0
                                       doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                           NSLog(@"Picker: %@", picker);
                                           NSLog(@"Selected Index: %ld", (long)selectedIndex);
                                           NSLog(@"Selected Value: %@", selectedValue);
                                           NSArray* chosenRMC = (NSArray*)[[MarsImageNotebook instance] getNamedLocations][selectedValue];
                                           [_scene deleteImages];
                                           if (chosenRMC) {
                                               //update HUD controls and display
                                               NSArray* oneMoreNextRmc = [[MarsImageNotebook instance] getNextRMC:chosenRMC];
                                               [_segmentedControl setEnabled:YES forSegmentAtIndex:BACK_BUTTON];
                                               if (!oneMoreNextRmc) {
                                                   [_segmentedControl setEnabled:NO forSegmentAtIndex:FORWARD_BUTTON];
                                               }
                                               [_hud show:YES];
                                               
                                               //load new image mosaic
                                               [_scene addImagesToScene: chosenRMC];
                                               [self updateCaption:chosenRMC];
                                           }
                                       }
                                     cancelBlock:^(ActionSheetStringPicker *picker) {
                                         NSLog(@"Block Picker Canceled");
                                     }
                                          origin:sender];
}

- (void) defaultsChanged:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) segmentedControlButtonPressed: (id)sender {
    switch (_segmentedControl.selectedSegmentIndex) {
        case BACK_BUTTON: {
            [_scene deleteImages];
            NSArray* prevRMC = [[MarsImageNotebook instance] getPreviousRMC: _scene.rmc];
            if (prevRMC) {
                //update HUD controls and display
                NSArray* oneMorePrevRmc = [[MarsImageNotebook instance] getPreviousRMC:prevRMC];
                [_segmentedControl setEnabled:YES forSegmentAtIndex:FORWARD_BUTTON];
                if (!oneMorePrevRmc) {
                    [_segmentedControl setEnabled:NO forSegmentAtIndex:BACK_BUTTON];
                }
                [_hud show:YES];
                
                //load new image mosaic
                [_scene addImagesToScene: prevRMC];
                [self updateCaption:prevRMC];
            }
            break;
        }
        case GOTO_BUTTON: {
            [self chooseLocation:sender];
            break;
        }
        case FORWARD_BUTTON: {
            [_scene deleteImages];
            NSArray* nextRMC = [[MarsImageNotebook instance] getNextRMC: _scene.rmc];
            if (nextRMC) {
                //update HUD controls and display
                NSArray* oneMoreNextRmc = [[MarsImageNotebook instance] getNextRMC:nextRMC];
                [_segmentedControl setEnabled:YES forSegmentAtIndex:BACK_BUTTON];
                if (!oneMoreNextRmc) {
                    [_segmentedControl setEnabled:NO forSegmentAtIndex:FORWARD_BUTTON];
                }
                [_hud show:YES];
                
                //load new image mosaic
                [_scene addImagesToScene: nextRMC];
                [self updateCaption:nextRMC];
            }
            break;
        }
    }
}

- (void) setupRotationScroller {
    _rotationScroller = [[InfiniteScrollView alloc] initWithFrame:self.view.bounds];

    [_rotationScroller setDelegate:self];
    [_rotationScroller setRecenterDelegate:self];
    
    [self.view addSubview:_rotationScroller];
}

- (void) update {
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
    
    [_scene drawCompass: _baseEffect];
    
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
    GLfloat fovRadians = [self computeFOVRadians];
    self.baseEffect.transform.projectionMatrix =
    GLKMatrix4MakePerspective(fovRadians,
                              aspectRatio,
                              NEAR_DISTANCE,   // Don't make near plane too close
                              FAR_DISTANCE); // Far arbitrarily far enough to contain scene
    
    self.baseEffect.transform.modelviewMatrix =
    GLKMatrix4MakeLookAt(_eyePosition.x, _eyePosition.y, _eyePosition.z,            // Eye position
                         _lookAtPosition.x, _lookAtPosition.y, _lookAtPosition.z,   // Look-at position
                         _upVector.x, _upVector.y, _upVector.z);                    // Up direction
    
    AGLKFrustumSetPerspective(&_frustum, fovRadians, aspectRatio, NEAR_DISTANCE, FAR_DISTANCE);
    AGLKFrustumSetToMatchModelview(&_frustum, self.baseEffect.transform.modelviewMatrix);
}

- (void) viewWillDisappear: (BOOL)animated {
    [_motionManager stopDeviceMotionUpdates];
    [_scene destroy];
    _scene = nil;
    [super viewWillDisappear:YES];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    GLKView *view = (GLKView*)self.view;
    [AGLKContext setCurrentContext:view.context];
    
    [_scene deleteImages];
    [_scene addImagesToScene:_scene.rmc];
}

- (float) computeFOVRadians {
    return GLKMathDegreesToRadians(80.f/_scale);
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
        _flipButton.tintColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    }
}

- (void) processMotion: (CMDeviceMotion*) motion {
    _rotationY = -(motion.attitude.roll + M_PI_2);
    _rotationX = motion.attitude.yaw + M_PI;
//    NSLog(@"Rotation X: %.2f Y: %.2f", _rotationX, _rotationY);
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
    
    [_scene handleZoomChanged];
}

#pragma mark - UIScrollViewDelegate

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(angle) ((angle) / M_PI * 180.0)
- (void) scrollViewDidScroll: (UIScrollView *) scrollView
{
    if (self.isRecentering || motionActive)
        return;
    
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
    float azDegrees = RADIANS_TO_DEGREES(M_PI*2-_rotationX);
    while (azDegrees < 0) {azDegrees += 360; }
    while (azDegrees > 360) {azDegrees -= 360; }
    float elDegrees = RADIANS_TO_DEGREES(_rotationY);
    _azimuthLabel.text = [NSString stringWithFormat:@"Azimuth: %03.1f", azDegrees];
    _elevationLabel.text = [NSString stringWithFormat:@"Elevation: %03.1f", elDegrees];
}

- (void) hideHud {
    [_hud hide:YES];
}

@end
