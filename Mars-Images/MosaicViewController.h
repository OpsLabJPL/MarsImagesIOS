//
//  MosaicViewController.h
//  Mars-Images
//
//  Created by Mark Powell on 12/30/13.
//  Copyright (c) 2013 Powellware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "InfiniteScrollView.h"

@interface MosaicViewController : GLKViewController <UIScrollViewDelegate, InfiniteScrollViewDelegate>
{
    GLuint vertexBufferID;
    float _rotation;
    float _lastRotation;
    CGPoint _lastContentOffset;
    CADisplayLink *_displayLink;
}

@property (strong, nonatomic) GLKBaseEffect *baseEffect;
@property (assign, nonatomic, readwrite) GLKVector3 eyePosition;
@property (assign, nonatomic) GLKVector3 lookAtPosition;
@property (assign, nonatomic) GLKVector3 upVector;
@property (strong, nonatomic) InfiniteScrollView* rotationScroller;
@property (assign, nonatomic, getter = isRecentering) BOOL recentering;

@end
