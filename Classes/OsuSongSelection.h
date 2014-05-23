//
//  OsuSongSelection.h
//  Osu
//
//  Created by Christopher Luu on 10/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Texture2D.h"
#import "BeatmapManager.h"

typedef enum
{
	kSongSelectionStates_SearchResults,
	kSongSelectionStates_Newest,
	kSongSelectionStates_SortedByTitle,
	kSongSelectionStates_SortedByArtist,
	kSongSelectionStates_DifficultySelect,
	kSongSelectionStates_Scoreboard,
	kSongSelectionStates_Downloading,
} eSongSelection_States;

@interface OsuSongSelection : NSObject <UITextFieldDelegate, UIAlertViewDelegate>
{
	UITextField *_searchField;
	Texture2D *_descTexture;

	NSArray *_curBeatmaps;
	Texture2D **_textures;
	BeatmapManager *_manager;
	NSMutableArray *_txtTextures;
	UInt32 *_sounds;
	Beatmap *_selectedBeatmap;
	OsuFiletype *_selectedOsufile;

	int _selectedIndex;
	eSongSelection_States _curState, _lastState, _lastSortedBy;
	CGPoint _curLocation;
	float _curPosition, _curVelocity;
	int _touchDown;

	// download stuff
	NSURLConnection *_downloader;
	NSMutableData *_downloadedData;
	int _totalDownloadLength;
}

- (id)initWithTextures:(Texture2D **)textures manager:(BeatmapManager *)manager sounds:(UInt32 *)sounds;
- (void)drawSongSelection;
- (BOOL)doTouch:(int)type location:(CGPoint)location;
- (void)goToState:(eSongSelection_States)newState;

@end
