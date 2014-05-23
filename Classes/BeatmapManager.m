//
//  BeatmapManager.m
//  Osu
//
//  Created by Christopher Luu on 10/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BeatmapManager.h"
#import "OsuAppDelegate.h"

@implementation BeatmapManager

@synthesize numBeatmaps;
@synthesize loadedBeatmaps;

- (void)loadBeatmaps
{
	_beatmaps = [[NSMutableArray alloc] init];
	_sql = SQL_MANAGER;
	
	NSString *fileName;
	Beatmap *tmpBeatmap;
	sqlite3_stmt *compiledStatement;

	if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/osu/beatmaps", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]]])
		[[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/osu/beatmaps", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]] withIntermediateDirectories:YES attributes:NULL error:NULL];

	numBeatmaps = [[[NSFileManager defaultManager] directoryContentsAtPath:[NSString stringWithFormat:@"%@/osu/beatmaps", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]]] count];
	loadedBeatmaps = 0;

	_database = [_sql openDB];
	for (fileName in [[NSFileManager defaultManager] directoryContentsAtPath:[NSString stringWithFormat:@"%@/osu/beatmaps", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]]])
	{
		if(sqlite3_prepare_v2(_database, "SELECT * FROM beatmaps WHERE directory = ?", -1, &compiledStatement, NULL) == SQLITE_OK)
		{
			sqlite3_bind_text(compiledStatement, 1, [fileName UTF8String], -1, SQLITE_TRANSIENT);
			if (sqlite3_step(compiledStatement) == SQLITE_ROW)
			{
				tmpBeatmap = [[Beatmap alloc] initWithTitle:[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 2)] artist:[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 3)] creator:[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 4)] directory:fileName];
				
				NSArray *tmpFilenames = [[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 5)] componentsSeparatedByString:@"|"];
				NSArray *tmpDifficultyTexts = [[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 7)] componentsSeparatedByString:@"|"];
				NSArray *tmpHpDropRates = [[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 8)] componentsSeparatedByString:@"|"];
				NSArray *tmpHpMultiplierNormals = [[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 9)] componentsSeparatedByString:@"|"];
				NSArray *tmpHpMultiplierComboEnds = [[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 10)] componentsSeparatedByString:@"|"];
				NSArray *tmpDifficultyStars = [[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 11)] componentsSeparatedByString:@"|"];
				NSArray *tmpPlaycount = [[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 12)] componentsSeparatedByString:@"|"];
				NSArray *tmpHighscores = NULL;
				if (sqlite3_column_text(compiledStatement, 13))
					tmpHighscores = [[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 13)] componentsSeparatedByString:@"|"];

				OsuFiletype *tmpOsufile;
				for (int i = 0; i < [tmpFilenames count]; i++)
				{
					tmpOsufile = [[OsuFiletype alloc] initWithTitle:tmpBeatmap.title artist:tmpBeatmap.artist creator:tmpBeatmap.creator filename:[NSString stringWithFormat:@"%@/%@", tmpBeatmap.directory, [tmpFilenames objectAtIndex:i]] difficultyText:[tmpDifficultyTexts objectAtIndex:i] difficultyEyupStars:[[tmpDifficultyStars objectAtIndex:i] floatValue] hpDropRate:[[tmpHpDropRates objectAtIndex:i] floatValue] hpMultiplierNormal:[[tmpHpMultiplierNormals objectAtIndex:i] floatValue] hpMultiplierComboEnd:[[tmpHpMultiplierComboEnds objectAtIndex:i] floatValue] playcount:[[tmpPlaycount objectAtIndex:i] intValue] highscores:tmpHighscores ? [tmpHighscores objectAtIndex:i] : NULL];
					[tmpBeatmap addOsuFile:tmpOsufile];
				}
				[_beatmaps addObject:tmpBeatmap];
				[tmpBeatmap release];
				sqlite3_finalize(compiledStatement);
			}
			else
			{
				sqlite3_finalize(compiledStatement);
				tmpBeatmap = [[Beatmap alloc] initWithDirectory:fileName];
				if (tmpBeatmap)
					[self addBeatmap:tmpBeatmap];
			}
		}
		loadedBeatmaps++;
	}
	[_sql closeDB];
	_database = NULL;
}

- (NSArray *)getSortedBeatmaps:(NSString *)key
{
	NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:key ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
	NSArray *sortDescriptor = [NSArray arrayWithObject:descriptor];

	return [_beatmaps sortedArrayUsingDescriptors:sortDescriptor];
}

- (void)addBeatmap:(Beatmap *)tmpBeatmap
{
	OsuFiletype *tmpOsufile;
	[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] setBeatmap:tmpBeatmap];
	sqlite3_stmt *compiledStatement;

	BOOL openedDB = NO;

	if (!_database)
	{
		openedDB = YES;
		_database = [_sql openDB];
	}

	for (int i = 0; i < [tmpBeatmap getOsuFileCount]; i++)
	{
		tmpOsufile = [tmpBeatmap getOsuFile:i];
		[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] setOsufile:tmpOsufile];
		[tmpOsufile processHitObjects];
		[tmpOsufile calcHPDropRate];
	}
	[tmpBeatmap sortOsuFiles];
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
	
	sqlite3_prepare_v2(_database, "INSERT INTO beatmaps (directory, title, artist, creator, osuFilenames, md5sums, difficultyText, hpDropRates, hpMultiplierNormals, hpMultiplierComboEnds, difficultyStars, playcount) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, &compiledStatement, NULL);
	sqlite3_bind_text(compiledStatement, 1, [[tmpBeatmap.directory lastPathComponent] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(compiledStatement, 2, [tmpBeatmap.title UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(compiledStatement, 3, [tmpBeatmap.artist UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(compiledStatement, 4, [tmpBeatmap.creator UTF8String], -1, SQLITE_TRANSIENT);
	[tmpBeatmap.osuFileArray makeObjectsPerformSelector:@selector(putFilenameIntoArray:) withObject:tmpArray];
	sqlite3_bind_text(compiledStatement, 5, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
	[tmpArray removeAllObjects];
	[tmpBeatmap.osuFileArray makeObjectsPerformSelector:@selector(putMd5SumsIntoArray:) withObject:tmpArray];
	sqlite3_bind_text(compiledStatement, 6, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
	[tmpArray removeAllObjects];
	[tmpBeatmap.osuFileArray makeObjectsPerformSelector:@selector(putDifficultyTextIntoArray:) withObject:tmpArray];
	sqlite3_bind_text(compiledStatement, 7, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
	[tmpArray removeAllObjects];
	[tmpBeatmap.osuFileArray makeObjectsPerformSelector:@selector(putHpDrainRatesIntoArray:) withObject:tmpArray];
	sqlite3_bind_text(compiledStatement, 8, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
	[tmpArray removeAllObjects];
	[tmpBeatmap.osuFileArray makeObjectsPerformSelector:@selector(putHpMultiplierNormalsIntoArray:) withObject:tmpArray];
	sqlite3_bind_text(compiledStatement, 9, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
	[tmpArray removeAllObjects];
	[tmpBeatmap.osuFileArray makeObjectsPerformSelector:@selector(putHpMultiplierComboEndsIntoArray:) withObject:tmpArray];
	sqlite3_bind_text(compiledStatement, 10, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
	[tmpArray removeAllObjects];
	[tmpBeatmap.osuFileArray makeObjectsPerformSelector:@selector(putDifficultyStarsIntoArray:) withObject:tmpArray];
	sqlite3_bind_text(compiledStatement, 11, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
	[tmpArray removeAllObjects];
	[tmpBeatmap.osuFileArray makeObjectsPerformSelector:@selector(putPlaycountIntoArray:) withObject:tmpArray];
	sqlite3_bind_text(compiledStatement, 12, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
	
	if (sqlite3_step(compiledStatement) != SQLITE_DONE)
		NSLog(@"Error while inserting data. '%s'", sqlite3_errmsg(_database));
	sqlite3_finalize(compiledStatement);
	
	[tmpArray release];
	
	Beatmap *tmpBeatmap2 = [[Beatmap alloc] initWithTitle:tmpBeatmap.title artist:tmpBeatmap.artist creator:tmpBeatmap.creator directory:[tmpBeatmap.directory lastPathComponent]];
	for (OsuFiletype *tmpOsufile2 in tmpBeatmap.osuFileArray)
	{
		tmpOsufile = [[OsuFiletype alloc] initWithTitle:tmpBeatmap2.title artist:tmpBeatmap2.artist creator:tmpBeatmap2.creator filename:tmpOsufile2.filename difficultyText:tmpOsufile2.metaData_Version difficultyEyupStars:tmpOsufile2.difficulty_EyupStars hpDropRate:tmpOsufile2.HpDropRate hpMultiplierNormal:tmpOsufile2.HpMultiplierNormal hpMultiplierComboEnd:tmpOsufile2.HpMultiplierComboEnd playcount:0 highscores:NULL];
		[tmpBeatmap2 addOsuFile:tmpOsufile];
		[tmpOsufile release];
	}
	[_beatmaps addObject:tmpBeatmap2];
	[tmpBeatmap2 release];
	[tmpBeatmap release];
	
	if (openedDB)
	{
		[_sql closeDB];
		_database = NULL;
	}
}

- (void)removeBeatmap:(Beatmap *)delBeatmap
{
	BOOL openedDB = NO;
	sqlite3_stmt *compiledStatement;

	if (!_database)
		_database = [_sql openDB];
	sqlite3_prepare_v2(_database, "DELETE FROM beatmaps WHERE directory = ?", -1, &compiledStatement, NULL);
	sqlite3_bind_text(compiledStatement, 1, [[delBeatmap.directory lastPathComponent] UTF8String], -1, SQLITE_TRANSIENT);
	if (sqlite3_step(compiledStatement) != SQLITE_DONE)
		NSLog(@"Error while removing beatmap. '%s'", sqlite3_errmsg(_database));
	sqlite3_finalize(compiledStatement);

	if (openedDB)
	{
		[_sql closeDB];
		_database = NULL;
	}

	[_beatmaps removeObject:delBeatmap];
}

- (void)dealloc
{
	[_beatmaps release];
	[_sql release];

	[super dealloc];
}

@end
