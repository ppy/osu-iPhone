//
//  OsuAppDelegate.m
//  Osu
//
//  Created by Christopher Luu on 7/30/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "OsuAppDelegate.h"
#import "EAGLView.h"
#import "SoundEngine.h"
#import "OsuFunctions.h"
#include <unistd.h>

#define kListenerDistance 1.0  // Used for creating a realistic sound field
#define GET_SOUND_INDEX(x) (x + (_curTimingPoint.sampleSetId ? _curTimingPoint.sampleSetId - 1 : _curOsuFile.general_SampleSet) * kSound_SoftHitNormal)

typedef struct s_OsuHotspot
{
	CGRect bounds;
	float transparency;
	BOOL hasOver;
	eSkinManager_Textures textureID;
	eOsuStateActions action;
} tOsuHotspot;

@implementation OsuAppDelegate

@synthesize window;
@synthesize glView;

tOsuHotspot OsuLoadingBeatmapsHotspots[] = 
{
	{.bounds = {0, 0, 720, 480}, .textureID = kTexture_MenuBackground, .action = kOsuStateActions_NoAction},
	{.bounds = {35, 25, 400, 400}, .textureID = kTexture_MenuOsu, .action = kOsuStateActions_NoAction},
	{.textureID = kNumTextures},
};

tOsuHotspot OsuMainMenuHotspots[] = 
{
	{.bounds = {0, 0, 720, 480}, .textureID = kTexture_MenuBackground, .action = kOsuStateActions_NoAction},
	{.bounds = {205, 125, -1, 80}, .textureID = kTexture_MenuFreeplay, .action = kOsuStateActions_GoToSongSelection, .hasOver = YES},
//	{.bounds = {210, 190, -1, 80}, .textureID = kTexture_MenuMultiplayer, .action = kOsuStateActions_NoAction, .hasOver = YES},
	{.bounds = {205, 235, -1, 80}, .textureID = kTexture_MenuOptions, .action = kOsuStateActions_GoToOptionsMenu, .hasOver = YES},
//	{.bounds = {230, 315, 408, 70}, .textureID = kTexture_MenuExit, .action = kOsuStateActions_Quit},
	{.bounds = {35, 25, 400, 400}, .textureID = kTexture_MenuOsu, .action = kOsuStateActions_GoToSongSelection},
	{.bounds = {0, 410, 280, 70}, .textureID = kTexture_BlackPixel, .transparency=1.0f, .action = kOsuStateActions_GoToHomepage},
	{.textureID = kNumTextures},
};

tOsuHotspot OsuOptionsMenuHotspots[] =
{
//	{.bounds = {0, 0, 720, 480}, .textureID = kTexture_MenuBackground, .action = kOsuStateActions_NoAction},
	{.bounds = {18, 18, 36, 36}, .textureID = kTexture_HitCircle, .action = kOsuStateActions_NoAction},
	{.bounds = {60, 24, 256, 32}, .textureID = kTexture_ExtraTexture1, .action = kOsuStateActions_NoAction},
//	{.bounds = {18, 60, 256, 32}, .textureID = kTexture_ExtraTexture2, .action = kOsuStateActions_NoAction},
	{.bounds = {18, 18, 200, 36}, .textureID = kTexture_BlackPixel, .transparency=1.0f, .action = kOsuStateActions_ToggleNoFail},
//	{.bounds = {18, 54, 200, 36}, .textureID = kTexture_BlackPixel, .transparency=1.0f, .action = kOsuStateActions_GoToOffsetFinder},
	{.bounds = {0, 380, -1, 100}, .textureID = kTexture_MenuBack, .action = kOsuStateActions_GoToMainMenu},
	{.textureID = kNumTextures},
};

tOsuHotspot OsuSongSelectionHotspots[] = 
{
	{.textureID = kNumTextures},
};

tOsuHotspot OsuRankingHotspots[] = 
{
	{.bounds = {25, 30, -1, 450}, .textureID = kTexture_RankingPanel, .action = kOsuStateActions_NoAction},
	{.bounds = {450, 15, -1, 50}, .textureID = kTexture_RankingTitle, .action = kOsuStateActions_NoAction},
	{.bounds = {450, 400, 250, -1}, .textureID = kTexture_RankingBackToMainMenu, .action = kOsuStateActions_PauseBack},
	{.bounds = {450, 335, 250, -1}, .textureID = kTexture_RankingRetry, .action = kOsuStateActions_PauseRetry},
	{.bounds = {25, 100, 90, 90}, .textureID = kTexture_Hit300, .action = kOsuStateActions_NoAction},
	{.bounds = {25, 165, 90, 90}, .textureID = kTexture_Hit100, .action = kOsuStateActions_NoAction},
	{.bounds = {25, 230, 90, 90}, .textureID = kTexture_Hit50, .action = kOsuStateActions_NoAction},
	{.bounds = {215, 100, 90, 90}, .textureID = kTexture_Hit300g, .action = kOsuStateActions_NoAction},
	{.bounds = {215, 165, 90, 90}, .textureID = kTexture_Hit100k, .action = kOsuStateActions_NoAction},
	{.bounds = {215, 230, 90, 90}, .textureID = kTexture_Hit0, .action = kOsuStateActions_NoAction},
	{.bounds = {110, 355, 225, -1}, .textureID = kTexture_RankingGraph, .action = kOsuStateActions_NoAction},
	{.bounds = {30, 305, -1, 25}, .textureID = kTexture_RankingMaxCombo, .action = kOsuStateActions_NoAction},
	{.bounds = {225, 305, -1, 25}, .textureID = kTexture_RankingAccuracy, .action = kOsuStateActions_NoAction},
	{.textureID = kNumTextures},
};

tOsuHotspot OsuGamePausedHotspots[] = 
{
	{.bounds = {0, 0, 720, 480}, .transparency = 0.25f, .textureID = kTexture_BlackPixel, .action = kOsuStateActions_NoAction},
	{.bounds = {210, 200, 300, 87.437185929648241f}, .textureID = kTexture_PauseRetry, .action = kOsuStateActions_PauseRetry},
	{.bounds = {210, 285, 300, 87.437185929648241f}, .textureID = kTexture_PauseBack, .action = kOsuStateActions_PauseBack},
	{.bounds = {210, 115, 300, 87.437185929648241f}, .textureID = kTexture_PauseContinue, .action = kOsuStateActions_PauseContinue},
	{.textureID = kNumTextures},
};

tOsuHotspot *hotspots[kNumStates] =
{
	OsuLoadingBeatmapsHotspots,
	OsuMainMenuHotspots,
	OsuOptionsMenuHotspots,
	OsuSongSelectionHotspots,
	OsuRankingHotspots,
	NULL,
	OsuGamePausedHotspots,
};

- (void) blockInputs
{
	_blockInput = YES;
	[_animationSystem scheduleEvent:kOsuStateActions_UnblockInputs atTime:CFAbsoluteTimeGetCurrent()+0.5f absolute:YES];
}

- (void) textureThread
{
	int i;
	HitObject *tmpHitObject;
	static EAGLContext *context = NULL;
	CGRect rect = [[UIScreen mainScreen] bounds];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[NSThread setThreadPriority:0.0f];

	if (context == NULL)
	{
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1 sharegroup:[glView getSharegroup]];

		[EAGLContext setCurrentContext:context];
		glMatrixMode(GL_PROJECTION);
		glOrthof(0, rect.size.width, 0, rect.size.height, -1, 1);
		glMatrixMode(GL_MODELVIEW);
		
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glEnable(GL_TEXTURE_2D);
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	}
	else
		[EAGLContext setCurrentContext:context];

	while (_curState >= kOsuStates_GameInPlay && _curHitIndex < [_hitObjects count])
	{
		for (i = _curHitIndex; i < [_hitObjects count]; i++)
		{
			tmpHitObject = [_hitObjects objectAtIndex:i];
			if (tmpHitObject.startTime > _curTime + 5000.0f)
			{
				break;
			}
			if ((tmpHitObject.objectType & kHitObject_Slider) && _curTime > tmpHitObject.startTime - 5000.0f && tmpHitObject.sliderTexture == NULL)
			{
				tmpHitObject.sliderTexture = [self renderSlider:tmpHitObject];
			}
		}
		for (i = _curHitIndex - 1; i >= 0; i--)
		{
			tmpHitObject = [_hitObjects objectAtIndex:i];
			// break at the first sign of a sliderTexture that has already been cleared
			if ((tmpHitObject.objectType & kHitObject_Slider) && tmpHitObject.sliderTexture == NULL)
				break;
			if ((tmpHitObject.objectType & kHitObject_Slider) && _curTime > tmpHitObject.endTime + 600.0f)
			{
				[tmpHitObject.sliderTexture release];
				tmpHitObject.sliderTexture = NULL;
			}
		}
	}

	for (i = _curHitIndex - 1; i >= 0; i--)
	{
		tmpHitObject = [_hitObjects objectAtIndex:i];
		// break at the first sign of a sliderTexture that has already been cleared
		if ((tmpHitObject.objectType & kHitObject_Slider) && tmpHitObject.sliderTexture == NULL)
			break;
		if (tmpHitObject.objectType & kHitObject_Slider)
		{
			[tmpHitObject.sliderTexture release];
			tmpHitObject.sliderTexture = NULL;
		}
	}

	if (_curState >= kOsuStates_GameInPlay)
	{
		[NSThread setThreadPriority:1.0f];
		[_skinManager initRankingTextures];
		while (_ranking < 0)
		{}
		[_skinManager initRankingGrade:kTexture_RankingSS+_ranking];
		for (int j = 0; hotspots[kOsuStates_Ranking][j].textureID != kNumTextures; j++)
		{
			if (hotspots[kOsuStates_Ranking][j].bounds.size.width < 0)
				hotspots[kOsuStates_Ranking][j].bounds.size.width = hotspots[kOsuStates_Ranking][j].bounds.size.height * _textures[hotspots[kOsuStates_Ranking][j].textureID].contentSize.width / _textures[hotspots[kOsuStates_Ranking][j].textureID].contentSize.height;
			if (hotspots[kOsuStates_Ranking][j].bounds.size.height < 0)
				hotspots[kOsuStates_Ranking][j].bounds.size.height = hotspots[kOsuStates_Ranking][j].bounds.size.width * _textures[hotspots[kOsuStates_Ranking][j].textureID].contentSize.height / _textures[hotspots[kOsuStates_Ranking][j].textureID].contentSize.width;
		}
		//_curState = kOsuStates_Ranking;
	}
	//[context release];
	[pool release];
}

- (void) setBeatmap:(Beatmap *)beatmap
{
	if (_beatMap)
		[_beatMap release];
	_beatMap = [beatmap retain];
}

- (void)loadBeatmapsThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_curBeatmapManager loadBeatmaps];
	_curState = kOsuStates_MainMenu;
	[pool release];
	sleep(1000);
	[_textures[kTexture_ExtraTexture2] release];
	[_textures[kTexture_ExtraTexture1] release];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	//umask(022);
	// Send stderr to our file
	//FILE *newStderr = freopen("/tmp/redirect.log", "a", stderr);

	application.statusBarOrientation = UIInterfaceOrientationLandscapeRight;

	if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/osu", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]]])
		[[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/osu", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]] withIntermediateDirectories:YES attributes:NULL error:NULL];

	_blockInput = NO;

	_curState = kOsuStates_MainMenu;
	glView.animationInterval = 1.0 / 60.0;

	//Setup sound engine. Run  it at 44Khz to match the sound files
	SoundEngine_Initialize(44100);
	// Assume the listener is in the center at the start. The sound will pan as the position of the rocket changes.
	SoundEngine_SetListenerPosition(0.0, 0.0, kListenerDistance);

	_curState = kOsuStates_LoadingBeatmaps;

	_sqlManager = [[SQLManager alloc] initWithDB:@"osu.sqlite"];
	_settingsManager = [[SettingsManager alloc] initWithSql:_sqlManager];
	_curBeatmapManager = [[BeatmapManager alloc] init];

	_animationSystem = [[AnimationSystem alloc] init];
	_skinManager = [[SkinManager alloc] initWithSkin:@"default"];
	_textures = [_skinManager getTextures];
	_sounds = [_skinManager getSounds];

	[NSThread detachNewThreadSelector:@selector(loadBeatmapsThread) toTarget:self withObject:NULL];

	_curPlayer = [[OsuPlayer alloc] init];
	_curPlayer.name = [_settingsManager getValue:kSettings_PlayerNameKey];

	for (int i = 0; i < kNumStates; i++)
	{
		if (hotspots[i] && i != kOsuStates_Ranking)
		{
			for (int j = 0; hotspots[i][j].textureID != kNumTextures; j++)
			{
				if (hotspots[i][j].bounds.size.width < 0)
					hotspots[i][j].bounds.size.width = hotspots[i][j].bounds.size.height * _textures[hotspots[i][j].textureID].contentSize.width / _textures[hotspots[i][j].textureID].contentSize.height;
				if (hotspots[i][j].bounds.size.height < 0)
					hotspots[i][j].bounds.size.height = hotspots[i][j].bounds.size.width * _textures[hotspots[i][j].textureID].contentSize.height / _textures[hotspots[i][j].textureID].contentSize.width;
			}
		}
	}

	[glView startAnimation];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
	glView.animationInterval = 1.0 / 5.0;
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
	glView.animationInterval = 1.0 / 60.0;
}

- (Texture2D*)renderSlider:(HitObject*)input
{
	Texture2D *retVal;
	float maxX, maxY, minX, minY;
	int i, stepSize;

	minX = maxX = input.pSliderCurvePoints[0];
	minY = maxY = input.pSliderCurvePoints[1];

	for (i = 1; i < input.rotationRequirement_sliderCurveCount; i++)
	{
		minX = [OsuFunctions min:minX y:input.pSliderCurvePoints[i*3]];
		minY = [OsuFunctions min:minY y:input.pSliderCurvePoints[i*3+1]];
		maxX = [OsuFunctions max:maxX y:input.pSliderCurvePoints[i*3]];
		maxY = [OsuFunctions max:maxY y:input.pSliderCurvePoints[i*3+1]];
	}

	input.x = minX;
	input.y = minY;

	//static int ChrisCount = 0;
	//NSLog(@"Rendering Slider to a texture... %f %f %f %f %d", minX, maxX, minY, maxY, ++ChrisCount);

	retVal = [[Texture2D alloc] initBlankTexture:CGSizeMake(ceil(maxX - minX + _curOsuFile.difficulty_HitCircleSize), ceil(maxY - minY + _curOsuFile.difficulty_HitCircleSize))];

	[retVal drawToTexture:YES];

	//glClearColor(0.5f, 0.5f, 0.5f, 0.5f);
	//glClear(GL_COLOR_BUFFER_BIT);

	glTranslatef(-minX + _curOsuFile.difficulty_HitCircleSize / 2.0f, -minY + _curOsuFile.difficulty_HitCircleSize / 2.0f, 0.0f);

	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

	stepSize = [OsuFunctions max:1 y:(10.0f / [OsuFunctions dist:input.pSliderCurvePoints[0] y1:input.pSliderCurvePoints[1] x2:input.pSliderCurvePoints[3] y2:input.pSliderCurvePoints[4]])];

	glBlendFunc(GL_ONE, GL_ONE);
	for (i = 0; i < input.rotationRequirement_sliderCurveCount; i += stepSize)
		[_textures[kTexture_WhiteCircle] drawInRectUpsideDown:CGRectMake(input.pSliderCurvePoints[i*3] - (_curOsuFile.difficulty_HitCircleSize)/2, input.pSliderCurvePoints[i*3+1] - (_curOsuFile.difficulty_HitCircleSize)/2, (_curOsuFile.difficulty_HitCircleSize), (_curOsuFile.difficulty_HitCircleSize))];

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glColor4f((float)(_colours[input.colourIndex].r)/255.0f, (float)(_colours[input.colourIndex].g)/255.0f, (float)(_colours[input.colourIndex].b)/255.0f, 1.0f);
	for (i = 0; i < input.rotationRequirement_sliderCurveCount; i += stepSize)
		[_textures[kTexture_WhiteCircle] drawInRectUpsideDown:CGRectMake(input.pSliderCurvePoints[i*3] - (_curOsuFile.difficulty_HitCircleSize * 0.90f)/2, input.pSliderCurvePoints[i*3+1] - (_curOsuFile.difficulty_HitCircleSize * 0.90f)/2, (_curOsuFile.difficulty_HitCircleSize * 0.90f), (_curOsuFile.difficulty_HitCircleSize * 0.90f))];

	// draw scorepoints
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	for (int i = SLIDER_TICKS_PER_BEAT / _curOsuFile.difficulty_SliderTickrate; i < input.rotationRequirement_sliderCurveCount - 1; i += SLIDER_TICKS_PER_BEAT / _curOsuFile.difficulty_SliderTickrate)
		[_textures[kTexture_SliderScorePoint] drawInRectUpsideDown:CGRectMake(input.pSliderCurvePoints[i*3] - _curOsuFile.difficulty_HitCircleSize/8, input.pSliderCurvePoints[i*3+1] - _curOsuFile.difficulty_HitCircleSize/8, _curOsuFile.difficulty_HitCircleSize/4, _curOsuFile.difficulty_HitCircleSize/4)];

	// Draw last circle
	glColor4f((float)(_colours[input.colourIndex].r)/255.0f, (float)(_colours[input.colourIndex].g)/255.0f, (float)(_colours[input.colourIndex].b)/255.0f, 1.0f);
	[_textures[kTexture_HitCircle] drawInRectUpsideDown:CGRectMake(input.pSliderCurvePoints[(input.rotationRequirement_sliderCurveCount-1)*3] - _curOsuFile.difficulty_HitCircleSize/2, input.pSliderCurvePoints[(input.rotationRequirement_sliderCurveCount-1)*3+1] - _curOsuFile.difficulty_HitCircleSize/2, _curOsuFile.difficulty_HitCircleSize, _curOsuFile.difficulty_HitCircleSize)];
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	[_textures[kTexture_HitCircleOverlay] drawInRectUpsideDown:CGRectMake(input.pSliderCurvePoints[(input.rotationRequirement_sliderCurveCount-1)*3] - _curOsuFile.difficulty_HitCircleSize/2, input.pSliderCurvePoints[(input.rotationRequirement_sliderCurveCount-1)*3+1] - _curOsuFile.difficulty_HitCircleSize/2, _curOsuFile.difficulty_HitCircleSize, _curOsuFile.difficulty_HitCircleSize)];

	// Draw first circle
	glColor4f((float)(_colours[input.colourIndex].r)/255.0f, (float)(_colours[input.colourIndex].g)/255.0f, (float)(_colours[input.colourIndex].b)/255.0f, 1.0f);
	[_textures[kTexture_HitCircle] drawInRectUpsideDown:CGRectMake(input.pSliderCurvePoints[0] - _curOsuFile.difficulty_HitCircleSize/2, input.pSliderCurvePoints[1] - _curOsuFile.difficulty_HitCircleSize/2, _curOsuFile.difficulty_HitCircleSize, _curOsuFile.difficulty_HitCircleSize)];
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	[_textures[kTexture_HitCircleOverlay] drawInRectUpsideDown:CGRectMake(input.pSliderCurvePoints[0] - _curOsuFile.difficulty_HitCircleSize/2, input.pSliderCurvePoints[1] - _curOsuFile.difficulty_HitCircleSize/2, _curOsuFile.difficulty_HitCircleSize, _curOsuFile.difficulty_HitCircleSize)];

	[retVal drawToTexture:NO];

	return retVal;
}
/*
- (void)renderBackground
{
	glPushMatrix();
	glTranslatef(SCREEN_SIZE_X/2.0f, SCREEN_SIZE_Y/2.0f, 0.0f);

	if ((float)_textures[kTexture_Background].contentSize.width / _textures[kTexture_Background].contentSize.height <= (float)SCREEN_SIZE_X/SCREEN_SIZE_Y)
		glScalef((float)SCREEN_SIZE_Y/_textures[kTexture_Background].contentSize.height, -(float)SCREEN_SIZE_Y/_textures[kTexture_Background].contentSize.height, 1.0f);
	else
		glScalef((float)SCREEN_SIZE_X/_textures[kTexture_Background].contentSize.width, -(float)SCREEN_SIZE_X/_textures[kTexture_Background].contentSize.width, 1.0f);

	[_textures[kTexture_Background] drawAtPoint:CGPointMake(0, 0)];
	glPopMatrix();
}
*/
- (int)drawNumber:(int)number x:(int)x y:(int)y upper:(int)upper height:(int)height
{
	if (upper < 0)
	{
		if (number == 0)
		{
			[_textures[kTexture_ScoreTextures] drawInRectUpsideDown:CGRectMake(x, y, -1, height)];
			return x + _textures[kTexture_ScoreTextures].contentSize.width * ((float)height / _textures[kTexture_ScoreTextures].contentSize.height);
		}

		int i = 1;
		for (i = 1; i <= number; i *= 10) {}
		upper = i / 10;
	}
	if (upper == 0)
		return x;

	int i = (number / upper) % 10;
	[_textures[kTexture_ScoreTextures+i] drawInRectUpsideDown:CGRectMake(x, y, -1, height)];
	return [self drawNumber:number x:(x + _textures[kTexture_ScoreTextures+i].contentSize.width * ((float)height / _textures[kTexture_ScoreTextures+i].contentSize.height)) y:y upper:(upper/10) height:height];
}

- (void)renderGameElements
{
	static float displayedCombo = 0.0f;

	// Draw combo
	[_textures[kTexture_ScoreTextures+13] drawInRectUpsideDown:CGRectMake([self drawNumber:(int)displayedCombo x:50.0f y:(SCREEN_SIZE_Y - 10.0f - COMBO_HEIGHT) upper:-1 height:COMBO_HEIGHT], (SCREEN_SIZE_Y - 10.0f - COMBO_HEIGHT), -1, COMBO_HEIGHT)]; // draw Combo
	if (_curPlayer.curCombo < displayedCombo)
		displayedCombo = _curPlayer.curCombo;
	if ((float)_curPlayer.curCombo > displayedCombo)
	{
		if ((float)_curPlayer.curCombo - displayedCombo > 1.0f)
			displayedCombo = _curPlayer.curCombo - 1.05f;
		displayedCombo += 0.05f;

		float iter = displayedCombo - (int)displayedCombo;

		glColor4f(1.0f, 1.0f, 1.0f, 0.6f - iter * 0.6f);
		[_textures[kTexture_ScoreTextures+13] drawInRectUpsideDown:CGRectMake([self drawNumber:(int)_curPlayer.curCombo x:50.0f y:(SCREEN_SIZE_Y - 10.0f - COMBO_HEIGHT - 20.0f * iter) upper:-1 height:(COMBO_HEIGHT + 20.0f * iter)], (SCREEN_SIZE_Y - 10.0f - COMBO_HEIGHT - 20.0f * iter), -1, COMBO_HEIGHT + 20.0f * iter)]; // draw Combo
	}

	[_curPlayer updateDisplayHealth];
	
	// Draw Scorebar
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	[_textures[kTexture_ScorebarBackground] drawInRectUpsideDown:CGRectMake(40, 0, -1, TOP_BAR_HEIGHT)];
	[_textures[kTexture_ScorebarColor] drawInRect:CGRectMake(44, 10, 430 * (_curPlayer.displayedHealth / HP_BAR_MAXIMUM), 10) scaleX:(_curPlayer.displayedHealth / HP_BAR_MAXIMUM) scaleY:1.0f];
	if (_curPlayer.displayedHealth < HP_BAR_MAXIMUM / 8.0f)
		[_textures[kTexture_ScorebarKiDanger2] drawInRectUpsideDown:CGRectMake(24 + 430 * (_curPlayer.displayedHealth / HP_BAR_MAXIMUM), -10, -1, 50)];
	else if (_curPlayer.displayedHealth < HP_BAR_MAXIMUM * 3.0f / 8.0f)
		[_textures[kTexture_ScorebarKiDanger] drawInRectUpsideDown:CGRectMake(24 + 430 * (_curPlayer.displayedHealth / HP_BAR_MAXIMUM), -10, -1, 50)];
	else
		[_textures[kTexture_ScorebarKi] drawInRectUpsideDown:CGRectMake(24 + 430 * (_curPlayer.displayedHealth / HP_BAR_MAXIMUM), -10, -1, 50)];
}

- (void)doScore:(HitObject*)input score:(eHitObjectScore)score x:(float)x y:(float)y player:(OsuPlayer*)player simulate:(BOOL)simulate
{
	static int fullCombo; // 0 none, 1 all 300s, 2 100s and 300s
	BOOL increaseCombo = NO;

	switch (score)
	{
		case kHitObjectScore_300:
		{
			player.score += (300 + 300 * player.curCombo * _curOsuFile.difficulty_OverallDifficulty / 25.0f);
			[player increaseHealth:_curOsuFile.HpMultiplierNormal * HP_HIT_300];
			increaseCombo = YES;

			if (input.comboNum == 1)
				fullCombo = 1;
		}
		break;

		case kHitObjectScore_100:
		{
			player.score += (100 + 100 * player.curCombo * _curOsuFile.difficulty_OverallDifficulty / 25.0f);
			[player increaseHealth:_curOsuFile.HpMultiplierNormal * [OsuFunctions mapDifficultyRange:_curOsuFile.difficulty_HPDrainRate min:HP_HIT_100*8 mid:HP_HIT_100 max:HP_HIT_100]];
			increaseCombo = YES;

			if (fullCombo == 1 || input.comboNum == 1)
				fullCombo = 2;
		}
		break;

		case kHitObjectScore_50:
		{
			player.score += (50 + 50 * player.curCombo * _curOsuFile.difficulty_OverallDifficulty / 25.0f);
			[player increaseHealth:_curOsuFile.HpMultiplierNormal * [OsuFunctions mapDifficultyRange:_curOsuFile.difficulty_HPDrainRate min:HP_HIT_50*8 mid:HP_HIT_50 max:HP_HIT_50]];
			increaseCombo = YES;

			fullCombo = 0;
		}
		break;

		case kHitObjectScore_0:
		{
			if (player.curCombo > player.maxCombo)
				player.maxCombo = player.curCombo;

			[player increaseHealth:[OsuFunctions mapDifficultyRange:_curOsuFile.difficulty_HPDrainRate min:-6 mid:-25 max:-40]];

			fullCombo = 0;
		}
		break;

		case kHitObjectScore_SliderTick:
		{
			player.score += 10;
			[player increaseHealth:_curOsuFile.HpMultiplierNormal * HP_SLIDER_TICK];
			increaseCombo = YES;

			if (!simulate)
				[_animationSystem addItem:(kAnimationType_Move|kAnimationType_Fade) texture:_textures[kTexture_SliderPoint10] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(x+GAME_STAGE_X, y+GAME_STAGE_Y) scale:1.0f isTopLeft:NO, CGPointMake(x+GAME_STAGE_X, y+GAME_STAGE_Y-10.0f), 1.0f, 0.0f];
		}
		break;
	
		case kHitObjectScore_SliderRepeat:
		{
			player.score += 30;
			increaseCombo = YES;
			[player increaseHealth:_curOsuFile.HpMultiplierNormal * HP_SLIDER_REPEAT];

			if (!simulate)
				[_animationSystem addItem:(kAnimationType_Move|kAnimationType_Fade) texture:_textures[kTexture_SliderPoint30] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(x+GAME_STAGE_X, y+GAME_STAGE_Y) scale:1.0f isTopLeft:NO, CGPointMake(x+GAME_STAGE_X, y+GAME_STAGE_Y-10.0f), 1.0f, 0.0f];
		}
		break;

		case kHitObjectScore_SliderEnd:
		{
			player.score += 30;
			[player increaseHealth:_curOsuFile.HpMultiplierNormal * HP_SLIDER_REPEAT];

			if (!simulate)
				[_animationSystem addItem:(kAnimationType_Move|kAnimationType_Fade) texture:_textures[kTexture_SliderPoint30] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(x+GAME_STAGE_X, y+GAME_STAGE_Y) scale:1.0f isTopLeft:NO, CGPointMake(x+GAME_STAGE_X, y+GAME_STAGE_Y-10.0f), 1.0f, 0.0f];
		}
		break;

		case kHitObjectScore_SpinnerSpinPoints:
		{
			[player increaseHealth:_curOsuFile.HpMultiplierNormal * 1.7];
			player.score += 100;
		}
		break;

		case kHitObjectScore_SpinnerBonus:
		{
			player.score += 1100;
			[player increaseHealth:_curOsuFile.HpMultiplierNormal * 2];

			if (!simulate)
			{
				input.repeatCount++;

				if (input.repeatCount > 9)
					[_animationSystem addItem:(kAnimationType_Move|kAnimationType_Fade) texture:_textures[kTexture_ScoreTextures+input.repeatCount/10] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(x+GAME_STAGE_X-150.0f, y+GAME_STAGE_Y+50.0f) scale:1.5f isTopLeft:NO, CGPointMake(x+GAME_STAGE_X-150.0f, y+GAME_STAGE_Y+25.0f), 1.0f, 0.0f];

				[_animationSystem addItem:(kAnimationType_Move|kAnimationType_Fade) texture:_textures[kTexture_ScoreTextures+input.repeatCount%10] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(x+GAME_STAGE_X-90.0f, y+GAME_STAGE_Y+50.0f) scale:1.5f isTopLeft:NO, CGPointMake(x+GAME_STAGE_X-90.0f, y+GAME_STAGE_Y+25.0f), 1.0f, 0.0f];
				[_animationSystem addItem:(kAnimationType_Move|kAnimationType_Fade) texture:_textures[kTexture_ScoreTextures] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(x+GAME_STAGE_X-30.0f, y+GAME_STAGE_Y+50.0f) scale:1.5f isTopLeft:NO, CGPointMake(x+GAME_STAGE_X-30.0f, y+GAME_STAGE_Y+25.0f), 1.0f, 0.0f];
				[_animationSystem addItem:(kAnimationType_Move|kAnimationType_Fade) texture:_textures[kTexture_ScoreTextures] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(x+GAME_STAGE_X+30.0f, y+GAME_STAGE_Y+50.0f) scale:1.5f isTopLeft:NO, CGPointMake(x+GAME_STAGE_X+30.0f, y+GAME_STAGE_Y+25.0f), 1.0f, 0.0f];
				[_animationSystem addItem:(kAnimationType_Move|kAnimationType_Fade) texture:_textures[kTexture_ScoreTextures] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(x+GAME_STAGE_X+90.0f, y+GAME_STAGE_Y+50.0f) scale:1.5f isTopLeft:NO, CGPointMake(x+GAME_STAGE_X+90.0f, y+GAME_STAGE_Y+25.0f), 1.0f, 0.0f];
			}
		}
		break;
	}

	if (increaseCombo)
		player.curCombo++;

	if (score <= kHitObjectScore_300k)
	{
		if (!simulate)
			input.score = score;

		if (_curHitIndex == [_hitObjects count] - 1 || ((HitObject *)[_hitObjects objectAtIndex:_curHitIndex+1]).comboNum == 1) // Last HitObject of the combo
		{
			if (fullCombo == 1)
			{
				[player increaseHealth:(_curOsuFile.HpMultiplierComboEnd * HP_COMBO_GEKI)];
				if (!simulate)
					input.score = kHitObjectScore_300g;
			}
			else if (fullCombo == 2 && score == kHitObjectScore_300)
			{
				[player increaseHealth:(_curOsuFile.HpMultiplierComboEnd * HP_COMBO_KATU)];
				if (!simulate)
					input.score = kHitObjectScore_300k;
			}
			else if (fullCombo == 2 && score == kHitObjectScore_100)
			{
				[player increaseHealth:(_curOsuFile.HpMultiplierComboEnd * HP_COMBO_KATU)];
				if (!simulate)
					input.score = kHitObjectScore_100k;
			}
			else if (fullCombo != 0) // COMBO_MU
			{
				[player increaseHealth:(_curOsuFile.HpMultiplierComboEnd * HP_COMBO_MU)];
			}
		}

		if (!simulate)
		{
			if (score != kHitObjectScore_0)
			{
				int tmpSoundType = input.sliderPerEndpointSounds ? [[input.sliderPerEndpointSounds objectAtIndex:[input.sliderPerEndpointSounds count] - 1] intValue] : input.soundType;

				SoundEngine_StartEffect( _sounds[GET_SOUND_INDEX(kSound_NormalHitNormal)]);
				if (tmpSoundType & kHitObjectSound_Whistle)
					SoundEngine_StartEffect( _sounds[GET_SOUND_INDEX(kSound_NormalHitWhistle)]);
				if (tmpSoundType & kHitObjectSound_Finish)
					SoundEngine_StartEffect( _sounds[GET_SOUND_INDEX(kSound_NormalHitFinish)]);
				if (tmpSoundType & kHitObjectSound_Clap)
					SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalHitClap)]);
			}
			else
			{
				if (player.curCombo > 20)
					SoundEngine_StartEffect(_sounds[kSound_ComboBreak]);
				player.curCombo = 0;
			}

			[_animationSystem addItem:kAnimationType_Fade texture:_textures[kTexture_Hit0+input.score] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(x+GAME_STAGE_X, y+GAME_STAGE_Y) scale:((_curOsuFile.difficulty_HitCircleSize * 2.0f) / _textures[kTexture_Hit0+input.score].contentSize.width) isTopLeft:NO, 1.0f, 0.0f];
		}
	}
}

- (void)drawHitCircle:(HitObject*)input
{
	if (input.score == kHitObjectScore_None && _curTime > input.startTime + _hitWindows[kHitWindow_50]) // Missed most lenient hit window
	{
		[self doScore:input score:kHitObjectScore_0 x:input.x+input.stackSize*_curOsuFile.difficulty_HitCircleSize/20.0f y:input.y+input.stackSize*_curOsuFile.difficulty_HitCircleSize/20.0f player:_curPlayer simulate:NO];
	}
	
	float scaleFactor = ((input.startTime - _curTime)/_curOsuFile.difficulty_PreEmpt * (_curOsuFile.difficulty_HitCircleSize * 2.0f) + _curOsuFile.difficulty_HitCircleSize);

	glPushMatrix();
	glTranslatef(input.x + input.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f, input.y + input.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f, 0);
	glScalef(_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_HitCircle].contentSize.width, -_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_HitCircle].contentSize.height, 1.0f);
	glColor4f((float)(_colours[input.colourIndex].r)/255.0f, (float)(_colours[input.colourIndex].g)/255.0f, (float)(_colours[input.colourIndex].b)/255.0f, scaleFactor > (1.2f * _curOsuFile.difficulty_HitCircleSize) ? 1.0f - ((scaleFactor/_curOsuFile.difficulty_HitCircleSize) - 1.2f)/2.0f : 1.0f);
	[_textures[kTexture_HitCircle] drawAtPoint:CGPointMake(0, 0)];

	glColor4f(1.0f, 1.0f, 1.0f, scaleFactor > (1.2f * _curOsuFile.difficulty_HitCircleSize) ? 1.0f - ((scaleFactor/_curOsuFile.difficulty_HitCircleSize) - 1.2f)/2.0f : 1.0f);

	if (input.comboNum < 10)
		[_textures[kTexture_NumberTextures + input.comboNum % 10] drawAtPoint:CGPointMake(0, 0)];
	else if (input.comboNum < 100)
	{
		[_textures[kTexture_NumberTextures + (int)(input.comboNum / 10.0f)] drawAtPoint:CGPointMake(-_curOsuFile.difficulty_HitCircleSize / 5.0f, 0)];
		[_textures[kTexture_NumberTextures + input.comboNum % 10] drawAtPoint:CGPointMake(_curOsuFile.difficulty_HitCircleSize / 5.0f, 0)];
	}

	[_textures[kTexture_HitCircleOverlay] drawAtPoint:CGPointMake(0, 0)];

	glColor4f((float)(_colours[input.colourIndex].r)/255.0f, (float)(_colours[input.colourIndex].g)/255.0f, (float)(_colours[input.colourIndex].b)/255.0f, scaleFactor > (1.2f * _curOsuFile.difficulty_HitCircleSize) ? 1.0f - ((scaleFactor/_curOsuFile.difficulty_HitCircleSize) - 1.2f)/2.0f : 1.0f);
	glScalef((_textures[kTexture_HitCircle].contentSize.width / _curOsuFile.difficulty_HitCircleSize) * (scaleFactor / _textures[kTexture_ApproachCircle].contentSize.width), (_textures[kTexture_HitCircle].contentSize.height / _curOsuFile.difficulty_HitCircleSize) * (scaleFactor / _textures[kTexture_HitCircle].contentSize.height), 1.0f);
	[_textures[kTexture_ApproachCircle] drawAtPoint:CGPointMake(0, 0)];

	glPopMatrix();
}

// Thanks Pat!
int getNextTick(int curTick, int offset, int count)
{
    count--;
    int distFromLastPoint = curTick % count;
    int distToNextPoint = count - distFromLastPoint;

    int distToNextEndPoint = curTick % (count * 2);
    int distToNextOffset = offset - (distToNextEndPoint % offset);
	
    if( distToNextEndPoint >= count )
        distToNextOffset = ((count * 2) - distToNextEndPoint) % offset;
	
    distToNextOffset += offset * !distToNextOffset;
	
    if (distToNextOffset < distToNextPoint  )
		return distToNextOffset + curTick;
	
    return distToNextPoint + curTick;
}

- (void)drawSlider:(HitObject*)input reset:(BOOL)reset
{
	int count = input.rotationRequirement_sliderCurveCount;
	int i;
	static int nextTick = 0;

	if (reset)
	{
		nextTick = 0;
		_sliderOnBall = NO;
		_sliderTicksHit = 0;
		return;
	}

	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

	[input.sliderTexture drawInRectUpsideDown:CGRectMake(input.x - _curOsuFile.difficulty_HitCircleSize / 2.0f, input.y - _curOsuFile.difficulty_HitCircleSize / 2.0f, input.sliderTexture.contentSize.width, input.sliderTexture.contentSize.height)];

	// Slider ball
	if (_curTime < input.startTime)
	{
		float scaleFactor = ((input.startTime - _curTime)/_curOsuFile.difficulty_PreEmpt * (_curOsuFile.difficulty_HitCircleSize * 2.0f) + _curOsuFile.difficulty_HitCircleSize);

		//if (nextTick == 0)
		//	nextTick = getNextTick(nextTick, SLIDER_TICKS_PER_BEAT / _curOsuFile.difficulty_SliderTickrate, count);

		glPushMatrix();
		glTranslatef(input.pSliderCurvePoints[0], input.pSliderCurvePoints[1], 0.0f);
		glScalef(_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_HitCircle].contentSize.width, -_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_HitCircle].contentSize.height, 1.0f);

		glColor4f(1.0f, 1.0f, 1.0f, scaleFactor > (1.2f * _curOsuFile.difficulty_HitCircleSize) ? 1.0f - ((scaleFactor/_curOsuFile.difficulty_HitCircleSize) - 1.2f)/2.0f : 1.0f);

		if (input.comboNum < 10)
			[_textures[kTexture_NumberTextures + input.comboNum % 10] drawAtPoint:CGPointMake(0, 0)];
		else if (input.comboNum < 100)
		{
			[_textures[kTexture_NumberTextures + (int)(input.comboNum / 10.0f)] drawAtPoint:CGPointMake(-_curOsuFile.difficulty_HitCircleSize / 5.0f, 0)];
			[_textures[kTexture_NumberTextures + input.comboNum % 10] drawAtPoint:CGPointMake(_curOsuFile.difficulty_HitCircleSize / 5.0f, 0)];
		}

		glColor4f((float)(_colours[input.colourIndex].r)/255.0f, (float)(_colours[input.colourIndex].g)/255.0f, (float)(_colours[input.colourIndex].b)/255.0f, scaleFactor > (1.2f * _curOsuFile.difficulty_HitCircleSize) ? 1.0f - ((scaleFactor/_curOsuFile.difficulty_HitCircleSize) - 1.2f)/2.0f : 1.0f);
		glScalef((_textures[kTexture_HitCircle].contentSize.width / _curOsuFile.difficulty_HitCircleSize) * (scaleFactor / _textures[kTexture_ApproachCircle].contentSize.width), (_textures[kTexture_HitCircle].contentSize.height / _curOsuFile.difficulty_HitCircleSize) * (scaleFactor / _textures[kTexture_HitCircle].contentSize.height), 1.0f);
		[_textures[kTexture_ApproachCircle] drawAtPoint:CGPointMake(0, 0)];		
		glPopMatrix();		

		if (input.repeatCount > 1)
		{
			glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
			glPushMatrix();
			glTranslatef(input.pSliderCurvePoints[(count-1)*3], input.pSliderCurvePoints[(count-1)*3+1], 0);
			glRotatef(atan2(input.pSliderCurvePoints[(count-1)*3+1] - input.pSliderCurvePoints[(count-2)*3+1], input.pSliderCurvePoints[(count-1)*3] - input.pSliderCurvePoints[(count-2)*3]) * (180.0f/PI) + 180.0f, 0.0f, 0.0f, 1.0f);
			glScalef(_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_HitCircle].contentSize.width, -_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_HitCircle].contentSize.height, 1.0f);
			[_textures[kTexture_ReverseArrow] drawAtPoint:CGPointMake(0,0)];
			glPopMatrix();
		}
	}
	else
	{
		int index = (_curTime - input.startTime) / (input.endTime - input.startTime) * (count - 1) * input.repeatCount;
		CGPoint tmp, tmp2;
		float angle;
		int direction = (int)floor((float)(index - 1) / (count - 1)) % 2; // 0 = incrementing, 1 = decrementing
		int index2 = index;

		if (nextTick == 0)
		{
			if (_sliderTicksHit == 0 && _curTime > input.startTime + _hitWindows[kHitWindow_50])
			{
				nextTick = getNextTick(nextTick, SLIDER_TICKS_PER_BEAT / _curOsuFile.difficulty_SliderTickrate, count);
				if (_curPlayer.curCombo > _curPlayer.maxCombo)
					_curPlayer.maxCombo = _curPlayer.curCombo;

				if (_curPlayer.curCombo > 20)
					SoundEngine_StartEffect(_sounds[kSound_ComboBreak]);
				_curPlayer.curCombo = 0;
			}
			else if (_sliderTicksHit > 0)
				nextTick = getNextTick(nextTick, SLIDER_TICKS_PER_BEAT / _curOsuFile.difficulty_SliderTickrate, count);
		}

		if (index > 0)
		{
			if (index > (count - 1) * input.repeatCount)
			{
				index = (count - 1) * input.repeatCount;
				direction = (int)floor((float)index / count) % 2;
			}
			
			index = abs(-(count - 1) * direction + ((index - 1) % (count - 1) + 1));

			tmp = CGPointMake(input.pSliderCurvePoints[index*3], input.pSliderCurvePoints[index*3+1]);
			tmp2 = CGPointMake(input.pSliderCurvePoints[(index+(direction*2-1))*3], input.pSliderCurvePoints[(index+(direction*2-1))*3+1]);
			angle = atan2(tmp.y - tmp2.y, tmp.x - tmp2.x) * 180.0f / PI;
		}
		else
		{
			tmp = CGPointMake(input.pSliderCurvePoints[0], input.pSliderCurvePoints[1]);
			tmp2 = CGPointMake(input.pSliderCurvePoints[3], input.pSliderCurvePoints[4]);
			angle = atan2(tmp2.y - tmp.y, tmp2.x - tmp.x) * 180.0f / PI;
			direction = 0;
		}

		// draw reversals
		if (floor((index2 - 1) / (count - 1)) < input.repeatCount - 1)
		{
			glPushMatrix();
			glTranslatef(input.pSliderCurvePoints[((1-direction)*(count-1))*3], input.pSliderCurvePoints[((1-direction)*(count-1))*3+1], 0);
			glRotatef(atan2(input.pSliderCurvePoints[((1-direction)*(count-1))*3+1] - input.pSliderCurvePoints[((1-direction)*(count-1)+(direction*2-1))*3+1], input.pSliderCurvePoints[((1-direction)*(count-1))*3] - input.pSliderCurvePoints[((1-direction)*(count-1)+(direction*2-1))*3]) * (180.0f/PI) + 180.0f, 0.0f, 0.0f, 1.0f);
			glScalef(_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_HitCircle].contentSize.width, -_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_HitCircle].contentSize.height, 1.0f);
			[_textures[kTexture_ReverseArrow] drawAtPoint:CGPointMake(0,0)];
			glPopMatrix();
		}

		glPushMatrix();
		glTranslatef(tmp.x, tmp.y, 0);
		glScalef(_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_SliderBallTextures + index2 % 10].contentSize.width, -_curOsuFile.difficulty_HitCircleSize / _textures[kTexture_SliderBallTextures + index2 % 10].contentSize.height, 1.0f);
		glRotatef(angle, 0.0f, 0.0f, -1.0f);
		[_textures[kTexture_SliderBallTextures + index2 % 10] drawAtPoint:CGPointMake(0, 0)];

		if ([OsuFunctions dist:(_curTouchPos.x - GAME_STAGE_X) y1:(_curTouchPos.y - GAME_STAGE_Y) x2:tmp.x y2:tmp.y] < (_sliderOnBall ? _curOsuFile.difficulty_HitCircleSize : _curOsuFile.difficulty_HitCircleSize / 2.0f) && _curState == kOsuStates_GameInPlay)
		{
			// Handle scoring
			if (nextTick && (index2 == nextTick || (index2 > nextTick && _sliderOnBall)))
			{
				_sliderTicksHit++;
				if (nextTick % (count - 1) == 0)
				{
					if (index2 >= (count - 1) * input.repeatCount)
						[self doScore:input score:kHitObjectScore_SliderEnd x:tmp.x y:tmp.y player:_curPlayer simulate:NO];
					else
					{
						[self doScore:input score:kHitObjectScore_SliderRepeat x:tmp.x y:tmp.y player:_curPlayer simulate:NO];

						SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalHitNormal)]);
						if ((input.sliderPerEndpointSounds ? [[input.sliderPerEndpointSounds objectAtIndex:(nextTick / (count - 1))] intValue] : input.soundType) & kHitObjectSound_Whistle)
							SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalHitWhistle)]);
						if ((input.sliderPerEndpointSounds ? [[input.sliderPerEndpointSounds objectAtIndex:(nextTick / (count - 1))] intValue] : input.soundType) & kHitObjectSound_Clap)
							SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalHitClap)]);
						if ((input.sliderPerEndpointSounds ? [[input.sliderPerEndpointSounds objectAtIndex:(nextTick / (count - 1))] intValue] : input.soundType) & kHitObjectSound_Finish)
							SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalHitFinish)]);
					}
				}
				else
				{
					[self doScore:input score:kHitObjectScore_SliderTick x:tmp.x y:tmp.y player:_curPlayer simulate:NO];
					SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalSliderTick)]);
				}
			}

			[_textures[kTexture_SliderFollowCircle] drawAtPoint:CGPointMake(0, 0)];
			_sliderOnBall = YES;
		}
		else
		{
			_sliderOnBall = NO;
		}

		glPopMatrix();

		if (nextTick && index2 >= nextTick)
		{
			nextTick = getNextTick(nextTick, SLIDER_TICKS_PER_BEAT / _curOsuFile.difficulty_SliderTickrate, count);
			if (!_sliderOnBall && index2 < (count - 1) * input.repeatCount)
			{
				if (_curPlayer.curCombo > _curPlayer.maxCombo)
					_curPlayer.maxCombo = _curPlayer.curCombo;

				if (_curPlayer.curCombo > 20)
					SoundEngine_StartEffect(_sounds[kSound_ComboBreak]);
				_curPlayer.curCombo = 0;
			}
		}

		if (index2 >= (count - 1) * input.repeatCount)
		{
			// judge slider performance
			i = input.repeatCount + 1 + (ceil((count - 1) / (SLIDER_TICKS_PER_BEAT / _curOsuFile.difficulty_SliderTickrate)) - 1) * input.repeatCount;

			// reset static variables
			SoundEngine_StopEffect(_sounds[GET_SOUND_INDEX(kSound_NormalSliderSlide)], FALSE);
			if (input.soundType & kHitObjectSound_Whistle)
				SoundEngine_StopEffect(_sounds[GET_SOUND_INDEX(kSound_NormalSliderWhistle)], FALSE);

			if (_sliderTicksHit == 0)
				[self doScore:input score:kHitObjectScore_0 x:tmp.x y:tmp.y player:_curPlayer simulate:NO];
			else if (_sliderTicksHit == i)
				[self doScore:input score:kHitObjectScore_300 x:tmp.x y:tmp.y player:_curPlayer simulate:NO];
			else if ((float)_sliderTicksHit / i >= 0.5f)
				[self doScore:input score:kHitObjectScore_100 x:tmp.x y:tmp.y player:_curPlayer simulate:NO];
			else
				[self doScore:input score:kHitObjectScore_50 x:tmp.x y:tmp.y player:_curPlayer simulate:NO];

			//[input.sliderTexture release];
			//input.sliderTexture = NULL;
			nextTick = 0;
			_sliderOnBall = NO;
			_sliderTicksHit = 0;

			[_animationSystem addItem:kAnimationType_Fade texture:input.sliderTexture startTime:_curTime endTime:_curTime+500.0f absolute:NO layer:kLayerType_BelowForeground easing:0 position:CGPointMake(input.x - _curOsuFile.difficulty_HitCircleSize / 2.0f + GAME_STAGE_X, input.y - _curOsuFile.difficulty_HitCircleSize / 2.0f + GAME_STAGE_Y) scale:1.0f isTopLeft:YES, 1.0f, 0.0f];
		}
	}
}

- (void)drawSpinner:(HitObject*)input reset:(BOOL)reset
{
	static float angleDiff = 0.0f;
	static int zeroCount = 0;
	static float velocityTheoretical = 0.0f, velocityCurrent = 0.0f;
	static float lastMouseAngle = 4*PI;
	static float curAngle = 0.0f;
	static int lastScoredRotation;
	static BOOL soundStarted;
	//float rpm;
	float newMouseAngle = atan2(_curTouchPos.y - input.y - GAME_STAGE_Y, _curTouchPos.x - input.x - GAME_STAGE_X);

	if (reset)
	{
		angleDiff = 0.0f;
		zeroCount = 0;
		velocityCurrent = 0.0f;
		velocityTheoretical = 0.0f;
		lastMouseAngle = 4*PI;
		curAngle = 0.0f;
		lastScoredRotation = 0;
		return;
	}
	
	if (_curTime < input.startTime)
	{
		return;
	}
	if (_curTime > input.endTime)
	{
		SoundEngine_StopEffect(_sounds[kSound_SpinnerSpin], FALSE);
		soundStarted = NO;

		// judge spinner
		if (lastScoredRotation > input.rotationRequirement_sliderCurveCount + 1)
		{
			[self doScore:input score:kHitObjectScore_300 x:input.x y:input.y player:_curPlayer simulate:NO];
		}
		else if (lastScoredRotation > input.rotationRequirement_sliderCurveCount)
		{
			[self doScore:input score:kHitObjectScore_100 x:input.x y:input.y player:_curPlayer simulate:NO];
		}
		else if (lastScoredRotation > input.rotationRequirement_sliderCurveCount - 1)
		{
			[self doScore:input score:kHitObjectScore_50 x:input.x y:input.y player:_curPlayer simulate:NO];
		}
		else
		{
			[self doScore:input score:kHitObjectScore_0 x:input.x y:input.y player:_curPlayer simulate:NO];
		}
		if (input.score != kHitObjectScore_0)
			[_animationSystem addItem:kAnimationType_Fade texture:_textures[kTexture_SpinnerOsu] startTime:_curTime endTime:(_curTime+FADE_TIME) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(input.x+GAME_STAGE_X, input.y+GAME_STAGE_Y-100.0f) scale:0.8f isTopLeft:NO, 1.0f, 0.0f];

		angleDiff = 0.0f;
		zeroCount = 0;
		velocityCurrent = 0.0f;
		velocityTheoretical = 0.0f;
		lastMouseAngle = 4*PI;
		curAngle = 0.0f;
		lastScoredRotation = 0;
		return;
	}

	if (_curState == kOsuStates_GameInPlay && lastMouseAngle != 4*PI)
	{
		angleDiff = newMouseAngle - lastMouseAngle;
		if (newMouseAngle - lastMouseAngle < -PI)
			angleDiff = (2*PI) + newMouseAngle - lastMouseAngle;
		else if (lastMouseAngle - newMouseAngle < -PI)
			angleDiff = (-2*PI) - lastMouseAngle + newMouseAngle;
	}
	else
		angleDiff = 0.0f;

	lastMouseAngle = newMouseAngle;
	if ((_curTouchPos.x == SCREEN_SIZE_X + 100.0f) && (_curTouchPos.y == SCREEN_SIZE_Y + 100.0f))
		lastMouseAngle = 4*PI;

	if (angleDiff == 0.0f)
	{
		if (zeroCount++ < 1)
			velocityTheoretical = velocityTheoretical/3;
		else
			velocityTheoretical = 0;
	}
	else
	{
		zeroCount = 0;

		if ((_curTouchPos.x == SCREEN_SIZE_X + 100.0f) && (_curTouchPos.y == SCREEN_SIZE_Y + 100.0f))
			angleDiff = 0.0f;

		if (fabs(angleDiff) < PI)
			velocityTheoretical = angleDiff/SIXTY_FRAMES_PER_SECOND;
		else
			velocityTheoretical = 0.0f;
	}

	//rpm = rpm * 0.9 + 0.1 * fabs(velocityCurrent);
	if (velocityTheoretical > velocityCurrent)
		velocityCurrent = velocityCurrent + [OsuFunctions min:(velocityTheoretical - velocityCurrent) y:(input.maxAccel*SIXTY_FRAMES_PER_SECOND)];
	else
		velocityCurrent = velocityCurrent + [OsuFunctions max:(velocityTheoretical - velocityCurrent) y:-(input.maxAccel*SIXTY_FRAMES_PER_SECOND)];

	velocityCurrent = [OsuFunctions max:-0.05f y:[OsuFunctions min:velocityCurrent y:0.05f]];
	curAngle = curAngle + fabs((float)(velocityCurrent * SIXTY_FRAMES_PER_SECOND));

	if ((int)(fabs(curAngle) / PI) > lastScoredRotation)
	{
		lastScoredRotation = (int)(fabs(curAngle) / PI);
		if (lastScoredRotation % 2 == 0)
		{
			if (lastScoredRotation > input.rotationRequirement_sliderCurveCount)
			{
				SoundEngine_StartEffect(_sounds[kSound_SpinnerBonus]);
				[self doScore:input score:kHitObjectScore_SpinnerBonus x:input.x y:input.y player:_curPlayer simulate:NO];
				//_curPlayer.score += 1000;
			}
			else
				[self doScore:input score:kHitObjectScore_SpinnerSpinPoints x:input.x y:input.y player:_curPlayer simulate:NO];
				//_curPlayer.score += 100;
		}
	}

	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glPushMatrix();
	glTranslatef(input.x, input.y, 0.0f);
	glScalef(640.0f / _textures[kTexture_SpinnerBackground].contentSize.width, -640.0f / _textures[kTexture_SpinnerBackground].contentSize.width, 1.0f);
	[_textures[kTexture_SpinnerBackground] drawAtPoint:CGPointMake(0,0)];
	[_textures[kTexture_SpinnerMetre] drawInRect:CGRectMake(-_textures[kTexture_SpinnerMetre].contentSize.width / 2.0f, -_textures[kTexture_SpinnerMetre].contentSize.height / 2.0f, _textures[kTexture_SpinnerMetre].contentSize.width, _textures[kTexture_SpinnerMetre].contentSize.height * (fabs(curAngle) / PI) / (input.rotationRequirement_sliderCurveCount)) scaleX:1.0f scaleY:((fabs(curAngle) / PI) / (input.rotationRequirement_sliderCurveCount))];

	glRotatef(curAngle * (180.0f / PI), 0.0f, 0.0f, -1.0f);
	[_textures[kTexture_SpinnerCircle] drawAtPoint:CGPointMake(0,0)];
	glPopMatrix();

	float circleSize = (1.0f - (_curTime - input.startTime) / (input.endTime - input.startTime)) * 380.0f;
	glColor4f(77.0f/255.0f, 139.0f/255.0f, 217.0f/255.0f, 1.0f);
	[_textures[kTexture_ApproachCircle] drawInRectUpsideDown:CGRectMake(input.x - circleSize/2.0f, input.y - circleSize/2.0f, circleSize, circleSize)];

	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	if (fabs(curAngle) / PI > input.rotationRequirement_sliderCurveCount)
		[_textures[kTexture_SpinnerClear] drawInRectUpsideDown:CGRectMake(input.x - 125, 50, 250, -1)];
	else
		[_textures[kTexture_SpinnerSpin] drawInRectUpsideDown:CGRectMake(input.x - 100, 250, 200, -1)];
	
	if (_curTouchPos.x != SCREEN_SIZE_X + 100.0f && _curTouchPos.y != SCREEN_SIZE_Y && _curState == kOsuStates_GameInPlay)
	{
		SoundEngine_SetEffectPitch(_sounds[kSound_SpinnerSpin], [OsuFunctions max:(5.0f * [OsuFunctions min:((fabs(curAngle) / PI) / (input.rotationRequirement_sliderCurveCount)) y:1.0f]) y:1.0f]);
		if (!soundStarted)
		{
			SoundEngine_StartEffect(_sounds[kSound_SpinnerSpin]);
			soundStarted = YES;
		}
	}
	else
	{
		soundStarted = NO;
		SoundEngine_StopEffect(_sounds[kSound_SpinnerSpin], FALSE);
	}
}

- (void)renderHitObjects
{
	int i = _curHitIndex;
	if (i < [_hitObjects count])
	{
		HitObject *tmp = [_hitObjects objectAtIndex:i];
		while ((tmp.startTime - _curTime) < _curOsuFile.difficulty_PreEmpt)
		{
			i++;
			if (tmp.objectType & kHitObject_Spinner)
				[self drawSpinner:tmp reset:NO];
			if (i >= [_hitObjects count])
				break;
			tmp = [_hitObjects objectAtIndex:i];
		}
		for (i = i - 1; i >= _curHitIndex; i--)
		{
			tmp = [_hitObjects objectAtIndex:i];
			if (tmp.objectType & kHitObject_HitCircle)
				[self drawHitCircle:tmp];
			else if (tmp.objectType & kHitObject_Slider)
				[self drawSlider:tmp reset:NO];
			//else if (tmp.objectType & kHitObject_Spinner)
			//	[self drawSpinner:tmp reset:NO];
		}
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView.tag == 12345)
	{
		if ([_curPlayer.name compare:[[_enterNameField text] retain]] != 0)
		{
			_curPlayer.name = [[_enterNameField text] retain];
			[_settingsManager setValue:_curPlayer.name forKey:kSettings_PlayerNameKey];
			[_settingsManager commitChanges];
		}
		[_curOsuFile addHighscore:_curPlayer.score rank:_ranking name:_curPlayer.name combo:_curPlayer.maxCombo];
		[_beatMap updateDB:kBeatmapDBUpdate_Highscores];
	}
}

- (void)renderRankingScreen:(BOOL)calculate
{
	static int counters[7]; // ordered by the same order as eHitObjectScore
	static float accuracy;

	if (calculate)
	{
		HitObject *tmpHitObject;
		int total = 0;

		memset(counters, 0, sizeof(counters));
		for (tmpHitObject in _hitObjects)
		{
			counters[tmpHitObject.score]++;
			total++;
		}
		accuracy = (float)(counters[kHitObjectScore_50] * 50.0f + (counters[kHitObjectScore_100] + counters[kHitObjectScore_100k]) * 100.0f + (counters[kHitObjectScore_300] + counters[kHitObjectScore_300k] + counters[kHitObjectScore_300g]) * 300.0f) / ((counters[kHitObjectScore_0] + counters[kHitObjectScore_50] + counters[kHitObjectScore_100] + counters[kHitObjectScore_100k] + counters[kHitObjectScore_300] + counters[kHitObjectScore_300k] + counters[kHitObjectScore_300g]) * 300.0f);

		if (counters[kHitObjectScore_300] + counters[kHitObjectScore_300g] + counters[kHitObjectScore_300k] == total)
			_ranking = 0;
		else if (counters[kHitObjectScore_0] == 0 && ((float)counters[kHitObjectScore_50] / total) < 0.01f && ((float)(counters[kHitObjectScore_300] + counters[kHitObjectScore_300g] + counters[kHitObjectScore_300k]) / total) > 0.9f)
			_ranking = 1;
		else if ((counters[kHitObjectScore_0] == 0 && ((float)(counters[kHitObjectScore_300] + counters[kHitObjectScore_300g] + counters[kHitObjectScore_300k]) / total) > 0.8f) || ((float)(counters[kHitObjectScore_300] + counters[kHitObjectScore_300g] + counters[kHitObjectScore_300k]) / total) > 0.9f)
			_ranking = 2;
		else if ((counters[kHitObjectScore_0] == 0 && ((float)(counters[kHitObjectScore_300] + counters[kHitObjectScore_300g] + counters[kHitObjectScore_300k]) / total) > 0.7f) || ((float)(counters[kHitObjectScore_300] + counters[kHitObjectScore_300g] + counters[kHitObjectScore_300k]) / total) > 0.8f)
			_ranking = 3;
		else if (((float)(counters[kHitObjectScore_300] + counters[kHitObjectScore_300g] + counters[kHitObjectScore_300k]) / total) > 0.6f)
			_ranking = 4;
		else
			_ranking = 5;

		if (_curPlayer.curCombo > _curPlayer.maxCombo)
			_curPlayer.maxCombo = _curPlayer.curCombo;

		return;
	}

	float x;
	x = [self drawNumber:counters[0] x:290 y:250 upper:-1 height:50];
	[_textures[kTexture_ScoreTextures+13] drawInRectUpsideDown:CGRectMake(x, 250, -1, 50)];
	x = [self drawNumber:counters[1] x:100 y:250 upper:-1 height:50];
	[_textures[kTexture_ScoreTextures+13] drawInRectUpsideDown:CGRectMake(x, 250, -1, 50)];
	x = [self drawNumber:counters[2] x:100 y:185 upper:-1 height:50];
	[_textures[kTexture_ScoreTextures+13] drawInRectUpsideDown:CGRectMake(x, 185, -1, 50)];
	x = [self drawNumber:counters[3]+counters[6] x:290 y:185 upper:-1 height:50];
	[_textures[kTexture_ScoreTextures+13] drawInRectUpsideDown:CGRectMake(x, 185, -1, 50)];
	x = [self drawNumber:counters[4] x:100 y:120 upper:-1 height:50];
	[_textures[kTexture_ScoreTextures+13] drawInRectUpsideDown:CGRectMake(x, 120, -1, 50)];
	x = [self drawNumber:counters[5] x:290 y:120 upper:-1 height:50];
	[_textures[kTexture_ScoreTextures+13] drawInRectUpsideDown:CGRectMake(x, 120, -1, 50)];
	[self drawNumber:_curPlayer.score x:120 y:60 upper:10000000 height:40];

	x = [self drawNumber:_curPlayer.maxCombo x:35 y:325 upper:-1 height:40];
	[_textures[kTexture_ScoreTextures+13] drawInRectUpsideDown:CGRectMake(x, 325, -1, 40)];

	x = [self drawNumber:(int)(accuracy * 100.0f) x:225 y:325 upper:-1 height:40];
	[_textures[kTexture_ScoreTextures+11] drawInRectUpsideDown:CGRectMake(x, 325, -1, 40)];
	x = [self drawNumber:(int)((accuracy * 100.0f - (int)(accuracy * 100.0f)) * 100.0f) x:(x + 12) y:325 upper:-1 height:40];
	[_textures[kTexture_ScoreTextures+12] drawInRectUpsideDown:CGRectMake(x, 325, -1, 40)];

	if (_ranking >= 0)
		[_textures[kTexture_RankingSS+_ranking] drawInRectUpsideDown:CGRectMake(460, 50, -1, 270)];
	if (counters[kHitObjectScore_0] == 0)
		[_textures[kTexture_RankingPerfect] drawInRectUpsideDown:CGRectMake(40, 370, -1, 120)];
}

- (void)renderScene
{
	CGRect rect = [[UIScreen mainScreen] bounds];
	float scalex = rect.size.height / SCREEN_SIZE_X, scaley = rect.size.width / SCREEN_SIZE_Y;

#if 0
	if (_curState >= kOsuStates_GameInPlay)
	{
		int i;
		HitObject *tmpHitObject;
		for (i = _curHitIndex; i < [_hitObjects count] - 1; i++)
		{
			tmpHitObject = [_hitObjects objectAtIndex:i];
			if (tmpHitObject.startTime > _curTime + _curOsuFile.difficulty_PreEmpt)
			{
				break;
			}
			if ((tmpHitObject.objectType & kHitObject_Slider) && _curTime > tmpHitObject.startTime - 10000.0f && tmpHitObject.sliderTexture == NULL)
			{
				tmpHitObject.sliderTexture = [self renderSlider:tmpHitObject];
			}
		}
	}
#endif
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);

	glRotatef(-90.0f, 0.0f, 0.0f, 1.0f);
	glTranslatef(-rect.size.height, rect.size.width, 0.0f);
	glScalef(scalex, -scaley, 1.0f);

	if (_curState < kOsuStates_GameInPlay)
	{
		for (int i = 0; hotspots[_curState][i].textureID != kNumTextures; i++)
		{
			glColor4f(1.0f, 1.0f, 1.0f, 1.0f - hotspots[_curState][i].transparency);
			if (_curTouchPos.x > hotspots[_curState][i].bounds.origin.x && 
				_curTouchPos.x < hotspots[_curState][i].bounds.origin.x + hotspots[_curState][i].bounds.size.width && 
				_curTouchPos.y > hotspots[_curState][i].bounds.origin.y && 
				_curTouchPos.y < hotspots[_curState][i].bounds.origin.y + hotspots[_curState][i].bounds.size.height &&
				hotspots[_curState][i].hasOver)
				[_textures[hotspots[_curState][i].textureID + 1] drawInRectUpsideDown:hotspots[_curState][i].bounds];
			else
				[_textures[hotspots[_curState][i].textureID] drawInRectUpsideDown:hotspots[_curState][i].bounds];
		}
		if (_curState == kOsuStates_SongSelection)
			[_curSongSelection drawSongSelection];
		else if (_curState == kOsuStates_Ranking)
			[self renderRankingScreen:NO];
		else if (_curState == kOsuStates_LoadingBeatmaps)
		{
			float iter = (float)_curBeatmapManager.loadedBeatmaps / _curBeatmapManager.numBeatmaps;

			[_textures[kTexture_ExtraTexture1] drawInRectUpsideDown:CGRectMake(261, 450, 198, 11)];
			[_textures[kTexture_ExtraTexture2] drawInRectUpsideDown:CGRectMake(261, 450, 198*iter, 11) scaleX:iter scaleY:1.0f];
		}
		else if (_curState == kOsuStates_OptionsMenu)
		{
			if (_settingsManager.noFailMode)
				[_textures[kTexture_Hit0] drawInRectUpsideDown:CGRectMake(14, 14, 44, 44)];
		}

		glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
		[_animationSystem drawAnimations:_curTime layer:0];

		return;
	}

	if (_curHitIndex < [_hitObjects count])
	{
		HitObject *tmp;

		while (1)
		{
			if (_curHitIndex >= [_hitObjects count])
				break;

			tmp = [_hitObjects objectAtIndex:_curHitIndex];
			if (tmp.score == kHitObjectScore_None)
				break;

			_curHitIndex++;
		}
		if (_curHitIndex >= [_hitObjects count])
			[_animationSystem scheduleEvent:kOsuStateActions_GoToRankingScreen atTime:CFAbsoluteTimeGetCurrent()+3.0f absolute:YES];
	}

	if (_curState == kOsuStates_GameInPlay)
	{
		if (_curTime >= 0)
		{
			_lastTime = _curTime;
			_curTime = _avPlayer.currentTime * 1000.0f + 75.0f;
		}
		else
		{
			_curTime = -_curOsuFile.general_AudioLeadIn + (CFAbsoluteTimeGetCurrent()*1000.0f - _lastTime);
			if (_curTime >= 0)
			{
				[_avPlayer play];
				_lastTime = _curTime = 0.0f;
			}
		}

		if (!_isBreakPeriod && _curTime >= ((HitObject*)[_hitObjects objectAtIndex:0]).startTime && _curHitIndex < [_hitObjects count])
			[_curPlayer decreaseHealth:_curOsuFile.HpDropRate*(_curTime-_lastTime)];

		if (_curPlayer.health == 0.0f && !_settingsManager.noFailMode)
		{
			SoundEngine_StartEffect(_sounds[kSound_FailSound]);
			[_avPlayer pause];
			OsuGamePausedHotspots[3].textureID = kNumTextures;
			[self blockInputs];
			_curState = kOsuStates_GamePaused;
		}
	}

	if (_curTimingPointIndex < [_curOsuFile.timingPoints count] - 1 && _curTime > ((TimingPoint *)[_curOsuFile.timingPoints objectAtIndex:(_curTimingPointIndex + 1)]).offsetMs)
	{
		_curTimingPointIndex++;
		_curTimingPoint = [_curOsuFile.timingPoints objectAtIndex:_curTimingPointIndex];
	}

	if (_sliderOnBall && !_silderSoundStarted) // Slider sound
	{
		_silderSoundStarted = YES;
		SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalSliderSlide)]);
		if (((HitObject *)[_hitObjects objectAtIndex:_curHitIndex]).soundType & kHitObjectSound_Whistle)
			SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalSliderWhistle)]);
	}
	else if (!_sliderOnBall)
	{
		_silderSoundStarted = NO;
		SoundEngine_StopEffect(_sounds[kSound_NormalSliderSlide], FALSE);
		SoundEngine_StopEffect(_sounds[kSound_NormalSliderWhistle], FALSE);
		SoundEngine_StopEffect(_sounds[kSound_SoftSliderSlide], FALSE);
		SoundEngine_StopEffect(_sounds[kSound_SoftSliderWhistle], FALSE);
	}

	if (_curHitIndex >= [_hitObjects count] || ((HitObject*)[_hitObjects objectAtIndex:_curHitIndex]).objectType & kHitObject_Spinner == 0)
		SoundEngine_StopEffect(_sounds[kSound_SpinnerSpin], FALSE);

	/*
	if (!_isBreakPeriod)
		glColor4f(1.0f, 1.0f, 1.0f, 0.5f); // darken background
	else
		glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	[self renderBackground];
	*/

	[_animationSystem drawAnimations:_curTime layer:kLayerType_Background];
	[_animationSystem drawAnimations:_curTime layer:kLayerType_Failing];
	[_animationSystem drawAnimations:_curTime layer:kLayerType_Passing];
	[_animationSystem drawAnimations:_curTime layer:kLayerType_BelowForeground];
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

	// Draw score
	[self drawNumber:_curPlayer.score x:(_textures[kTexture_ScorebarBackground].contentSize.width * (TOP_BAR_HEIGHT / _textures[kTexture_ScorebarBackground].contentSize.height) + 12.0f) y:0 upper:10000000 height:SCORE_HEIGHT];

	// Draw progress bar
	glColor4f(1.0f, 1.0f, 1.0f, 0.2f);
	[_textures[kTexture_WhitePixel] drawInRect:CGRectMake((_textures[kTexture_ScorebarBackground].contentSize.width * (TOP_BAR_HEIGHT / _textures[kTexture_ScorebarBackground].contentSize.height) + 12.0f), 33, 159, 3)];
	glColor4f(1.0f, 1.0f, 0.5, 0.5f);
	[_textures[kTexture_WhitePixel] drawInRect:CGRectMake((_textures[kTexture_ScorebarBackground].contentSize.width * (TOP_BAR_HEIGHT / _textures[kTexture_ScorebarBackground].contentSize.height) + 12.0f), 33, 159*(_curTime/_curOsuFile.general_TotalLength), 3)];

	// Draw skip button if necessary
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	if (_curHitIndex == 0 && _curTime < _skipTime)
		[_textures[kTexture_PlaySkip] drawInRectUpsideDown:CGRectMake(570, 380, 150, 100)];

	if (!_isBreakPeriod)
		[self renderGameElements];
	glTranslatef(GAME_STAGE_X, GAME_STAGE_Y, 0.0f);
	[self renderHitObjects];
	glTranslatef(-GAME_STAGE_X, -GAME_STAGE_Y, 0.0f);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	[_animationSystem drawAnimations:_curTime layer:kLayerType_Foreground];

	if (_ranking < 0 && _curState == kOsuStates_GameInPlay && _curHitIndex == [_hitObjects count])
	{
		// done...
		//[_skinManager initRankingTextures];

		[self renderRankingScreen:YES];
		//_curState = kOsuStates_Ranking;
	}

	if (_curState == kOsuStates_GamePaused)
	{
		for (int i = 0; hotspots[_curState][i].textureID != kNumTextures; i++)
		{
			glColor4f(1.0f, 1.0f, 1.0f, 1.0f - hotspots[_curState][i].transparency);
			if (_curTouchPos.x > hotspots[_curState][i].bounds.origin.x && 
				_curTouchPos.x < hotspots[_curState][i].bounds.origin.x + hotspots[_curState][i].bounds.size.width && 
				_curTouchPos.y > hotspots[_curState][i].bounds.origin.y && 
				_curTouchPos.y < hotspots[_curState][i].bounds.origin.y + hotspots[_curState][i].bounds.size.height &&
				hotspots[_curState][i].hasOver)
				[_textures[hotspots[_curState][i].textureID + 1] drawInRectUpsideDown:hotspots[_curState][i].bounds];
			else
				[_textures[hotspots[_curState][i].textureID] drawInRectUpsideDown:hotspots[_curState][i].bounds];
		}
	}
}

- (BOOL) doStateAction:(eOsuStateActions)action
{
	BOOL stateChange = NO;

	switch (action)
	{
		case kOsuStateActions_GoToHomepage:
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://osu.ppy.sh/p/iphone"]];
			break;
		case kOsuStateActions_GoToSongSelection:
			SoundEngine_StartEffect( _sounds[kSound_MenuHit]);
			_curState = kOsuStates_SongSelection;
			if (!_curSongSelection)
				_curSongSelection = [[OsuSongSelection alloc] initWithTextures:_textures manager:_curBeatmapManager sounds:_sounds];
			stateChange = YES;
			break;
		case kOsuStateActions_GoToMainMenu:
			SoundEngine_StartEffect( _sounds[kSound_MenuBack]);
			if (_curState == kOsuStates_OptionsMenu)
			{
				[_textures[kTexture_ExtraTexture1] release];
				[_textures[kTexture_ExtraTexture2] release];
			}
			_curState = kOsuStates_MainMenu;
			stateChange = YES;
			break;
		case kOsuStateActions_GoToOptionsMenu:
			SoundEngine_StartEffect( _sounds[kSound_MenuHit]);
			_textures[kTexture_ExtraTexture1] = [[Texture2D alloc] initWithString:@"No-fail mode" dimensions:CGSizeMake(256, 32) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
			_textures[kTexture_ExtraTexture2] = [[Texture2D alloc] initWithString:@"Offset Finder" dimensions:CGSizeMake(256, 32) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];

			_curState = kOsuStates_OptionsMenu;
			stateChange = YES;
			break;
		case kOsuStateActions_GoToGameStart:
			SoundEngine_StartEffect( _sounds[kSound_MenuHit]);
			stateChange = YES;
			break;
		case kOsuStateActions_PauseContinue:
			SoundEngine_StartEffect(_sounds[kSound_MenuHit]);
			if (_curTime >= 0)
			{
				[_avPlayer play];
			}
			else
				_lastTime = CFAbsoluteTimeGetCurrent()*1000.0f - (_curTime + _curOsuFile.general_AudioLeadIn);

			_curState = kOsuStates_GameInPlay;
			stateChange = YES;
			break;
		case kOsuStateActions_PauseRetry:
			SoundEngine_StartEffect( _sounds[kSound_MenuHit]);
			if (_curState == kOsuStates_Ranking)
				SoundEngine_StopEffect(_sounds[kSound_Applause], FALSE);
			[self startGame:NULL];
			stateChange = YES;
			break;
		case kOsuStateActions_PauseBack:
			SoundEngine_StartEffect( _sounds[kSound_MenuBack]);
			if (_curState == kOsuStates_Ranking)
			{
				SoundEngine_StopEffect(_sounds[kSound_Applause], FALSE);
				[_skinManager releaseRankingTextures];
			}
			_curState = kOsuStates_SongSelection;
			[_curSongSelection goToState:kSongSelectionStates_Scoreboard];

			[_avPlayer stop];
			[_avPlayer release];
			_avPlayer = NULL;

			_curTime = 0.0f;
			_curHitIndex = 0;

			[_animationSystem removeAllItems];
			[_curOsuFile releaseGameElements];
			[_skinManager restoreReplacedObjects];
			//[_skinManager releaseGameTextures];
			//[_skinManager initMenuTextures];

			stateChange = YES;
			break;
		case kOsuStateActions_Ready:
			SoundEngine_StartEffect(_sounds[kSound_Ready]);
			break;
		case kOsuStateActions_Count3:
			SoundEngine_StartEffect(_sounds[kSound_Count3]);
			break;
		case kOsuStateActions_Count2:
			SoundEngine_StartEffect(_sounds[kSound_Count2]);
			break;
		case kOsuStateActions_Count1:
			SoundEngine_StartEffect(_sounds[kSound_Count1]);
			break;
		case kOsuStateActions_CountGo:
			SoundEngine_StartEffect(_sounds[kSound_CountGo]);
			break;
		case kOsuStateActions_UnblockInputs:
			_blockInput = NO;
			break;
		case kOsuStateActions_BreakStart:
			_isBreakPeriod = YES;
			break;
		case kOsuStateActions_BreakEnd:
			_isBreakPeriod = NO;
			break;
		case kOsuStateActions_ProcessBreakRanking:
			if (_curPlayer.health >= HP_BAR_MAXIMUM * 5/8) // Passing
			{
				AnimatedItem *tmpItem;
				//[_animationSystem scheduleEvent:kOsuStateActions_PlaySectionPass atTime:_curTime+20 absolute:NO];
				SoundEngine_StartEffect(_sounds[kSound_SectionPass]);
				[_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_SectionPass] startTime:_curTime+20 endTime:_curTime+100 absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(360, 240) scale:0.96f isTopLeft:NO];
				[_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_SectionPass] startTime:_curTime+160 endTime:_curTime+230 absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(360, 240) scale:0.96f isTopLeft:NO];
				tmpItem = [_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_SectionPass] startTime:_curTime+280 endTime:_curTime+1480 absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(360, 240) scale:0.96f isTopLeft:NO];
				[tmpItem addTransformation:kAnimationType_Fade startTime:_curTime+1280 endTime:_curTime+1480];
			}
			else
			{
				AnimatedItem *tmpItem;
				SoundEngine_StartEffect(_sounds[kSound_SectionFail]);
				//[_animationSystem scheduleEvent:kOsuStateActions_PlaySectionFail atTime:_curTime+130 absolute:NO];
				[_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_SectionFail] startTime:_curTime+130 endTime:_curTime+230 absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(360, 240) scale:0.96f isTopLeft:NO];
				tmpItem = [_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_SectionFail] startTime:_curTime+280 endTime:_curTime+1480 absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(360, 240) scale:0.96f isTopLeft:NO];
				[tmpItem addTransformation:kAnimationType_Fade startTime:_curTime+1280 endTime:_curTime+1480];
			}
			break;
		case kOsuStateActions_GoToRankingScreen:
			_curState = kOsuStates_Ranking;
			SoundEngine_StartEffect(_sounds[kSound_Applause]);
			[_animationSystem scheduleRemoveAllItems];
			if ([_curOsuFile isHighscore:_curPlayer.score] && !_settingsManager.noFailMode)
			{
				UIAlertView *alert;
				alert = [[UIAlertView alloc] initWithTitle:@"Osu!" message:@"High Score! Enter name:\n\n" delegate:self cancelButtonTitle:NULL otherButtonTitles:@"OK", NULL];

				_enterNameField = [[UITextField alloc] initWithFrame:CGRectMake(20.0, 70.0, 245.0, 25.0)];
				[_enterNameField setBackgroundColor:[UIColor whiteColor]];
				[_enterNameField setText:_curPlayer.name];
				_enterNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
				[_enterNameField becomeFirstResponder];

				[alert addSubview:_enterNameField];
				[alert setTransform:CGAffineTransformMakeTranslation(0.0, 80.0)];
				alert.tag = 12345;

				[alert show];
				[alert release];
				[_enterNameField release];
			}
			break;
		case kOsuStateActions_ToggleNoFail:
			SoundEngine_StartEffect(_sounds[kSound_MenuClick]);
			[_settingsManager setValue:(_settingsManager.noFailMode ? @"N" : @"Y") forKey:kSettings_NoFailKey];
			[_settingsManager commitChanges];
			break;
		default:
			break;
	}
	return stateChange;
}

- (void) handleTouch:(int)type location:(CGPoint)location
{
	CGRect rect = [[UIScreen mainScreen] bounds];
	CGPoint translatedLocation;

	if (_blockInput)
		return;

	translatedLocation.x = (location.y / rect.size.height) * SCREEN_SIZE_X;
	translatedLocation.y = SCREEN_SIZE_Y - (location.x / rect.size.width) * SCREEN_SIZE_Y;

	if (_curState != kOsuStates_GameInPlay)
	{
		BOOL stateChange = NO;

		for (int i = 0; !stateChange && hotspots[_curState][i].textureID != kNumTextures; i++)
		{
			if (_curTouchPos.x > hotspots[_curState][i].bounds.origin.x && 
				_curTouchPos.x < hotspots[_curState][i].bounds.origin.x + hotspots[_curState][i].bounds.size.width && 
				_curTouchPos.y > hotspots[_curState][i].bounds.origin.y && 
				_curTouchPos.y < hotspots[_curState][i].bounds.origin.y + hotspots[_curState][i].bounds.size.height &&
				type == 2)
			{
				stateChange = [self doStateAction:hotspots[_curState][i].action];
			}
		}
		if (_curState == kOsuStates_SongSelection && !stateChange)
			stateChange = [_curSongSelection doTouch:type location:translatedLocation];
		if (stateChange)
		{
			_curTouchPos.x = SCREEN_SIZE_X+100.0f;
			_curTouchPos.y = SCREEN_SIZE_Y+100.0f;
			[self blockInputs];
			return;
		}
	}

	if (type < 2) // touchMoved
	{
		_curTouchPos.x = translatedLocation.x;
		_curTouchPos.y = translatedLocation.y;
	}
	else
	{
		_curTouchPos.x = SCREEN_SIZE_X+100.0f;
		_curTouchPos.y = SCREEN_SIZE_Y+100.0f;
	}

	if (type == 0 && _curState == kOsuStates_GameInPlay) // touchBegan
	{
		HitObject *tmpHitObject;

		if (_curHitIndex == 0 && _curTime < _skipTime && _curTouchPos.x > 570 && _curTouchPos.y > 380) // skip button
		{
			_avPlayer.currentTime = _skipTime / 1000.0f;
			return;
		}

		[_animationSystem addItem:(kAnimationType_Scale | kAnimationType_Fade) texture:_textures[kTexture_ApproachCircle] startTime:_curTime endTime:(_curTime+350.0f) absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(translatedLocation.x, translatedLocation.y) scale:0.0f isTopLeft:NO, (96.0f/_textures[kTexture_ApproachCircle].contentSize.width), 1.0f, 0.25f];

		for (int i = _curHitIndex; i < [_hitObjects count]; i++)
		{
			tmpHitObject = [_hitObjects objectAtIndex:i];
			if (tmpHitObject.objectType & kHitObject_Spinner)
				continue;
			if (tmpHitObject.objectType & kHitObject_Slider)
			{
				if ([OsuFunctions dist:tmpHitObject.pSliderCurvePoints[0] y1:tmpHitObject.pSliderCurvePoints[1] x2:(translatedLocation.x - GAME_STAGE_X) y2:(translatedLocation.y - GAME_STAGE_Y)] < _curOsuFile.difficulty_HitCircleSize / 2.0f)
				{
					int timeDifference = abs(tmpHitObject.startTime - _curTime);

					if (timeDifference < _hitWindows[kHitWindow_50] && _sliderTicksHit == 0)
					{
						_sliderTicksHit = 1;

						[self doScore:tmpHitObject score:kHitObjectScore_SliderRepeat x:tmpHitObject.pSliderCurvePoints[0] y:tmpHitObject.pSliderCurvePoints[1] player:_curPlayer simulate:NO];
						SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalHitNormal)]);
						if ((tmpHitObject.sliderPerEndpointSounds ? [[tmpHitObject.sliderPerEndpointSounds objectAtIndex:0] intValue] : tmpHitObject.soundType) & kHitObjectSound_Whistle)
							SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalHitWhistle)]);
						if ((tmpHitObject.sliderPerEndpointSounds ? [[tmpHitObject.sliderPerEndpointSounds objectAtIndex:0] intValue] : tmpHitObject.soundType) & kHitObjectSound_Clap)
							SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalHitClap)]);
						if ((tmpHitObject.sliderPerEndpointSounds ? [[tmpHitObject.sliderPerEndpointSounds objectAtIndex:0] intValue] : tmpHitObject.soundType) & kHitObjectSound_Finish)
							SoundEngine_StartEffect(_sounds[GET_SOUND_INDEX(kSound_NormalHitFinish)]);
					}
	
					break;
				}
				else
					continue;
			}
			if (tmpHitObject.score > kHitObjectScore_None)
				continue;
			if (_curTime > tmpHitObject.startTime + _hitWindows[kHitWindow_50])
				break;
			if (_curTime < tmpHitObject.startTime - _curOsuFile.difficulty_PreEmpt)
				break;

			if ([OsuFunctions dist:(tmpHitObject.x + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) y1:(tmpHitObject.y + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) x2:(translatedLocation.x - GAME_STAGE_X) y2:(translatedLocation.y - GAME_STAGE_Y)] < _curOsuFile.difficulty_HitCircleSize / 2.0f)
			{
				int timeDifference = abs(tmpHitObject.startTime - _curTime);

				if (timeDifference < _hitWindows[kHitWindow_300])
				{
					[self doScore:tmpHitObject score:kHitObjectScore_300 x:(tmpHitObject.x + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) y:(tmpHitObject.y + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) player:_curPlayer simulate:NO];
				}
				else if (timeDifference < _hitWindows[kHitWindow_100])
				{
					[self doScore:tmpHitObject score:kHitObjectScore_100 x:(tmpHitObject.x + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) y:(tmpHitObject.y + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) player:_curPlayer simulate:NO];
				}
				else if (timeDifference < _hitWindows[kHitWindow_50])
				{
					[self doScore:tmpHitObject score:kHitObjectScore_50 x:(tmpHitObject.x + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) y:(tmpHitObject.y + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) player:_curPlayer simulate:NO];
				}
				else if (timeDifference < 400 || tmpHitObject == [_hitObjects objectAtIndex:_curHitIndex])
				{
					[self doScore:tmpHitObject score:kHitObjectScore_0 x:(tmpHitObject.x + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) y:(tmpHitObject.y + tmpHitObject.stackSize * _curOsuFile.difficulty_HitCircleSize / 20.0f) player:_curPlayer simulate:NO];
				}
				break;
			}
		}
	}
	else if (type == 4 && _curState == kOsuStates_GameInPlay && _curHitIndex < [_hitObjects count])
	{
		[_avPlayer pause];
		[self blockInputs];
		OsuGamePausedHotspots[3].textureID = kTexture_PauseContinue;
		_curState = kOsuStates_GamePaused;
	}
}

- (void) setOsufile:(OsuFiletype *)filetype
{
	_curOsuFile = filetype;
	_colours = _curOsuFile.pColours;
	_hitObjects = _curOsuFile.hitObjects;
}

- (SQLManager *)getSqlManager
{
	return _sqlManager;
}

- (void)startGame:(OsuFiletype *)osuFile // NULL if retrying (no need to reload)
{
	if (osuFile)
	{
		[osuFile processFile];

		if (_avPlayer)
			[_avPlayer release];
		_avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", _beatMap.directory, osuFile.general_AudioFilename]] error:NULL];
		
		if (!_avPlayer)
		{
			[OsuFunctions doAlert:[NSString stringWithFormat:@"Error loading beatmap song: %@", osuFile.general_AudioFilename] withCancel:NO delegate:self];
			return;
		}

		//[_skinManager releaseMenuTextures];
		//[_skinManager initGameTextures];

		//NSLog(@"Processing HitObjects...");
		[osuFile processHitObjects];
		[self setOsufile:osuFile];
		//[_curOsuFile calcHPDropRate];
		//NSLog(@"Done Processing HitObjects");
		[_skinManager replaceObjectsWithDirectory:_beatMap.directory];
	}

	_curOsuFile.general_Playcount++;
	_beatMap.playcount++;
	[_beatMap updateDB:kBeatmapDBUpdate_Playcount];
	[_animationSystem removeAllItems];

	// Handle events
	//[_textures[kTexture_Background] release];
	//_textures[kTexture_Background] = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/playfield.png", _skinManager.directory]]];

	if (_textures[kTexture_WhitePixel] == NULL)
		[_skinManager initOnTheFlyTextures];

	Texture2D *backgroundSprite = NULL;
	AnimatedItem *backgroundItem = NULL;

	for (OsuEvent *tmpEvent in _curOsuFile.events)
	{
		if (tmpEvent.type == kOsuEventType_Background)
		{
			backgroundSprite = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", _beatMap.directory, tmpEvent.filepath]] with4444:YES];
			break;
		}
	}
	if (backgroundSprite == NULL)
		backgroundSprite = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/playfield.png", _skinManager.directory]] with4444:NO];

	// Scale background texture...
	if ((float)backgroundSprite.contentSize.width / backgroundSprite.contentSize.height <= (float)SCREEN_SIZE_X/SCREEN_SIZE_Y)
		backgroundItem = [_animationSystem addItem:kAnimationType_None texture:backgroundSprite startTime:-_curOsuFile.general_AudioLeadIn endTime:_curOsuFile.general_TotalLength+4000.0f absolute:NO layer:kLayerType_Background easing:0 position:CGPointMake(360,240) scale:(float)SCREEN_SIZE_Y/backgroundSprite.contentSize.height isTopLeft:NO];
	else
		backgroundItem = [_animationSystem addItem:kAnimationType_None texture:backgroundSprite startTime:-_curOsuFile.general_AudioLeadIn endTime:_curOsuFile.general_TotalLength+4000.0f absolute:NO layer:kLayerType_Background easing:0 position:CGPointMake(360,240) scale:(float)SCREEN_SIZE_X/backgroundSprite.contentSize.width isTopLeft:NO];

	for (OsuEvent *tmpEvent in _curOsuFile.events)
	{
		if (tmpEvent.type == kOsuEventType_BreakPeriod)
		{
			[_animationSystem scheduleEvent:kOsuStateActions_BreakStart atTime:tmpEvent.x absolute:NO];
			[_animationSystem scheduleEvent:kOsuStateActions_BreakEnd atTime:tmpEvent.y absolute:NO];

			if (tmpEvent.y - tmpEvent.x > 2880)
				[_animationSystem scheduleEvent:kOsuStateActions_ProcessBreakRanking atTime:((tmpEvent.y - tmpEvent.x) / 2 > 2880 ? tmpEvent.x + (tmpEvent.y - tmpEvent.x) / 2 : tmpEvent.y - 2880) absolute:NO];

			for (int i = 0; i < 1300; i += 200)
			{
				[_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_PlayWarningArrow] startTime:tmpEvent.y-1000+i endTime:tmpEvent.y-900+i absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(120,100) scale:0.7f isTopLeft:NO];
				[_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_PlayWarningArrow] startTime:tmpEvent.y-1000+i endTime:tmpEvent.y-900+i absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(120,380) scale:0.7f isTopLeft:NO];
				[_animationSystem addItem:kAnimationType_Rotate texture:_textures[kTexture_PlayWarningArrow] startTime:tmpEvent.y-1000+i endTime:tmpEvent.y-900+i absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(600,100) scale:0.7f isTopLeft:NO, 180.0f, 180.0f];
				[_animationSystem addItem:kAnimationType_Rotate texture:_textures[kTexture_PlayWarningArrow] startTime:tmpEvent.y-1000+i endTime:tmpEvent.y-900+i absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(600,380) scale:0.7f isTopLeft:NO, 180.0f, 180.0f];
			}

			// Brighten/darken background
			[backgroundItem addTransformation:kAnimationType_Fade startTime:tmpEvent.x endTime:tmpEvent.x+300.0f, 0.5f, 1.0f];
			[backgroundItem addTransformation:kAnimationType_Fade startTime:tmpEvent.y-300.0f endTime:tmpEvent.y, 1.0f, 0.5f];
		}
	}

	HitObject *lastHitObject = NULL;
	for (HitObject *tmpHitObject in _hitObjects)
	{
		if (tmpHitObject.startTime < 5000.0f && (tmpHitObject.objectType & kHitObject_Slider))
			tmpHitObject.sliderTexture = [self renderSlider:tmpHitObject];

		// followpoint
		if (lastHitObject && (tmpHitObject.objectType & kHitObject_NewCombo) == 0 && (lastHitObject.objectType & kHitObject_Spinner) == 0)
		{
			CGPoint pos1 = (lastHitObject.objectType & kHitObject_HitCircle) ? CGPointMake(lastHitObject.x, lastHitObject.y) : (lastHitObject.repeatCount % 2 == 1 ? CGPointMake(lastHitObject.pSliderCurvePoints[(lastHitObject.rotationRequirement_sliderCurveCount-1)*3], lastHitObject.pSliderCurvePoints[(lastHitObject.rotationRequirement_sliderCurveCount-1)*3+1]) : CGPointMake(lastHitObject.pSliderCurvePoints[0], lastHitObject.pSliderCurvePoints[1]));
			int time1 = lastHitObject.endTime;
			CGPoint pos2 = (tmpHitObject.objectType & kHitObject_HitCircle) ? CGPointMake(tmpHitObject.x, tmpHitObject.y) : CGPointMake(tmpHitObject.pSliderCurvePoints[0], tmpHitObject.pSliderCurvePoints[1]);
			int time2 = tmpHitObject.startTime;

			int distance = (int)[OsuFunctions dist:pos1.x y1:pos1.y x2:pos2.x y2:pos2.y];
			CGPoint distanceVector = CGPointMake(pos2.x - pos1.x, pos2.y - pos1.y);
			int length = time2 - time1;

			AnimatedItem *dot;

			for (int j = (int)(32*1.5f); j < distance - 32; j += 32)
			{
				int fadein = (int)(time1 + ((float)j/distance)*length) - 800;
				int fadeout = (int)(time1 + ((float)j/distance)*length);

				dot = [_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_FollowPoint] startTime:fadein endTime:fadeout+400 absolute:NO layer:kLayerType_BelowForeground easing:0 position:CGPointMake(GAME_STAGE_X + pos1.x + ((float)j/distance)*distanceVector.x, GAME_STAGE_Y + pos1.y + ((float)j/distance)*distanceVector.y) scale:0.7f isTopLeft:NO];
				[dot addTransformation:kAnimationType_Fade startTime:fadein endTime:fadein+400, 0.0f, 1.0f];
				[dot addTransformation:kAnimationType_Fade startTime:fadeout endTime:fadeout+400, 1.0f, 0.0f];
			}
		}
		lastHitObject = tmpHitObject;
	}

	[self drawSlider:NULL reset:YES];
	[self drawSpinner:NULL reset:YES];

	// Handle TimingPoints
	_curTimingPointIndex = 0;
	_curTimingPoint = [_curOsuFile.timingPoints objectAtIndex:_curTimingPointIndex];

	_curPlayer.score = 0;
	[_curPlayer resetHealth];
	_curPlayer.curCombo = 0;
	_curPlayer.maxCombo = 0;
	_curTouchPos.x = SCREEN_SIZE_X + 100.0f;
	_curTouchPos.y = SCREEN_SIZE_Y + 100.0f;
	_ranking = -1;
	_isBreakPeriod = NO;

	if (osuFile == NULL)
	{
		[_avPlayer stop];
		_avPlayer.currentTime = 0;

		for (HitObject *tmpHitObject in _hitObjects)
		{
			if (tmpHitObject.objectType & kHitObject_Spinner)
				tmpHitObject.repeatCount = 0;
			tmpHitObject.score = kHitObjectScore_None;
		}
	}

	_hitWindows[kHitWindow_300] = (int)[OsuFunctions mapDifficultyRange:_curOsuFile.difficulty_OverallDifficulty min:80 mid:50 max:20]; // hitWindow300
	_hitWindows[kHitWindow_100] = (int)[OsuFunctions mapDifficultyRange:_curOsuFile.difficulty_OverallDifficulty min:140 mid:100 max:60]; // hitWindow100
	_hitWindows[kHitWindow_50] = (int)[OsuFunctions mapDifficultyRange:_curOsuFile.difficulty_OverallDifficulty min:200 mid:150 max:100]; // hitWindow50

	_curTime = -_curOsuFile.general_AudioLeadIn;
	_curHitIndex = 0;
	_lastTime = CFAbsoluteTimeGetCurrent()*1000.0f;

	[_avPlayer play];

	if (_curTime < 0)
		[_avPlayer pause];

	if (_curState == kOsuStates_Ranking)
	{
		_curState = kOsuStates_GameInPlay;
		[_skinManager releaseRankingTextures];
		[NSThread detachNewThreadSelector:@selector(textureThread) toTarget:self withObject:NULL];
	}
	else if (osuFile)
	{
		_curState = kOsuStates_GameInPlay;
		[NSThread detachNewThreadSelector:@selector(textureThread) toTarget:self withObject:NULL];
	}
	else
		_curState = kOsuStates_GameInPlay;

	float firstHitCircleStartTime = ((HitObject *)[_hitObjects objectAtIndex:0]).startTime;
	float beatIter = _curTimingPoint.beatLength;

	if (beatIter <= 333)
		beatIter *= 2.0f;

	if (_curOsuFile.general_Countdown == kOsuCountdown_HalfSpeed)
		beatIter *= 2.0f;
	else if (_curOsuFile.general_Countdown == kOsuCountdown_DoubleSpeed)
		beatIter /= 2.0f;

	if (_curOsuFile.general_Countdown && (firstHitCircleStartTime - beatIter * 7) > 0)
	{
		_skipTime = firstHitCircleStartTime - beatIter * 7;
		[_animationSystem scheduleEvent:kOsuStateActions_Ready atTime:(firstHitCircleStartTime - beatIter * 7) absolute:NO];
		[_animationSystem scheduleEvent:kOsuStateActions_Count3 atTime:(firstHitCircleStartTime - beatIter * 4) absolute:NO];
		[_animationSystem scheduleEvent:kOsuStateActions_Count2 atTime:(firstHitCircleStartTime - beatIter * 3) absolute:NO];
		[_animationSystem scheduleEvent:kOsuStateActions_Count1 atTime:(firstHitCircleStartTime - beatIter * 2) absolute:NO];
		[_animationSystem scheduleEvent:kOsuStateActions_CountGo atTime:(firstHitCircleStartTime - beatIter) absolute:NO];

		// Are you ready animations

		AnimatedItem *tmpItem;
		tmpItem = [_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_AreYouReady] startTime:(firstHitCircleStartTime - beatIter * 7) endTime:(firstHitCircleStartTime - beatIter * 4) absolute:NO layer:kLayerType_Background easing:0 position:CGPointMake(SCREEN_SIZE_X / 2.0f, SCREEN_SIZE_Y / 2.0f) scale:1.2f isTopLeft:NO];
		[tmpItem addTransformation:(kAnimationType_Scale|kAnimationType_Fade|kAnimationType_Rotate) startTime:(firstHitCircleStartTime - beatIter * 7) endTime:(firstHitCircleStartTime - beatIter * 6), 1.4f, 1.2f, 0.0f, 1.0f, -20.0f, 0.0f];
		[tmpItem addTransformation:(kAnimationType_Scale|kAnimationType_Fade) startTime:(firstHitCircleStartTime - beatIter * 5) endTime:(firstHitCircleStartTime - beatIter * 4), 1.2f, 2.5f, 1.0f, 0.0f];

		// Countdown animations
		tmpItem = [_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_Count3] startTime:(firstHitCircleStartTime - beatIter * 4) endTime:(firstHitCircleStartTime - beatIter*0.75f) absolute:NO layer:kLayerType_Background easing:0 position:CGPointMake(40, 0) scale:(480.0f / _textures[kTexture_Count3].contentSize.height) isTopLeft:YES];
		[tmpItem addTransformation:(kAnimationType_Fade) startTime:(firstHitCircleStartTime - beatIter) endTime:(firstHitCircleStartTime - beatIter*0.75f), 1.0f, 0.0f];
		tmpItem = [_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_Count2] startTime:(firstHitCircleStartTime - beatIter * 3) endTime:(firstHitCircleStartTime - beatIter*0.75f) absolute:NO layer:kLayerType_Background easing:0 position:CGPointMake(437.18383311603651f, 0) scale:(480.0f / _textures[kTexture_Count2].contentSize.height) isTopLeft:YES];
		[tmpItem addTransformation:(kAnimationType_Fade) startTime:(firstHitCircleStartTime - beatIter) endTime:(firstHitCircleStartTime - beatIter*0.75f), 1.0f, 0.0f];
		tmpItem = [_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_Count1] startTime:(firstHitCircleStartTime - beatIter * 2) endTime:(firstHitCircleStartTime - beatIter*0.75f) absolute:NO layer:kLayerType_Background easing:0 position:CGPointMake(195, 0) scale:(480.0f / _textures[kTexture_Count1].contentSize.height) isTopLeft:YES];
		[tmpItem addTransformation:(kAnimationType_Fade) startTime:(firstHitCircleStartTime - beatIter) endTime:(firstHitCircleStartTime - beatIter*0.75f), 1.0f, 0.0f];

		// Go animations
		tmpItem = [_animationSystem addItem:(kAnimationType_Scale|kAnimationType_Fade|kAnimationType_Rotate) texture:_textures[kTexture_CountGo] startTime:(firstHitCircleStartTime - beatIter*1.5f) endTime:(firstHitCircleStartTime - beatIter)+500.0f absolute:NO layer:kLayerType_Background easing:0 position:CGPointMake(SCREEN_SIZE_X / 2.0f, SCREEN_SIZE_Y / 2.0f) scale:0.5f isTopLeft:NO];
		[tmpItem addTransformation:(kAnimationType_Scale|kAnimationType_Fade|kAnimationType_Rotate) startTime:(firstHitCircleStartTime - beatIter*1.5f) endTime:(firstHitCircleStartTime - beatIter), 0.5f, 1.0f, 0.0f, 1.0f, -270.0f, 0.0f];
		[tmpItem addTransformation:(kAnimationType_Fade) startTime:(firstHitCircleStartTime - beatIter) endTime:(firstHitCircleStartTime - beatIter)+500.0f, 1.0f, 0.0f];
	}
	else
	{
		_skipTime = firstHitCircleStartTime - 2000.0f;
		for (int i = 0; i < 1300; i += 200)
		{
			[_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_PlayWarningArrow] startTime:firstHitCircleStartTime-_curOsuFile.difficulty_PreEmpt-1000+i endTime:firstHitCircleStartTime-_curOsuFile.difficulty_PreEmpt-900+i absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(120,100) scale:0.7f isTopLeft:NO];
			[_animationSystem addItem:kAnimationType_None texture:_textures[kTexture_PlayWarningArrow] startTime:firstHitCircleStartTime-_curOsuFile.difficulty_PreEmpt-1000+i endTime:firstHitCircleStartTime-_curOsuFile.difficulty_PreEmpt-900+i absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(120,380) scale:0.7f isTopLeft:NO];
			[_animationSystem addItem:kAnimationType_Rotate texture:_textures[kTexture_PlayWarningArrow] startTime:firstHitCircleStartTime-_curOsuFile.difficulty_PreEmpt-1000+i endTime:firstHitCircleStartTime-_curOsuFile.difficulty_PreEmpt-900+i absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(600,100) scale:0.7f isTopLeft:NO, 180.0f, 180.0f];
			[_animationSystem addItem:kAnimationType_Rotate texture:_textures[kTexture_PlayWarningArrow] startTime:firstHitCircleStartTime-_curOsuFile.difficulty_PreEmpt-1000+i endTime:firstHitCircleStartTime-_curOsuFile.difficulty_PreEmpt-900+i absolute:NO layer:kLayerType_Foreground easing:0 position:CGPointMake(600,380) scale:0.7f isTopLeft:NO, 180.0f, 180.0f];
		}
	}
	if (_skipTime < _curTime)
		_skipTime = 0;

	[backgroundItem addTransformation:kAnimationType_Fade startTime:firstHitCircleStartTime-beatIter endTime:firstHitCircleStartTime, 1.0f, 0.5f];

	//[_animationSystem scheduleEvent:kOsuStateActions_GoToRankingScreen atTime:_curOsuFile.general_TotalLength+3000.0f absolute:NO];

	[NSThread setThreadPriority:1.0f];
}

- (void)dealloc
{
	[_beatMap release];
	[_curOsuFile release];
	[_sqlManager release];
	[_settingsManager release];
	[_animationSystem release];
	[_curBeatmapManager release];
	[_avPlayer release];
	
	[window release];
	[glView release];

	[super dealloc];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)app
{
	/*
	static BOOL shown = NO;
	if (!shown)
	{
		[OsuFunctions doAlert:@"Low memory..." withCancel:NO delegate:self];
		shown = YES;
	}
	*/
}

@end
