//
//  OsuFiletype.h
//  Osu
//
//  Created by Christopher Luu on 8/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>

#import "HitObject.h"
#import "OsuEvent.h"
#import "TimingPoint.h"
#import "OsuFunctions.h"
#import "SkinManager.h"

#define SLIDER_TICKS_PER_BEAT 16.0f

typedef enum
{
	kOsuCountdown_Disabled = 0,
	kOsuCountdown_Normal = 1,
	kOsuCountdown_HalfSpeed = 2,
	kOsuCountdown_DoubleSpeed = 3,
} eOsuCountdown;

@interface OsuFiletype : NSObject
{
@private
	NSString *filename;
	SkinManager *_skinManager;

	int osuFileFormat;

	NSString *general_AudioFilename;
	NSString *general_AudioHash;
	int general_AudioLeadIn;
	int general_PreviewTime;
	eOsuCountdown general_Countdown;
	int general_SampleSet;
	float general_StackLeniency;
	int general_Mode;
	int general_Playcount;
	NSString *general_Md5Sum;
	int general_TotalLength;

	tColor colours[5];
	tColor *pColours;
	int numColours;

	NSString *metaData_Title;
	NSString *metaData_Artist;
	NSString *metaData_Creator;
	NSString *metaData_Version;
	NSString *metaData_Source;
	NSString *metaData_Tags;

	int difficulty_HPDrainRate;
	int difficulty_CircleSize;
	int difficulty_OverallDifficulty;
	float difficulty_SliderMultiplier;
	float difficulty_SliderTickrate;
	int difficulty_PreEmpt; // Used in the game
	float difficulty_HitCircleSize; // Used in the game
	float difficulty_EyupStars;

	NSMutableArray *hitObjects;
	NSArray *events;
	NSMutableArray *timingPoints;
	NSMutableArray *highScores;

	float HpMultiplierNormal;
	float HpMultiplierComboEnd;
	float HpDropRate;
}

@property(readonly) NSString *filename;
@property(readonly) int osuFileFormat;

@property(readonly) NSString *general_AudioFilename;
@property(readonly) NSString *general_AudioHash;
@property(readonly) int general_AudioLeadIn;
@property(readonly) int general_PreviewTime;
@property(readonly) eOsuCountdown general_Countdown;
@property(readonly) int general_SampleSet;
@property(readonly) float general_StackLeniency;
@property(readonly) int general_Mode;
@property int general_Playcount;
@property(readonly) int general_TotalLength;

@property(readonly) tColor *pColours;
@property(readonly) int numColours;

@property(readonly) NSString *metaData_Title;
@property(readonly) NSString *metaData_Artist;
@property(readonly) NSString *metaData_Creator;
@property(readonly) NSString *metaData_Version;
@property(readonly) NSString *metaData_Source;
@property(readonly) NSString *metaData_Tags;

@property(readonly) int difficulty_HPDrainRate;
@property(readonly) int difficulty_CircleSize;
@property(readonly) int difficulty_OverallDifficulty;
@property(readonly) float difficulty_SliderMultiplier;
@property(readonly) float difficulty_SliderTickrate;
@property(readonly) int difficulty_PreEmpt;
@property(readonly) float difficulty_HitCircleSize;
@property(readonly) float difficulty_EyupStars;

@property(readonly) NSMutableArray *hitObjects;
@property(readonly) NSArray *events;
@property(readonly) NSMutableArray *timingPoints;

@property(readonly) float HpMultiplierNormal;
@property(readonly) float HpMultiplierComboEnd;
@property(readonly) float HpDropRate;

- (id)initWithFilename:(NSString*)inFilename;
- (id)initWithTitle:(NSString*)inTitle artist:(NSString*)inArtist creator:(NSString*)inCreator filename:(NSString*)inFilename difficultyText:(NSString*)inDifficultyText difficultyEyupStars:(float)inDifficultyEyupStars hpDropRate:(float)inHpDropRate hpMultiplierNormal:(float)inHpMultiplierNormal hpMultiplierComboEnd:(float)inHpMultiplierComboEnd playcount:(int)inPlaycount highscores:(NSString*)inHighscores;

- (BOOL)matchGenericData:(OsuFiletype*)compareTo;
- (void)processHitObjects;
- (void)releaseGameElements;
- (void)calcHPDropRate;
- (BOOL)processFile;

- (void)putFilenameIntoArray:(id)array;
- (void)putMd5SumsIntoArray:(id)array;
- (void)putDifficultyTextIntoArray:(id)array;
- (void)putHpDrainRatesIntoArray:(id)array;
- (void)putHpMultiplierNormalsIntoArray:(id)array;
- (void)putHpMultiplierComboEndsIntoArray:(id)array;
- (void)putDifficultyStarsIntoArray:(id)array;
- (void)putPlaycountIntoArray:(id)array;
- (void)putHighscoresIntoArray:(id)array;

- (NSArray*)getHighscores;
- (BOOL)isHighscore:(int)newScore;
- (void)addHighscore:(int)newScore rank:(int)newRanking name:(NSString*)newName combo:(int)newCombo;

@end
