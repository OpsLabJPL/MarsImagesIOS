//
//  InfiniteScrollView.h
//  LearnGL1
//
//  Created by Mark Powell on 10/20/13.
//  Copyright (c) 2013 Mark Powell. All rights reserved.
//

@protocol InfiniteScrollViewDelegate;
@interface InfiniteScrollView : UIScrollView
@property (nonatomic, weak) id<InfiniteScrollViewDelegate> recenterDelegate;
@end
@protocol InfiniteScrollViewDelegate <NSObject>
@optional
-(void)willRecenterScrollView:(InfiniteScrollView *)infiniteScrollView;
-(void)didRecenterScrollView:(InfiniteScrollView *)infiniteScrollView;
@end