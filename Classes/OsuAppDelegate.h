//
//  OsuAppDelegate.h
//  Osu
//
//  Created by Christopher Luu on 7/30/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioPlayer.h>
#import "Texture2D.h"
#import "Beatmap.h"
#import "OsuFiletype.h"
#import "OsuEvent.h"
#import "OsuPlayer.h"
#import "AnimationSystem.h"
#import "SkinManager.h"
#import "OsuSongSelection.h"
#import "BeatmapManager.h"
#import "SettingsManager.h"

@class EAGLView;

enum {
	kHitWindow_300,
	kHitWindow_100,
	kHitWindow_50,
	kNumHitWindows
};

typedef enum
{
	kOsuStates_LoadingBeatmaps,
	kOsuStates_MainMenu,
	kOsuStates_OptionsMenu,
	kOsuStates_SongSelection,
	kOsuStates_Ranking,
	kOsuStates_GameInPlay,
	kOsuStates_GamePaused,
	kNumStates,
} eOsuStates;

@interface OsuAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate, AVAudioPlayerDelegate>
{
@private
	IBOutlet UIWindow *window;
	IBOutlet EAGLView *glView;

	/* Osu variables */
	AnimationSystem *_animationSystem;
	SkinManager *_skinManager;

	Texture2D **_textures;
	Beatmap *_beatMap;
	OsuFiletype *_curOsuFile;
	NSArray *_hitObjects;
	double _curTime;
	double _lastTime;
	int _skipTime;
	int _curHitIndex;
	tColor *_colours;
	//int _nextEventIndex;
	//OsuEvent *_nextEvent;
	int _curTimingPointIndex;
	TimingPoint *_curTimingPoint;
	OsuPlayer *_curPlayer;
	eOsuStates _curState;
	OsuSongSelection *_curSongSelection;
	BeatmapManager *_curBeatmapManager;
	SQLManager *_sqlManager;
	SettingsManager *_settingsManager;
	UInt32 *_sounds;
	AVAudioPlayer *_avPlayer;

	BOOL _blockInput;

	/* Slider variables */
	int _sliderTicksHit;
	BOOL _sliderOnBall;
	BOOL _silderSoundStarted;

	int _ranking; // 0 - SS, 1 - S, 2 - A, 3 - B, 4 - C, 5 - D

	int _hitWindows[kNumHitWindows];
	CGPoint _curTouchPos;

	BOOL _isBreakPeriod;
	UITextField *_enterNameField;

	//NSMutableSet *_optionsViews;
}

- (void)renderScene;
- (Texture2D*)renderSlider:(HitObject*)input;
- (void)handleTouch:(int)type location:(CGPoint)location;
- (void)setBeatmap:(Beatmap *)beatmap;
- (void)setOsufile:(OsuFiletype *)filetype;
- (SQLManager*)getSqlManager;
- (void)startGame:(OsuFiletype *)osuFile;
- (BOOL)doStateAction:(eOsuStateActions)action;
- (void)doScore:(HitObject*)input score:(eHitObjectScore)score x:(float)x y:(float)y player:(OsuPlayer*)player simulate:(BOOL)simulate;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) EAGLView *glView;

@end
