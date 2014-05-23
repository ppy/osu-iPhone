//
//  OsuEvent.h
//  Osu
//
//  Created by Christopher Luu on 8/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
	kOsuEventType_Background = 0,
	kOsuEventType_BreakPeriod = 2,
	kOsuEventType_ColorTransformation = 3,
	kOsuEventType_StaticSprite = 4,
	kOsuEventType_Animation = 6,
} eOsuEventType;

typedef enum
{
	kLayerType_Background = 0,
	kLayerType_Failing = 1,
	kLayerType_Passing = 2,
	kLayerType_Foreground = 3,
	kLayerType_BelowForeground = 4,
	kLayerType_Event,
} eLayerType;

@interface OsuEvent : NSObject
{
@private
	eOsuEventType type;
	eLayerType layer;
	NSString *filepath;
	int x;
	int y;
}

@property eOsuEventType type;
@property eLayerType layer;
@property(assign) NSString *filepath;
@property int x;
@property int y;

@end
