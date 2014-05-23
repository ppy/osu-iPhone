//
//  HitObject.h
//  Osu
//
//  Created by Christopher Luu on 8/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>
#import "Texture2D.h"

typedef enum
{
	kSlider_Catmull,
	kSlider_Bezier,
	kSlider_Linear,
} eSliderCurveTypes;

typedef enum
{
	kHitObject_HitCircle = 1,
	kHitObject_Slider = 2,
	kHitObject_NewCombo = 4,
	kHitObject_Spinner = 8,
} eHitObjectType;

typedef enum
{
	kHitObjectScore_None = -1,
	kHitObjectScore_0,
	kHitObjectScore_50,
	kHitObjectScore_100,
	kHitObjectScore_100k,
	kHitObjectScore_300,
	kHitObjectScore_300g,
	kHitObjectScore_300k,
	kHitObjectScore_SliderTick,
	kHitObjectScore_SliderRepeat,
	kHitObjectScore_SliderEnd,
	kHitObjectScore_SpinnerSpin,
	kHitObjectScore_SpinnerSpinPoints,
	kHitObjectScore_SpinnerBonus,
	kNumHitObjectScores,
} eHitObjectScore;

typedef enum
{
	kHitObjectSound_Normal = 0,
	kHitObjectSound_Whistle = 2,
	kHitObjectSound_Finish = 4,
	kHitObjectSound_Clap = 8,
} eHitObjectSoundType;

@interface HitObject : NSObject {
@private
	float x;
	float y;
	int startTime;
	eHitObjectType objectType;
	int soundType;
	int endTime;
	int repeatCount;
	eSliderCurveTypes sliderCurveType;
	GLfloat *pSliderCurvePoints;
	int rotationRequirement_sliderCurveCount;
	double maxAccel;
	int colourIndex;
	int comboNum;
	eHitObjectScore score;
	int stackSize;
	Texture2D *sliderTexture;
	NSArray *sliderPerEndpointSounds;
}

@property float x;
@property float y;
@property int startTime;
@property eHitObjectType objectType;
@property int soundType;
@property int endTime;
@property int repeatCount;
@property eSliderCurveTypes sliderCurveType;
@property int rotationRequirement_sliderCurveCount;
@property double maxAccel;
@property int colourIndex;
@property int comboNum;
@property GLfloat *pSliderCurvePoints;
@property eHitObjectScore score;
@property int stackSize;
@property(assign) Texture2D *sliderTexture;
@property(assign) NSArray *sliderPerEndpointSounds;

@end
