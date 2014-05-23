//
//  OsuFunctions.h
//  Osu
//
//  Created by Christopher Luu on 8/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SQL_MANAGER [(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] getSqlManager]

#define SCREEN_SIZE_X 720
#define SCREEN_SIZE_Y 480

#define GAME_STAGE_X 104.0f
#define GAME_STAGE_Y 71.0f

#define TOP_BAR_HEIGHT 48.0f
#define SCORE_HEIGHT 30.0f
#define COMBO_HEIGHT 44.0f

#define FADE_TIME 800.0f // ms to fade away

#define SIXTY_FRAMES_PER_SECOND (1000.0f/60.0f)

#define HP_COMBO_GEKI 14.0f
#define HP_COMBO_KATU 10.0f
#define HP_COMBO_MU 6.0f
#define HP_HIT_300 6.0f
#define HP_HIT_100 2.2f
#define HP_HIT_50 0.4f
#define HP_SLIDER_REPEAT 4.0f
#define HP_SLIDER_TICK 3.0f

#define HP_BAR_MAXIMUM 200.0f

#define PI 3.141592653585

typedef enum
{
	kOsuStateActions_NoAction,
	kOsuStateActions_GoToHomepage,
	kOsuStateActions_GoToMainMenu,
	kOsuStateActions_GoToOptionsMenu,
	kOsuStateActions_GoToSongSelection,
	kOsuStateActions_GoToGameStart,
	kOsuStateActions_TopIndexUp,
	kOsuStateActions_TopIndexDown,
	kOsuStateActions_PauseContinue,
	kOsuStateActions_PauseRetry,
	kOsuStateActions_PauseBack,
	kOsuStateActions_Ready,
	kOsuStateActions_Count3,
	kOsuStateActions_Count2,
	kOsuStateActions_Count1,
	kOsuStateActions_CountGo,
	kOsuStateActions_UnblockInputs,
	kOsuStateActions_BreakStart,
	kOsuStateActions_BreakEnd,
	kOsuStateActions_ProcessBreakRanking,
	kOsuStateActions_PlaySectionPass,
	kOsuStateActions_PlaySectionFail,
	kOsuStateActions_GoToRankingScreen,
	kOsuStateActions_ToggleNoFail,
	kOsuStateActions_GoToOffsetFinder,
	//	kOsuStateActions_Quit,
} eOsuStateActions;

typedef struct _colorStruct
{
	int r, g, b;
} tColor;

@interface OsuFunctions : NSObject
{

}

+ (void)doAlert:(NSString *)msg withCancel:(BOOL)withCancel delegate:(id)delegate;
+ (float) dist:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2;
+ (float) mapDifficultyRange:(float)difficulty min:(float)min mid:(float)mid max:(float)max;
+ (float) min:(float)x y:(float)y;
+ (float) max:(float)x y:(float)y;
+ (NSString *) md5:(NSString *)str;

@end
