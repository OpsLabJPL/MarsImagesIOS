//
//  MosaicViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 12/30/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "InfiniteScrollView.h"
#import "Model.h"
#import "MarsScene.h"

@interface MosaicViewController : GLKViewController <UIScrollViewDelegate, InfiniteScrollViewDelegate>
{
    float _rotationX;
    float _lastRotationX;
    float _rotationY;
    float _lastRotationY;
    float _scale;
    float _lastScale;
    CGPoint _lastContentOffset;
    CADisplayLink *_displayLink;
    BOOL motionActive;
}

@property (strong, nonatomic) MarsScene* scene;
@property (strong, nonatomic) GLKBaseEffect *baseEffect;
@property (assign, nonatomic, readwrite) GLKVector3 eyePosition;
@property (assign, nonatomic) GLKVector3 lookAtPosition;
@property (assign, nonatomic) GLKVector3 upVector;
@property (strong, nonatomic) InfiniteScrollView* rotationScroller;
@property (assign, nonatomic, getter = isRecentering) BOOL recentering;
@property (strong, nonatomic) CMMotionManager* motionManager;
@property (strong, nonatomic) NSOperationQueue* motionQueue;
@property (weak, nonatomic) IBOutlet UILabel* azimuthLabel;
@property (weak, nonatomic) IBOutlet UILabel* elevationLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *flipButton;

- (void) setupRotationScroller;
- (void) setupBaseEffect;
- (void) handleMWPhotoLoadingDidEndNotification:(NSNotification *)notification;
- (void) toggleMotion:(id)sender;
- (void) processMotion:(CMDeviceMotion*)motion;
- (void) updateHeadingDisplay;

@end
