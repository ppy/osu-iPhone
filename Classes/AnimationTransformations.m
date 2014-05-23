//
//  AnimationTransformations.m
//  Osu
//
//  Created by Christopher Luu on 12/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AnimationTransformations.h"

#define ITER_CALCULATION (curTime > endTime ? 1.0f : (curTime - startTime) / (endTime - startTime))

@implementation AnimationTransformations

@synthesize startTime;
@synthesize endTime;

- (void)performTransformation:(float)curTime
{

}

@end


@implementation ScaleTrans

- (id)initWithItem:(AnimatedItem*)inItem startTime:(float)inStartTime endTime:(float)inEndTime startScale:(float)inStartScale endScale:(float)inEndScale
{
	if (self = [super init])
	{
		item = inItem;
		startTime = inStartTime;
		endTime = inEndTime;
		startScale = inStartScale;
		endScale = inEndScale;
		return self;
	}
	return NULL;
}

- (void)performTransformation:(float)curTime
{
	float iter = ITER_CALCULATION;

	//glScalef(startScale + (endScale - startScale) * iter, -(startScale + (endScale - startScale) * iter), 1.0f);
	item.scale = startScale + (endScale - startScale) * iter;
}

@end

@implementation MoveTrans

- (id)initWithItem:(AnimatedItem *)inItem startTime:(float)inStartTime endTime:(float)inEndTime startPos:(CGPoint)inStartPos endPos:(CGPoint)inEndPos
{
	if (self = [super init])
	{
		item = inItem;
		startTime = inStartTime;
		endTime = inEndTime;
		startPos = inStartPos;
		endPos = inEndPos;
		return self;
	}
	return NULL;
}

- (void)performTransformation:(float)curTime
{
	float iter = ITER_CALCULATION;

	//glTranslatef(startPos.x + (endPos.x - startPos.x) * iter, startPos.y + (endPos.y - startPos.y) * iter, 0.0f);
	item.position = CGPointMake(startPos.x + (endPos.x - startPos.x) * iter, startPos.y + (endPos.y - startPos.y) * iter);
}

@end

@implementation FadeTrans

- (id)initWithItem:(AnimatedItem *)inItem startTime:(float)inStartTime endTime:(float)inEndTime startAlpha:(float)inStartAlpha endAlpha:(float)inEndAlpha
{
	if (self = [super init])
	{
		item = inItem;
		startTime = inStartTime;
		endTime = inEndTime;
		startAlpha = inStartAlpha;
		endAlpha = inEndAlpha;
		return self;
	}
	return NULL;
}

- (void)performTransformation:(float)curTime
{
	float iter = ITER_CALCULATION;

	//glColor4f(1.0f, 1.0f, 1.0f, startAlpha + (endAlpha - startAlpha) * iter);
	item.alpha = startAlpha + (endAlpha - startAlpha) * iter;
}

@end

@implementation RotateTrans

- (id)initWithItem:(AnimatedItem *)inItem startTime:(float)inStartTime endTime:(float)inEndTime startAngle:(float)inStartAngle endAngle:(float)inEndAngle
{
	if (self = [super init])
	{
		item = inItem;
		startTime = inStartTime;
		endTime = inEndTime;
		startAngle = inStartAngle;
		endAngle = inEndAngle;
		return self;
	}
	return NULL;
}

- (void)performTransformation:(float)curTime
{
	float iter = ITER_CALCULATION;

	//glRotatef(startAngle + (endAngle - startAngle) * iter, 0.0f, 0.0f, -1.0f);
	item.angle = startAngle + (endAngle - startAngle) * iter;
}

@end
