//
//  AnimationSystem.h
//  Osu
//
//  Created by Christopher Luu on 9/2/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Texture2D.h"
#import "OsuFunctions.h"

typedef enum
{
	kAnimationType_None = 0,
	kAnimationType_Move = 1,
	kAnimationType_Scale = 2,
	kAnimationType_Fade = 4,
	kAnimationType_VectorScale = 8,
	kAnimationType_Rotate = 16,
	kAnimationType_Colour = 32,
	kAnimationType_Loop = 64,
	kAnimationType_Event = 128,
} eAnimationType;

@interface AnimatedItem : NSObject
{
@private
	Texture2D *texture;
	double startTime;
	double endTime;
	BOOL absTime;
	int layer;
	int easing;
	CGPoint position;
	float scale;
	float angle;
	float alpha;
	BOOL isTopLeft;
	NSMutableArray *transformations;
}

@property(assign) Texture2D *texture;
@property double startTime;
@property double endTime;
@property BOOL absTime;
@property int layer;
@property int easing;
@property CGPoint position;
@property float scale;
@property float angle;
@property float alpha;
@property BOOL isTopLeft;
@property(assign) NSMutableArray *transformations;

- (void)addTransformation:(eAnimationType)inType startTime:(float)inStartTime endTime:(float)inEndTime, ...;

@end

@interface AnimationSystem : NSObject
{
@private
	NSMutableArray *_animationSet[5];
	BOOL _bRemoveAll;
}

- (void) drawAnimations:(double)curTime layer:(int)layer;
- (AnimatedItem *)addItem:(eAnimationType)inType texture:(Texture2D*)inTexture startTime:(double)inStartTime endTime:(double)inEndTime absolute:(BOOL)absolute layer:(int)inLayer easing:(int)inEasing position:(CGPoint)inPos scale:(float)inScale isTopLeft:(BOOL)isTopLeft, ...;
- (void) scheduleEvent:(eOsuStateActions)action atTime:(double)inTime absolute:(BOOL)absolute;
- (void) scheduleRemoveAllItems;
- (void) removeAllItems;

@end
