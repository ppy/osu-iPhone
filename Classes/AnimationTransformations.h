//
//  AnimationTransformations.h
//  Osu
//
//  Created by Christopher Luu on 12/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnimationSystem.h"

@interface AnimationTransformations : NSObject
{
@protected
	AnimatedItem *item;
	float startTime;
	float endTime;
}

@property(readonly) float startTime;
@property(readonly) float endTime;

- (void)performTransformation:(float)curTime;

@end

@interface ScaleTrans : AnimationTransformations
{
@private
	float startScale;
	float endScale;
}

- (id)initWithItem:(AnimatedItem *)inItem startTime:(float)inStartTime endTime:(float)inEndTime startScale:(float)inStartScale endScale:(float)inEndScale;

@end

@interface MoveTrans : AnimationTransformations
{
@private
	CGPoint startPos;
	CGPoint endPos;
}

- (id)initWithItem:(AnimatedItem *)inItem startTime:(float)inStartTime endTime:(float)inEndTime startPos:(CGPoint)inStartPos endPos:(CGPoint)inEndPos;

@end

@interface FadeTrans : AnimationTransformations
{
@private
	float startAlpha;
	float endAlpha;
}

- (id)initWithItem:(AnimatedItem *)inItem startTime:(float)inStartTime endTime:(float)inEndTime startAlpha:(float)inStartAlpha endAlpha:(float)inEndAlpha;

@end

@interface RotateTrans : AnimationTransformations
{
@private
	float startAngle;
	float endAngle;
}

- (id)initWithItem:(AnimatedItem *)inItem startTime:(float)inStartTime endTime:(float)inEndTime startAngle:(float)inStartAngle endAngle:(float)inEndAngle;

@end
