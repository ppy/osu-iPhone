//
//  SkinManager.h
//  Osu
//
//  Created by Christopher Luu on 9/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HitObject.h"

typedef enum
{
	kTexture_MenuBackground = 0,
	kTexture_MenuOsu,
	kTexture_MenuFreeplay,
	kTexture_MenuFreeplayOver,
	kTexture_MenuOptions,
	kTexture_MenuOptionsOver,
	kTexture_MenuBack,
	kTexture_MenuButtonBackground,
	kTexture_RankingSSSmall,
	kTexture_RankingSSmall,
	kTexture_RankingASmall,
	kTexture_RankingBSmall,
	kTexture_RankingCSmall,
	kTexture_RankingDSmall,
	kTexture_Star,
	kTexture_SongSelectBackground,
	kTexture_SongSelectTab,
	kTexture_PauseContinue,
	kTexture_PauseRetry,
	kTexture_PauseBack,
	kTexture_HitCircle,
	kTexture_HitCircleOverlay,
	kTexture_ApproachCircle,
	kTexture_SliderScorePoint,
	kTexture_SliderFollowCircle,
	kTexture_SliderPoint10,
	kTexture_SliderPoint30,
	kTexture_ReverseArrow,
	kTexture_SpinnerBackground,
	kTexture_SpinnerApproachCircle,
	kTexture_SpinnerCircle,
	kTexture_SpinnerMetre,
	kTexture_SpinnerSpin,
	kTexture_SpinnerOsu,
	kTexture_SpinnerClear,
	kTexture_ScorebarBackground,
	kTexture_ScorebarColor,
	kTexture_ScorebarKi,
	kTexture_ScorebarKiDanger,
	kTexture_ScorebarKiDanger2,
	kTexture_AreYouReady,
	kTexture_Count3,
	kTexture_Count2,
	kTexture_Count1,
	kTexture_CountGo,
	kTexture_PlayWarningArrow,
	kTexture_ExtraTexture1,
	kTexture_ExtraTexture2,
	kTexture_SectionFail,
	kTexture_SectionPass,
	kTexture_FollowPoint,
	kTexture_PlaySkip,
	kTexture_Hit0,
	kTexture_Hit50,
	kTexture_Hit100,
	kTexture_Hit100k,
	kTexture_Hit300,
	kTexture_Hit300g,
	kTexture_Hit300k,
	kTexture_ScoreTextures,
	kTexture_NumberTextures = kTexture_ScoreTextures + 14,
	kTexture_SliderBallTextures = kTexture_NumberTextures + 10,
	kTexture_RankingTitle = kTexture_SliderBallTextures + 10,
	kTexture_RankingPanel,
	kTexture_RankingGraph,
	kTexture_RankingMaxCombo,
	kTexture_RankingAccuracy,
	kTexture_RankingRetry,
	kTexture_RankingBackToMainMenu,
	kTexture_RankingPerfect,
	kTexture_RankingSS,
	kTexture_RankingS,
	kTexture_RankingA,
	kTexture_RankingB,
	kTexture_RankingC,
	kTexture_RankingD,
	kTexture_TextSearch,
	kTexture_TextNewest,
	kTexture_TextTitle,
	kTexture_TextArtist,
	kTexture_TextHomepage,
	kTexture_BlackPixel,
	kTexture_WhitePixel,
	kTexture_WhiteCircle,
	kNumTextures,
} eSkinManager_Textures;

typedef enum
{
	kSound_NormalHitNormal,
	kSound_NormalHitWhistle,
	kSound_NormalHitFinish,
	kSound_NormalHitClap,
	kSound_NormalSliderSlide,
	kSound_NormalSliderTick,
	kSound_NormalSliderWhistle,
	kSound_SoftHitNormal,
	kSound_SoftHitWhistle,
	kSound_SoftHitFinish,
	kSound_SoftHitClap,
	kSound_SoftSliderSlide,
	kSound_SoftSliderTick,
	kSound_SoftSliderWhistle,
	kSound_SpinnerSpin,
	kSound_SpinnerBonus,
	kSound_MenuHit,
	kSound_MenuBack,
	kSound_MenuClick,
	kSound_Ready,
	kSound_Count3,
	kSound_Count2,
	kSound_Count1,
	kSound_CountGo,
	kSound_ComboBreak,
	kSound_FailSound,
	kSound_Applause,
	kSound_SectionFail,
	kSound_SectionPass,
	kNumSounds,
} eSkinManager_Sounds;

@interface SkinManager : NSObject
{
@private
	NSString *directory;
	Texture2D *_textures[kNumTextures];
	UInt32 _sounds[kNumSounds];
	NSMutableArray *_replacedObjects;
}

@property (readonly) NSString *directory;

- (id)initWithSkin:(NSString*)skinName;
- (Texture2D **)getTextures;
- (UInt32 *)getSounds;
//- (void)initMenuTextures;
//- (void)releaseMenuTextures;
- (void)initRankingTextures;
- (void)releaseRankingTextures;
- (void)initRankingGrade:(int)grade;
- (void)replaceObjectsWithDirectory:(NSString *)inDir;
- (void)restoreReplacedObjects;
- (void)initOnTheFlyTextures;
//- (void)initGameTextures;
//- (void)releaseGameTextures;

@end
