//
//  AnimationSystem.m
//  Osu
//
//  Created by Christopher Luu on 9/2/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AnimationSystem.h"
#import "OsuAppDelegate.h"
#import "AnimationTransformations.h"

@implementation AnimatedItem

@synthesize texture;
@synthesize startTime;
@synthesize endTime;
@synthesize absTime;
@synthesize layer;
@synthesize easing;
@synthesize position;
@synthesize scale;
@synthesize angle;
@synthesize alpha;
@synthesize isTopLeft;
@synthesize transformations;

- (id)init
{
	if (self = [super init])
	{
		texture = NULL;
		return self;
	}
	return NULL;
}

- (void)addTransformation:(eAnimationType)inType startTime:(float)inStartTime endTime:(float)inEndTime, ...
{
	AnimationTransformations *newItem;
	if (!transformations)
		transformations = [[NSMutableArray alloc] init];

	va_list argumentList;
	va_start(argumentList, inEndTime);
	if (inType & kAnimationType_Move)
	{
		CGPoint tmp = va_arg(argumentList, CGPoint);
		newItem = [[MoveTrans alloc] initWithItem:self startTime:inStartTime endTime:inEndTime startPos:tmp endPos:va_arg(argumentList, CGPoint)];
		[transformations addObject:newItem];
		[newItem release];
	}
	if (inType & kAnimationType_Scale)
	{
		float tmp = va_arg(argumentList, double);
		newItem = [[ScaleTrans alloc] initWithItem:self startTime:inStartTime endTime:inEndTime startScale:tmp endScale:va_arg(argumentList, double)];
		[transformations addObject:newItem];
		[newItem release];
	}
	if (inType & kAnimationType_Fade)
	{
		float tmp = va_arg(argumentList, double);
		newItem = [[FadeTrans alloc] initWithItem:self startTime:inStartTime endTime:inEndTime startAlpha:tmp endAlpha:va_arg(argumentList, double)];
		[transformations addObject:newItem];
		[newItem release];
	}
	if (inType & kAnimationType_Rotate)
	{
		float tmp = va_arg(argumentList, double);
		newItem = [[RotateTrans alloc] initWithItem:self startTime:inStartTime endTime:inEndTime startAngle:tmp endAngle:va_arg(argumentList, double)];
		[transformations addObject:newItem];
		[newItem release];
	}
	va_end(argumentList);
}

- (void)dealloc
{
	if (transformations)
		[transformations release];
	[texture release];
	[super dealloc];
}

@end

@implementation AnimationSystem

- (id) init
{
	if (self = [super init])
	{
		for (int i = 0; i < 5; i++)
			_animationSet[i] = [[NSMutableArray alloc] init];
		_bRemoveAll = NO;
		return self;
	}
	return NULL;
}

- (void) scheduleEvent:(eOsuStateActions)action atTime:(double)inTime absolute:(BOOL)absolute
{
	AnimatedItem *newItem = [[AnimatedItem alloc] init];
	newItem.startTime = newItem.endTime = inTime;
	newItem.absTime = absolute;
	newItem.layer = kLayerType_Event;
	newItem.easing = action;

	//NSLog(@"Scheduled event... Now=%f, startTime=%f, absolute=%d, action=%d", CFAbsoluteTimeGetCurrent(), newItem.startTime, newItem.absTime, newItem.layer);
	@synchronized(_animationSet[0])
	{
		[_animationSet[0] addObject:newItem];
	}
	[newItem release];
}

- (AnimatedItem *)addItem:(eAnimationType)inType texture:(Texture2D*)inTexture startTime:(double)inStartTime endTime:(double)inEndTime absolute:(BOOL)absolute layer:(int)inLayer easing:(int)inEasing position:(CGPoint)inPos scale:(float)inScale isTopLeft:(BOOL)isTopLeft, ...
{
	AnimatedItem *newItem = [[AnimatedItem alloc] init];

	newItem.texture = [inTexture retain];
	newItem.startTime = inStartTime;
	newItem.endTime = inEndTime;
	newItem.absTime = absolute;
	newItem.layer = inLayer;
	newItem.easing = inEasing;
	newItem.isTopLeft = isTopLeft;
	if (isTopLeft)
		inPos = CGPointMake(inPos.x + inTexture.contentSize.width / 2.0f * inScale, inPos.y + inTexture.contentSize.height / 2.0f * inScale);
	newItem.position = inPos;
	newItem.scale = inScale;
	newItem.alpha = 1.0f;

	va_list argumentList;
	va_start(argumentList, isTopLeft);
	if (inType & kAnimationType_Move)
		[newItem addTransformation:kAnimationType_Move startTime:inStartTime endTime:inEndTime, inPos, va_arg(argumentList, CGPoint)];

	if (inType & kAnimationType_Scale)
		[newItem addTransformation:kAnimationType_Scale startTime:inStartTime endTime:inEndTime, inScale, va_arg(argumentList, double)];

	if (inType & kAnimationType_Fade)
	{
		float tmp = va_arg(argumentList, double);
		[newItem addTransformation:kAnimationType_Fade startTime:inStartTime endTime:inEndTime, tmp, va_arg(argumentList, double)];
	}

	if (inType & kAnimationType_Rotate)
	{
		float tmp = va_arg(argumentList, double);
		[newItem addTransformation:kAnimationType_Rotate startTime:inStartTime endTime:inEndTime, tmp, va_arg(argumentList, double)];
	}
	va_end(argumentList);

	@synchronized(_animationSet[inLayer])
	{
		[_animationSet[inLayer] addObject:newItem];
	}
	[newItem release];
	return newItem;
}

- (void) removeAllItems
{
	for (int i = 0; i < 5; i++)
	{
		@synchronized(_animationSet[i])
		{
			[_animationSet[i] removeAllObjects];
		}
	}
}

- (void) drawAnimations:(double)curTime layer:(int)layer
{
	AnimatedItem *tmp;
	NSMutableArray *toRemove = [[NSMutableArray alloc] init];
	NSMutableArray *toRemoveTransformations = [[NSMutableArray alloc] init];

	@synchronized(_animationSet[layer])
	{
		for (tmp in _animationSet[layer])
		{
			if ((tmp.absTime ? CFAbsoluteTimeGetCurrent() : curTime) < tmp.startTime)
				continue;
			if ((tmp.absTime ? CFAbsoluteTimeGetCurrent() : curTime) >= tmp.endTime)
			{
				if (tmp.layer == kLayerType_Event) // an event
					[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] doStateAction:tmp.easing];
				[toRemove addObject:tmp];
				continue;
			}

			for (AnimationTransformations *t in tmp.transformations)
			{
				if ((tmp.absTime ? CFAbsoluteTimeGetCurrent() : curTime) < t.startTime)
					continue;
				else if (t.endTime <= (tmp.absTime ? CFAbsoluteTimeGetCurrent() : curTime))
					[toRemoveTransformations addObject:t];
				[t performTransformation:(tmp.absTime ? CFAbsoluteTimeGetCurrent() : curTime)];
			}
			[tmp.transformations removeObjectsInArray:toRemoveTransformations];
			[toRemoveTransformations removeAllObjects];

			glPushMatrix();
			glColor4f(1.0f, 1.0f, 1.0f, tmp.alpha);
			glTranslatef(tmp.position.x, tmp.position.y, 0.0f);
			glScalef(tmp.scale, -tmp.scale, 1.0f);
			glRotatef(tmp.angle, 0.0f, 0.0f, -1.0f);
			[tmp.texture drawAtPoint:CGPointMake(0, 0)];
			glPopMatrix();
		}
		[_animationSet[layer] removeObjectsInArray:toRemove];
	}
	[toRemove release];
	[toRemoveTransformations release];
	if (_bRemoveAll)
	{
		_bRemoveAll = NO;
		[self removeAllItems];
	}
}

- (void)scheduleRemoveAllItems
{
	_bRemoveAll = YES;
}

- (void)dealloc
{
	for (int i = 0; i < 5; i++)
		[_animationSet[i] release];
	[super dealloc];
}

@end
