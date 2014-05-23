//
//  Beatmap.m
//  Osu
//
//  Created by Christopher Luu on 8/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Beatmap.h"
#import <sqlite3.h>
#import "OsuAppDelegate.h"

@implementation Beatmap

@synthesize directory;
@synthesize title;
@synthesize artist;
@synthesize creator;
@synthesize playcount;
@synthesize osuFileArray;

NSInteger osuFileSort(id osu1, id osu2, void *context)
{
	float v1 = ((OsuFiletype*)osu1).difficulty_EyupStars;
	float v2 = ((OsuFiletype*)osu2).difficulty_EyupStars;

	if (v1 < v2)
		return NSOrderedAscending;
	else if (v1 > v2)
		return NSOrderedDescending;

	return NSOrderedSame;
}

- (void)sortOsuFiles
{
	[osuFileArray sortUsingFunction:osuFileSort context:NULL];
}

- (id)initWithDirectory:(NSString*)inDir
{
	if (self = [super init])
	{
		NSString *fileName;
		OsuFiletype *tmpFile;

		directory = [[NSString stringWithFormat:@"%@/osu/beatmaps/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], inDir] retain];

		//NSLog(@"Initializing Beatmap with directory: %@\n", directory);

		osuFileArray = [[NSMutableArray alloc] init];
		for (fileName in [[NSFileManager defaultManager] enumeratorAtPath:directory])
		{
			if ([[fileName pathExtension] caseInsensitiveCompare:@"osu"] == 0)
			{
				//NSLog(@"Listing file: %@\n", fileName);

				tmpFile = [[OsuFiletype alloc] initWithFilename:[NSString stringWithFormat:@"%@/%@", directory, fileName]];
				if (tmpFile)
				{
					[osuFileArray addObject:tmpFile];
					[tmpFile release];
				}
			}
		}

		// Compare the common fields of the osu files for sanity check
		if ([osuFileArray count] <= 0)
		{
			[directory release];
			[osuFileArray release];

			return NULL;
		}
#if 0
		else if ([osuFileArray count] > 1)
		{
			tmpFile = [osuFileArray objectAtIndex:0];
			for (int i = 1; i < [osuFileArray count]; i++)
			{
				if ([tmpFile matchGenericData:[osuFileArray objectAtIndex:i]] == NO)
				{
					//NSLog(@"Generic Osu data does not match!\n");
					[directory release];
					[osuFileArray release];

					return NULL;
				}
			}
		}
#endif

		//[self sortOsuFiles];
		title = [((OsuFiletype*)[osuFileArray objectAtIndex:0]).metaData_Title retain];
		artist = [((OsuFiletype*)[osuFileArray objectAtIndex:0]).metaData_Artist retain];
		creator = [((OsuFiletype*)[osuFileArray objectAtIndex:0]).metaData_Creator retain];

		//for (int i = 0; i < [_osuFileArray count]; i++)
			//NSLog(@"Ordered Array: '%@'\n", ((OsuFiletype*)[_osuFileArray objectAtIndex:i]).metaData_Version);
		return self;
	}
	return NULL;
}

- (id)initWithURL:(NSString *)inURL artist:(NSString *)inArtist title:(NSString *)inTitle
{
	if (self = [super init])
	{
		directory = [inURL retain];
		artist = [inArtist retain];
		title = [inTitle retain];
		return self;
	}
	return NULL;
}

- (id)initWithTitle:(NSString *)inTitle artist:(NSString *)inArtist creator:(NSString *)inCreator directory:(NSString *)inDirectory;
{
	if (self = [super init])
	{
		title = [inTitle retain];
		artist = [inArtist retain];
		creator = [inCreator retain];
		directory = [[NSString stringWithFormat:@"%@/osu/beatmaps/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], inDirectory] retain];
		playcount = 0;
		return self;
	}
	return NULL;
}

- (OsuFiletype*)getOsuFile:(int)index
{
	return [osuFileArray objectAtIndex:index];
}

- (int)getOsuFileCount
{
	return [osuFileArray count];
}

- (void)addOsuFile:(OsuFiletype*)inOsuFile
{
	if (!osuFileArray)
		osuFileArray = [[NSMutableArray alloc] init];
	[osuFileArray addObject:inOsuFile];
	playcount += inOsuFile.general_Playcount;
}

- (void)dealloc
{
	if (osuFileArray)
		[osuFileArray release];
	[directory release];
	[title release];
	[artist release];

	[super dealloc];
}

- (BOOL)isEqual:(id)anObject
{
	Beatmap *tmpBeatmap = anObject;
	return [directory isEqual:tmpBeatmap.directory];
}

- (void)updateDB:(eBeatmapDBUpdate)what
{
	sqlite3 *database = [SQL_MANAGER openDB];
	sqlite3_stmt *compiledStatement;
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
	char *statement;

	switch(what)
	{
		case kBeatmapDBUpdate_Playcount:
			[osuFileArray makeObjectsPerformSelector:@selector(putPlaycountIntoArray:) withObject:tmpArray];
			statement = "UPDATE beatmaps SET playcount = ? WHERE md5sums = ?";
			break;
		case kBeatmapDBUpdate_Highscores:
			[osuFileArray makeObjectsPerformSelector:@selector(putHighscoresIntoArray:) withObject:tmpArray];
			statement = "UPDATE beatmaps SET highscores = ? WHERE md5sums = ?";
			break;
		default:
			break;
	}

	if(sqlite3_prepare_v2(database, statement, -1, &compiledStatement, NULL) == SQLITE_OK)
	{
		sqlite3_bind_text(compiledStatement, 1, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
		[tmpArray removeAllObjects];
		[osuFileArray makeObjectsPerformSelector:@selector(putMd5SumsIntoArray:) withObject:tmpArray];
		sqlite3_bind_text(compiledStatement, 2, [[tmpArray componentsJoinedByString:@"|"] UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(compiledStatement) != SQLITE_DONE)
			NSLog(@"Error while inserting data. '%s'", sqlite3_errmsg(database));
		if (sqlite3_total_changes(database) == 0)
			[OsuFunctions doAlert:@"One of the Osu Files associated with this beatmap has been modified." withCancel:NO delegate:self];
		sqlite3_finalize(compiledStatement);
	}
	[SQL_MANAGER closeDB];
	[tmpArray release];
}

@end
