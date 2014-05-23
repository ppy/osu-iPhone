//
//  BeatmapManager.h
//  Osu
//
//  Created by Christopher Luu on 10/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Beatmap.h"
#import "SQLManager.h"

@interface BeatmapManager : NSObject
{
	NSMutableArray *_beatmaps;
	SQLManager *_sql;
	sqlite3 *_database;
	int numBeatmaps;
	int loadedBeatmaps;
}

@property(readonly) int numBeatmaps;
@property(readonly) int loadedBeatmaps;

- (void)loadBeatmaps;
- (NSArray *)getSortedBeatmaps:(NSString *)key;
- (void)addBeatmap:(Beatmap *)newBeatmap;
- (void)removeBeatmap:(Beatmap *)delBeatmap;

@end
