//
//  TextureManager.m
//  Osu
//
//  Created by Christopher Luu on 9/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SkinManager.h"
#import "SoundEngine.h"
#import "OsuFunctions.h"

#define DO_4444(i) (i > kTexture_MenuBack && (i < kTexture_PauseContinue || i > kTexture_PauseBack) && i != kTexture_RankingRetry && i != kTexture_RankingBackToMainMenu && i != kTexture_SongSelectBackground)

#define DO_LOOP(i) (i == kSound_NormalSliderSlide || i == kSound_NormalSliderWhistle || i == kSound_SoftSliderSlide || i == kSound_SoftSliderWhistle || i == kSound_SpinnerSpin)

void GLDrawEllipse (int segments, CGFloat width, CGFloat height, CGPoint center, BOOL filled)
{
	glPushMatrix();
	glTranslatef(center.x, center.y, 0.0);
	GLfloat vertices[segments*2];
	int count=0;
	for (GLfloat i = 0; i < 360.0f; i+=(360.0f/segments))
	{
		vertices[count++] = (cos(i*PI/180.0f)*width);
		vertices[count++] = (sin(i*PI/180.0f)*height);
	}
	glVertexPointer (2, GL_FLOAT , 0, vertices); 
	glDrawArrays ((filled) ? GL_TRIANGLE_FAN : GL_LINE_LOOP, 0, segments);
	glPopMatrix();
}

@implementation SkinManager

@synthesize directory;

NSString *_textureFilenames[kNumTextures] = 
{
	@"menu-background.png",
	@"menu-osu.png",
	@"menu-button-freeplay.png",
	@"menu-button-freeplay-over.png",
	@"menu-button-options.png",
	@"menu-button-options-over.png",
	@"menu-back.png",
	@"menu-button-background.png",
	@"ranking-X-small.png",
	@"ranking-S-small.png",
	@"ranking-A-small.png",
	@"ranking-B-small.png",
	@"ranking-C-small.png",
	@"ranking-D-small.png",
	@"star.png",
	@"songselect-background.png",
	@"selection-tab.png",
	@"pause-continue.png",
	@"pause-retry.png",
	@"pause-back.png",
	@"hitcircle.png",
	@"hitcircleoverlay.png",
	@"approachcircle.png",
	@"sliderscorepoint.png",
	@"sliderfollowcircle.png",
	@"sliderpoint10.png",
	@"sliderpoint30.png",
	@"reversearrow.png",
	@"spinner-background.png",
	@"spinner-approachcircle.png",
	@"spinner-circle.png",
	@"spinner-metre.png",
	@"spinner-spin.png",
	@"spinner-osu.png",
	@"spinner-clear.png",
	@"scorebar-bg.png",
	@"scorebar-colour-0.png",
	@"scorebar-ki.png",
	@"scorebar-kidanger.png",
	@"scorebar-kidanger2.png",
	@"ready.png",
	@"count3.png",
	@"count2.png",
	@"count1.png",
	@"go.png",
	@"play-warningarrow.png",
	@"levelbar-bg.png",
	@"levelbar.png",
	@"section-fail.png",
	@"section-pass.png",
	@"followpoint.png",
	@"play-skip.png",
	@"hit0.png",
	@"hit50.png",
	@"hit100.png",
	@"hit100k.png",
	@"hit300.png",
	@"hit300g.png",
	@"hit300k.png",
	@"score-0.png",
	@"score-1.png",
	@"score-2.png",
	@"score-3.png",
	@"score-4.png",
	@"score-5.png",
	@"score-6.png",
	@"score-7.png",
	@"score-8.png",
	@"score-9.png",
	@"score-comma.png",
	@"score-dot.png",
	@"score-percent.png",
	@"score-x.png",
	@"default-0.png",
	@"default-1.png",
	@"default-2.png",
	@"default-3.png",
	@"default-4.png",
	@"default-5.png",
	@"default-6.png",
	@"default-7.png",
	@"default-8.png",
	@"default-9.png",
	@"sliderb0.png",
	@"sliderb1.png",
	@"sliderb2.png",
	@"sliderb3.png",
	@"sliderb4.png",
	@"sliderb5.png",
	@"sliderb6.png",
	@"sliderb7.png",
	@"sliderb8.png",
	@"sliderb9.png",
	@"ranking-title.png",
	@"ranking-panel.png",
	@"ranking-graph.png",
	@"ranking-maxcombo.png",
	@"ranking-accuracy.png",
	@"ranking-retry.png",
	@"ranking-back.png",
	@"ranking-perfect.png",
	@"ranking-X.png",
	@"ranking-S.png",
	@"ranking-A.png",
	@"ranking-B.png",
	@"ranking-C.png",
	@"ranking-D.png",
};

NSString *_soundFilenames[kNumSounds] = 
{
	@"normal-hitnormal.wav",
	@"normal-hitwhistle.wav",
	@"normal-hitfinish.wav",
	@"normal-hitclap.wav",
	@"normal-sliderslide.wav",
	@"normal-slidertick.wav",
	@"normal-sliderwhistle.wav",
	@"soft-hitnormal.wav",
	@"soft-hitwhistle.wav",
	@"soft-hitfinish.wav",
	@"soft-hitclap.wav",
	@"soft-sliderslide.wav",
	@"soft-slidertick.wav",
	@"soft-sliderwhistle.wav",
	@"spinnerspin.wav",
	@"spinnerbonus.wav",
	@"menuhit.wav",
	@"menuback.wav",
	@"menuclick.wav",
	@"readys.wav",
	@"count3s.wav",
	@"count2s.wav",
	@"count1s.wav",
	@"gos.wav",
	@"combobreak.wav",
	@"failsound.wav",
	@"applause.wav",
	@"sectionfail.wav",
	@"sectionpass.wav",
};

/*
- (void)initMenuTextures
{
	for (int i = kTexture_MenuBackground; i <= kTexture_SongSelectTab; i++)
		_textures[i] = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", directory, _textureFilenames[i]]]];
}

- (void)releaseMenuTextures
{
	for (int i = kTexture_MenuBackground; i <= kTexture_SongSelectTab; i++)
		[_textures[i] release];
}
*/

- (void)initRankingTextures
{
	for (int i = kTexture_RankingTitle; i <= kTexture_RankingPerfect; i++)
	{
		_textures[i] = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", directory, _textureFilenames[i]]] with4444:DO_4444(i)];
	}
	for (int i = kTexture_RankingSS; i <= kTexture_RankingD; i++)
		_textures[i] = NULL;
}

- (void)releaseRankingTextures
{
	for (int i = kTexture_RankingTitle; i <= kTexture_RankingD; i++)
	{
		[_textures[i] release];
		_textures[i] = NULL;
	}
}

- (void)initRankingGrade:(int)grade
{
	_textures[grade] = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", directory, _textureFilenames[grade]]] with4444:DO_4444(grade)];
}

/*
- (void)initGameTextures
{
	int i;

	for (i = kTexture_PauseContinue; i < kTexture_ScoreTextures; i++)
	{
		if (i == kTexture_Hit0 || i == kTexture_SpinnerBackground || i == kTexture_SpinnerCircle || i == kTexture_SpinnerMetre || i == kTexture_LevelBarBg || i == kTexture_LevelBar)
			continue;

		_textures[i] = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", directory, _textureFilenames[i]]]];
		//if (!_textures[i])
		//	NSLog(@"Couldn't find file... %@", _textureFilenames[i]);
	}
}

- (void)releaseGameTextures
{
	int i;

	for (i = kTexture_PauseContinue; i < kTexture_ScoreTextures; i++)
	{
		if (i == kTexture_Hit0 || i == kTexture_SpinnerBackground || i == kTexture_SpinnerCircle || i == kTexture_SpinnerMetre || i == kTexture_LevelBarBg || i == kTexture_LevelBar)
			continue;
		[_textures[i] release];
	}
}
*/

- (NSString *)findFile:(NSString *)inFilename
{
	NSString *toRet;

	toRet = [NSString stringWithFormat:@"%@/%@", directory, inFilename];
	if (![[NSFileManager defaultManager] fileExistsAtPath:toRet]) // not in skin, switch to default
		toRet = [NSString stringWithFormat:@"%@/skins/default/%@", [[NSBundle mainBundle] bundlePath], inFilename];

	return toRet;
}

- (void)initOnTheFlyTextures
{
	glBindTexture(GL_TEXTURE_2D, 0); // unbind any textures?
	_textures[kTexture_WhitePixel] = [[Texture2D alloc] initBlankTexture:CGSizeMake(16,16)];
	[_textures[kTexture_WhitePixel] drawToTexture:YES];

	glClearColor(1.0f,1.0f,1.0f,1.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	[_textures[kTexture_WhitePixel] drawToTexture:NO];

	_textures[kTexture_WhiteCircle] = [[Texture2D alloc] initBlankTexture:CGSizeMake(128,128)];
	[_textures[kTexture_WhiteCircle] drawToTexture:YES];

	glBindTexture(GL_TEXTURE_2D, 0); // unbind any textures?
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

	GLDrawEllipse(360, 58, 58, CGPointMake(64, 64), YES);
	[_textures[kTexture_WhiteCircle] drawToTexture:NO];	
}

- (id)initWithSkin:(NSString*)skinName
{
	if (self = [super init])
	{
		int i;

		if ([skinName compare:@"default"] == 0)
			directory = [[NSString stringWithFormat:@"%@/skins/default", [[NSBundle mainBundle] bundlePath]] retain];
		else
		{
			NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentsDir = [documentPaths objectAtIndex:0];

			directory = [[NSString stringWithFormat:@"%@/osuskins/%@", documentsDir, skinName] retain];
			if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) // couldn't find skin, default
			{
				[directory release];
				directory = [[NSString stringWithFormat:@"%@/skins/default", [[NSBundle mainBundle] bundlePath]] retain];
			}
		}

		for (i = 0; i < kTexture_RankingTitle; i++)
			_textures[i] = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[self findFile:_textureFilenames[i]]] with4444:DO_4444(i)];

		_textures[kTexture_BlackPixel] = [[Texture2D alloc] initBlankTexture:CGSizeMake(1,1)];

		_textures[kTexture_WhitePixel] = NULL;
		_textures[kTexture_WhiteCircle] = NULL;

		_textures[kTexture_TextTitle] = [[Texture2D alloc] initWithString:@"Title" dimensions:CGSizeMake(141, 29) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24];
		_textures[kTexture_TextArtist] = [[Texture2D alloc] initWithString:@"Artist" dimensions:CGSizeMake(141, 29) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24];
		_textures[kTexture_TextNewest] = [[Texture2D alloc] initWithString:@"Newest" dimensions:CGSizeMake(141, 29) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24];
		_textures[kTexture_TextSearch] = [[Texture2D alloc] initWithString:@"Search" dimensions:CGSizeMake(141, 29) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24];
		_textures[kTexture_TextHomepage] = [[Texture2D alloc] initWithString:@"Homepage" dimensions:CGSizeMake(141, 29) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24];

		for (i = 0; i < kNumSounds; i++)
		{
			if (DO_LOOP(i))
				SoundEngine_LoadLoopingEffect([[self findFile:_soundFilenames[i]] UTF8String], NULL, NULL, &_sounds[i]);
			else
				SoundEngine_LoadEffect([[self findFile:_soundFilenames[i]] UTF8String], &_sounds[i]);
		}

		_replacedObjects = [[NSMutableArray alloc] init];

		return self;
	}
	return NULL;
}

- (Texture2D**)getTextures
{
	return _textures;
}

- (UInt32 *)getSounds
{
	return _sounds;
}

- (void)replaceObjectsWithDirectory:(NSString *)inDir
{
	int i;

	[_replacedObjects removeAllObjects];
	for (NSString *fileName in [[NSFileManager defaultManager] directoryContentsAtPath:inDir])
	{
		if ([[fileName pathExtension] caseInsensitiveCompare:@"png"] == 0)
		{
			//NSLog(@"Looking for replacement object for %@", fileName);
			for (i = kTexture_HitCircle; i < kTexture_RankingTitle; i++)
			{
				if ([fileName compare:_textureFilenames[i]] == 0)
				{
					[_textures[i] release];
					_textures[i] = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", inDir, _textureFilenames[i]]] with4444:YES];
					[_replacedObjects addObject:[NSNumber numberWithInt:i]];
					break;
				}
			}
		}
		else if ([[fileName pathExtension] caseInsensitiveCompare:@"wav"] == 0)
		{
			//NSLog(@"Looking for replacement object for %@", fileName);
			for (i = 0; i < kNumSounds; i++)
			{
				if ([fileName compare:_soundFilenames[i]] == 0)
				{
					SoundEngine_UnloadEffect(_sounds[i]);
					if (DO_LOOP(i))
						SoundEngine_LoadLoopingEffect([[NSString stringWithFormat:@"%@/%@", inDir, _soundFilenames[i]] UTF8String], NULL, NULL, &_sounds[i]);
					else
						SoundEngine_LoadEffect([[NSString stringWithFormat:@"%@/%@", inDir, _soundFilenames[i]] UTF8String], &_sounds[i]);
					[_replacedObjects addObject:[NSNumber numberWithInt:i+1000]];
					break;
				}
			}
		}
	}
}

- (void)restoreReplacedObjects
{
	for (NSNumber *num in _replacedObjects)
	{
		int i = [num intValue];
		if (i < 1000) // texture
		{
			[_textures[i] release];
			_textures[i] = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[self findFile:_textureFilenames[i]]] with4444:DO_4444(i)];
		}
		else // sound
		{
			i -= 1000;
			SoundEngine_UnloadEffect(_sounds[i]);
			if (DO_LOOP(i))
				SoundEngine_LoadLoopingEffect([[self findFile:_soundFilenames[i]] UTF8String], NULL, NULL, &_sounds[i]);
			else
				SoundEngine_LoadEffect([[self findFile:_soundFilenames[i]] UTF8String], &_sounds[i]);
		}
	}
	[_replacedObjects removeAllObjects];
}

- (void)dealloc
{
	[directory release];
	for (int i = 0; i < kNumTextures; i++)
		[_textures[i] release];
	
	[super dealloc];
}

@end
