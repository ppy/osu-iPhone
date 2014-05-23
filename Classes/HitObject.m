//
//  HitObject.m
//  Osu
//
//  Created by Christopher Luu on 8/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HitObject.h"

@implementation HitObject
@synthesize x;
@synthesize y;
@synthesize startTime;
@synthesize objectType;
@synthesize soundType;
@synthesize endTime;
@synthesize repeatCount;
@synthesize sliderCurveType;
@synthesize pSliderCurvePoints;
@synthesize rotationRequirement_sliderCurveCount;
@synthesize maxAccel;
@synthesize colourIndex;
@synthesize comboNum;
@synthesize score;
@synthesize stackSize;
@synthesize sliderTexture;
@synthesize sliderPerEndpointSounds;

- (id)init
{
	if (self = [super init])
	{
		score = kHitObjectScore_None;
		sliderTexture = NULL;
		sliderPerEndpointSounds = NULL;
		return self;
	}
	return NULL;
}

- (void)dealloc
{
	if (pSliderCurvePoints)
		free(pSliderCurvePoints);
	if (sliderTexture)
		[sliderTexture release];
	if (sliderPerEndpointSounds)
		[sliderPerEndpointSounds release];
	[super dealloc];
}

@end
