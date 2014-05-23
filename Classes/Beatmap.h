//
//  Beatmap.h
//  Osu
//
//  Created by Christopher Luu on 8/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OsuFiletype.h"

typedef enum
{
	kBeatmapDBUpdate_Playcount,
	kBeatmapDBUpdate_Highscores,
} eBeatmapDBUpdate;

@interface Beatmap : NSObject {

@private
	NSString *directory;
	NSString *title;
	NSString *artist;
	NSString *creator;
	int playcount;

	NSMutableArray *osuFileArray;
}

@property(readonly) NSString *directory;
@property(readonly) NSString *title;
@property(readonly) NSString *artist;
@property(readonly) NSString *creator;
@property int playcount;
@property(readonly) NSMutableArray *osuFileArray;

- (id)initWithDirectory:(NSString*)inDir;
- (id)initWithURL:(NSString *)inURL artist:(NSString *)inArtist title:(NSString *)inTitle;
- (id)initWithTitle:(NSString *)inTitle artist:(NSString *)inArtist creator:(NSString *)inCreator directory:(NSString *)inDirectory;

- (OsuFiletype*)getOsuFile:(int)index;
- (int)getOsuFileCount;
- (void)addOsuFile:(OsuFiletype*)inOsuFile;
- (void)sortOsuFiles;
- (void)updateDB:(eBeatmapDBUpdate)what;

@end
