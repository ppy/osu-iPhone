//
//  OsuSongSelection.m
//  Osu
//
//  Created by Christopher Luu on 10/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "OsuSongSelection.h"
#import "SkinManager.h"
#import "SoundEngine.h"
#import "OsuAppDelegate.h"
#import "unzip.h"

#define BUTTONS_LEFT 60
#define BUTTONS_TOP 25
#define BUTTONS_WIDTH 600
#define BUTTONS_HEIGHT 127

#define FRICTION_COEFFICIENT 0.9f

@implementation OsuSongSelection

int tabPositions[] = {50, 191, 409, 550};

- (void)doSearch:(NSString *)query
{
	NSString *newestData = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://osu.ppy.sh/web/osu-search.php?q=%@", [query stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]] encoding:NSASCIIStringEncoding error:nil];
	NSScanner *scanner;
	Texture2D *tmpTexture;
	Beatmap *tmpBeatmap;
	int tmpInt;
	NSString *tmpString = NULL;
	NSArray *tmpArray;
	NSMutableArray *newBeatmaps = [[NSMutableArray alloc] init];

	//NSLog(newestData);
	if (!newestData)
	{
		[OsuFunctions doAlert:@"Could not reach server..." withCancel:NO delegate:self];

		_curState = _lastState;
		return;
	}
	
	scanner = [NSScanner scannerWithString:newestData];

	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
	[scanner scanInt:&tmpInt];

	if (tmpInt < 0)
	{
		[scanner scanUpToString:@"\0" intoString:&tmpString];
		[OsuFunctions doAlert:tmpString withCancel:NO delegate:self];
		[self goToState:_lastState];
		return;
	}
	else if (tmpInt == 0)
		[OsuFunctions doAlert:@"Your query returned no results" withCancel:NO delegate:self];

	[_txtTextures removeAllObjects];
	[_curBeatmaps release];

	for (int i = 0; i < tmpInt; i++)
	{
		// [0-filename]|[1-artist]|[2-title]|[3-creator]|[4-approved]|[5-rating]|[6-last_update]|[7-beatmapset_id]|[8-thread_id]|[9-video]|[10-storyboard]|[11-filesize]|[12-filesize_novideo]
		[scanner scanUpToString:@"\n" intoString:&tmpString];
		tmpArray = [tmpString componentsSeparatedByString:@"|"];

		if ([[tmpArray objectAtIndex:0] length] > 0)
		{
			//filename = [filename stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			//NSString *toAdd;
			if ([[tmpArray objectAtIndex:1] length] > 0)
				tmpString = [NSString stringWithFormat:@"%@ - %@", [tmpArray objectAtIndex:1], [tmpArray objectAtIndex:2]];
			else
				tmpString = [tmpArray objectAtIndex:2];
			tmpString = [NSString stringWithFormat:@"%@\n%@", tmpString, [tmpArray objectAtIndex:3]];
			tmpTexture = [[Texture2D alloc] initWithString:tmpString dimensions:CGSizeMake(500, 64) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
			[_txtTextures addObject:tmpTexture];
			[tmpTexture release];

			tmpString = [NSString stringWithFormat:@"%@|%@", [tmpArray objectAtIndex:0], [tmpArray objectAtIndex:7]];
			if ([[tmpArray objectAtIndex:9] boolValue])
				tmpString = [NSString stringWithFormat:@"%@n", tmpString];

			tmpBeatmap = [[Beatmap alloc] initWithURL:tmpString artist:[tmpArray objectAtIndex:1] title:[tmpArray objectAtIndex:2]];
			[newBeatmaps addObject:tmpBeatmap];
			[tmpBeatmap release];
		}
	}
	_curBeatmaps = newBeatmaps;	
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[textField removeFromSuperview];
	if ([textField.text length] > 0)
	{
		_lastState = _curState;
		_curState = kSongSelectionStates_SearchResults;
		[self doSearch:textField.text];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (_searchField == textField)
	{
		[textField resignFirstResponder];
	}
	return YES;
}

- (void)goToState:(eSongSelection_States)newState
{
	Beatmap *tmpBeatmap;
	Texture2D *tmpTexture;

	if (_curState == kSongSelectionStates_SearchResults)
		[_searchField removeFromSuperview];

	if (newState != kSongSelectionStates_SearchResults)
	{
		_lastState = _curState;
		_curState = newState;
	}

	switch(newState)
	{
		case kSongSelectionStates_SortedByTitle:
		case kSongSelectionStates_SortedByArtist:
		{
			_lastSortedBy = newState;

			if (_curBeatmaps)
				[_curBeatmaps release];
			[_txtTextures removeAllObjects];

			_curBeatmaps = [[_manager getSortedBeatmaps:(newState == kSongSelectionStates_SortedByTitle ? @"title" : @"artist")] retain];
			for (tmpBeatmap in _curBeatmaps)
			{
				NSString *toAdd;
				if ([tmpBeatmap.artist length] == 0)
					toAdd = tmpBeatmap.title;
				else if (newState == kSongSelectionStates_SortedByTitle)
					toAdd = [NSString stringWithFormat:@"%@ (%@)", tmpBeatmap.title, tmpBeatmap.artist];
				else
					toAdd = [NSString stringWithFormat:@"%@ - %@", tmpBeatmap.artist, tmpBeatmap.title];
				toAdd = [NSString stringWithFormat:@"%@\n                           %@", toAdd, tmpBeatmap.creator];

				tmpTexture = [[Texture2D alloc] initWithString:toAdd dimensions:CGSizeMake(500, 64) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];

				[_txtTextures addObject:tmpTexture];
				[tmpTexture release];
			}
			break;
		}

		case kSongSelectionStates_DifficultySelect:
		{
			[_txtTextures removeAllObjects];

			tmpTexture = [[Texture2D alloc] initWithString:@"Back..." dimensions:CGSizeMake(500, 64) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
			[_txtTextures addObject:tmpTexture];
			[tmpTexture release];
			for (int i = 0; i < [_selectedBeatmap getOsuFileCount]; i++)
			{
				tmpTexture = [[Texture2D alloc] initWithString:[NSString stringWithFormat:@"%@ [%@]\n                           %@", [_selectedBeatmap getOsuFile:i].metaData_Title, [_selectedBeatmap getOsuFile:i].metaData_Version, [_selectedBeatmap getOsuFile:i].metaData_Creator] dimensions:CGSizeMake(500, 64) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
				[_txtTextures addObject:tmpTexture];
				[tmpTexture release];
			}
			break;
		}

		case kSongSelectionStates_Scoreboard:
		{
			[_txtTextures removeAllObjects];

			tmpTexture = [[Texture2D alloc] initWithString:@"Back..." dimensions:CGSizeMake(500, 64) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
			[_txtTextures addObject:tmpTexture];
			[tmpTexture release];

			tmpTexture = [[Texture2D alloc] initWithString:[NSString stringWithFormat:@"%@ [%@]\n                           %@", _selectedOsufile.metaData_Title, _selectedOsufile.metaData_Version, _selectedOsufile.metaData_Creator] dimensions:CGSizeMake(500, 64) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
			[_txtTextures addObject:tmpTexture];
			[tmpTexture release];

			NSArray *tmpHighscores = [_selectedOsufile getHighscores];
			if (tmpHighscores && [tmpHighscores count] > 0)
			{
				NSArray *tmpArray;
				NSNumberFormatter *tmpNumberFormatter = [[NSNumberFormatter alloc] init];
				[tmpNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];

				int i = 1;
				for (NSString *tmpString in tmpHighscores)
				{
					if (tmpString && tmpString.length > 0)
					{
						tmpArray = [tmpString componentsSeparatedByString:@","];
						tmpTexture = [[Texture2D alloc] initWithString:[NSString stringWithFormat:@"          #%d %@\n          Score: %@ Combo:%d", i, [tmpArray objectAtIndex:3], [tmpNumberFormatter stringFromNumber:[NSNumber numberWithInt:[[tmpArray objectAtIndex:0] intValue]]], [[tmpArray objectAtIndex:2] intValue]] dimensions:CGSizeMake(500, 64) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
						[_txtTextures addObject:tmpTexture];
						[tmpTexture release];
						i++;
					}
				}
				[tmpNumberFormatter release];
			}

			break;
		}

		case kSongSelectionStates_SearchResults:
		{
			UIWindow *window = [[UIApplication sharedApplication] keyWindow];
			[window addSubview:_searchField];
			[_searchField becomeFirstResponder];
			break;
		}

		case kSongSelectionStates_Newest:
		{
			[self doSearch:@"Newest"];
			break;
		}
	}

	_curPosition = 0.0f;
}

- (void)makeSelection:(int)selection
{
	BOOL validInput = NO;

	switch(_curState)
	{
		case kSongSelectionStates_SortedByTitle:
		case kSongSelectionStates_SortedByArtist:
		{
			_selectedBeatmap = [_curBeatmaps objectAtIndex:selection];
			[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] setBeatmap:_selectedBeatmap];
			if ([_selectedBeatmap getOsuFileCount] == 1) // if only one song, go right to scoreboard
			{
				_selectedOsufile = [_selectedBeatmap getOsuFile:0];
				[self goToState:kSongSelectionStates_Scoreboard];
			}
			else
				[self goToState:kSongSelectionStates_DifficultySelect];
			validInput = YES;
		}
		break;

		case kSongSelectionStates_DifficultySelect:
		{
			if (selection == 0)
				[self goToState:_lastSortedBy];
			else
			{
				_selectedOsufile = [_selectedBeatmap getOsuFile:(selection - 1)];
				[self goToState:kSongSelectionStates_Scoreboard];
			}
			validInput = YES;
		}
		break;

		case kSongSelectionStates_SearchResults:
		case kSongSelectionStates_Newest:
		{
			Beatmap *tmpBeatmap = [_curBeatmaps objectAtIndex:selection];

			_lastState = _curState;
			_curState = kSongSelectionStates_Downloading;

			NSLog(@"Downloading URL: %@", [NSString stringWithFormat:@"http://osu.ppy.sh/d/%@", [[tmpBeatmap.directory componentsSeparatedByString:@"|"] objectAtIndex:1]]);
			//NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://peppy.chigau.com/bss/%@", [[NSString stringWithFormat:@"%@-novid.osz", [tmpBeatmap.directory stringByDeletingPathExtension]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
			NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://osu.ppy.sh/d/%@", [[tmpBeatmap.directory componentsSeparatedByString:@"|"] objectAtIndex:1]]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];

#ifdef TARGET_IPHONE_SIMULATOR
			[req setValue:@"Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en)" forHTTPHeaderField:@"User-Agent"];
#endif

			// create the downloader
			_downloadedData = [[NSMutableData alloc] init];
			_downloader = [[NSURLConnection alloc] initWithRequest:req delegate:self];

			_selectedIndex = selection;

			validInput = YES;
		}
		break;

		case kSongSelectionStates_Scoreboard:
		{
			if (selection == 0)
			{
				if ([_selectedBeatmap getOsuFileCount] == 1)
					[self goToState:_lastSortedBy];
				else
					[self goToState:kSongSelectionStates_DifficultySelect];
				validInput = YES;
			}
			else if (selection == 1)
			{
				SoundEngine_StartEffect(_sounds[kSound_MenuClick]);
				[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] startGame:_selectedOsufile];
				return;
			}
		}
		break;
	}
	if (validInput)
		SoundEngine_StartEffect(_sounds[kSound_MenuClick]);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog([response MIMEType]);
	if ([[response MIMEType] caseInsensitiveCompare:@"application/download"] != NSOrderedSame)
	{
		/*
		if ([[response suggestedFilename] rangeOfString:@"-novid"].location != NSNotFound)
		{
			Beatmap *tmpBeatmap = [_curBeatmaps objectAtIndex:_selectedIndex];

			NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://peppy.chigau.com/bss/%@", [tmpBeatmap.directory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];

			[_downloader cancel];
			[_downloader release];
			_downloader = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		}
		else
		*/
		{
			[self goToState:_lastState];
			if (_lastState == kSongSelectionStates_SearchResults)
				_curState = _lastState;

			[_downloader cancel];
			[_downloader release];
			[_downloadedData release];

			_totalDownloadLength = 0.0f;
			[OsuFunctions doAlert:@"Beatmap not found..." withCancel:NO delegate:self];
		}

		return;
	}
    [_downloadedData setLength:0];
	_totalDownloadLength = [response expectedContentLength];

	_descTexture = [[Texture2D alloc] initWithString:[NSString stringWithFormat:@"Downloading %@ (%0.3f MB)...", ((Beatmap *)[_curBeatmaps objectAtIndex:_selectedIndex]).title, (float)_totalDownloadLength / 1048576.0f] dimensions:CGSizeMake(720, 64) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24];

	NSLog(@"Total download length: %d", _totalDownloadLength);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [_downloadedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self goToState:kSongSelectionStates_SortedByTitle];

    // release the connection, and the data object
    [connection release];
    // receivedData is declared as a method instance elsewhere
    [_downloadedData release];
	[_descTexture release];
	_totalDownloadLength = 0.0f;
	
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (_curState == kSongSelectionStates_Downloading && buttonIndex == 1 && _totalDownloadLength != _downloadedData.length)
	{
		[_downloader cancel];

		_curState = _lastState;
		_totalDownloadLength = 0.0f;
		[_downloadedData release];
		[_downloader release];
		[_descTexture release];
	}
	else if ((_curState == kSongSelectionStates_SortedByTitle || _curState == kSongSelectionStates_SortedByArtist) && buttonIndex == 1)
	{
		[_manager removeBeatmap:[_curBeatmaps objectAtIndex:_selectedIndex]];
		[[NSFileManager defaultManager] removeItemAtPath:((Beatmap*)[_curBeatmaps objectAtIndex:_selectedIndex]).directory error:NULL];
		[self goToState:_curState];
	}
}

int do_extract(unzFile uf, int opt_extract_without_path, int opt_overwrite, const char* password);

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"Download succeeded");

	Beatmap *tmpBeatmap = [_curBeatmaps objectAtIndex:_selectedIndex];
	NSString *directory = [NSString stringWithFormat:@"%@/osu/beatmaps/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], [[[[tmpBeatmap.directory componentsSeparatedByString:@"|"] objectAtIndex:0] lastPathComponent] stringByDeletingPathExtension]];

	[[NSFileManager defaultManager] createDirectoryAtPath:directory attributes:NULL];
	[_downloadedData writeToFile:[NSString stringWithFormat:@"%@/%@", directory, [[[tmpBeatmap.directory componentsSeparatedByString:@"|"] objectAtIndex:0] lastPathComponent]] atomically:NO];

	chdir([directory UTF8String]);
	unzFile uf = unzOpen([[NSString stringWithFormat:@"%@/%@", directory, [[[tmpBeatmap.directory componentsSeparatedByString:@"|"] objectAtIndex:0] lastPathComponent]] UTF8String]);
	int err = do_extract(uf, 1, 1, NULL);
	unzClose(uf);

	if (err == UNZ_OK)
	{
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", directory, [tmpBeatmap.directory lastPathComponent]] error:NULL];
		tmpBeatmap = [[Beatmap alloc] initWithDirectory:[[tmpBeatmap.directory lastPathComponent] stringByDeletingPathExtension]];
		if (tmpBeatmap)
			[_manager addBeatmap:tmpBeatmap];
		else
			[OsuFunctions doAlert:@"Error recognizing this Beatmap. Please contact nuudles with the name of this Beatmap so he can investigate." withCancel:NO delegate:self];

		[self goToState:kSongSelectionStates_SortedByTitle];
		// release the connection, and the data object
	}
	else
	{
		_curState = _lastState;
		[[NSFileManager defaultManager] removeItemAtPath:directory error:NULL];
		NSLog(@"Downloaded file does not appear to be a zip file...");
		[OsuFunctions doAlert:@"Downloaded file does not appear to be a zip file..." withCancel:NO delegate:self];
	}

	_totalDownloadLength = 0.0f;
	[_downloadedData release];
	[connection release];
}

- (id)initWithTextures:(Texture2D **)textures manager:(BeatmapManager *)manager sounds:(UInt32*)sounds
{
	if (self = [super init])
	{
		_textures = textures;
		_manager = manager;
		_sounds = sounds;
		_txtTextures = [[NSMutableArray alloc] init];

		[self goToState:kSongSelectionStates_SortedByTitle];

		_selectedIndex = -1;

		_curLocation.x = SCREEN_SIZE_X+100.0f;
		_curLocation.y = SCREEN_SIZE_Y+100.0f;

		_curPosition = 0.0f;
		_curVelocity = 0.0f;

		_searchField = [[UITextField alloc] initWithFrame:CGRectMake(185, 120, 200, 30)];
		[_searchField setDelegate:self];
		[_searchField setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
		[_searchField setTextColor:[UIColor whiteColor]];
		[_searchField setFont:[UIFont fontWithName:@"Arial" size:20]];
		[_searchField setPlaceholder:@"Search..."];
		[_searchField setBorderStyle:UITextBorderStyleLine];
		[_searchField setReturnKeyType:UIReturnKeySearch];
		[_searchField setTransform:CGAffineTransformMakeRotation(PI/2.0f)];
		_searchField.clearButtonMode = UITextFieldViewModeWhileEditing;

		return self;
	}
	return NULL;
}

- (void)drawSongSelection
{
	int i;
	Texture2D *tmpTexture;

	[_textures[kTexture_SongSelectBackground] drawInRectUpsideDown:CGRectMake(0, -30, 720, -1)];

	if (_curState == kSongSelectionStates_Downloading)
	{
		float curAngle = 0.0f;

		if (_totalDownloadLength)
			curAngle = (6 * PI * ((float)_downloadedData.length / _totalDownloadLength));

		glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
		glPushMatrix();
		glTranslatef(360.0f, 240.0f, 0.0f);
		glScalef(500.0f / _textures[kTexture_SpinnerBackground].contentSize.width, -500.0f / _textures[kTexture_SpinnerBackground].contentSize.width, 1.0f);
		[_textures[kTexture_SpinnerBackground] drawAtPoint:CGPointMake(0,0)];
		if (_totalDownloadLength)
			[_textures[kTexture_SpinnerMetre] drawInRect:CGRectMake(-_textures[kTexture_SpinnerMetre].contentSize.width / 2.0f, -_textures[kTexture_SpinnerMetre].contentSize.height / 2.0f, _textures[kTexture_SpinnerMetre].contentSize.width, _textures[kTexture_SpinnerMetre].contentSize.height * ((float)_downloadedData.length / _totalDownloadLength)) scaleX:1.0f scaleY:((float)_downloadedData.length / _totalDownloadLength)];
		glRotatef(curAngle * (180.0f / PI), 0.0f, 0.0f, -1.0f);
		[_textures[kTexture_SpinnerCircle] drawAtPoint:CGPointMake(0,0)];
		glPopMatrix();
		if (_totalDownloadLength)
			[_descTexture drawInRectUpsideDown:CGRectMake(0.0f, 35.0f, 720.0f, 64.0f)];
		[_textures[kTexture_Hit0] drawInRectUpsideDown:CGRectMake(640.0f, 400.0f, 80.0f, 80.0f)];

		return;
	}

	for (i = 0; i < 4; i++)
	{
		if (_curState == i)
			glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
		else
			glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
		[_textures[kTexture_SongSelectTab] drawInRectUpsideDown:CGRectMake(tabPositions[i], 0, 141, 29)];
		if (_curState == i)
			glColor4f(0.0f, 0.0f, 0.0f, 1.0f);
		else
			glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
		[_textures[kTexture_TextSearch + i] drawInRectUpsideDown:CGRectMake(tabPositions[i], 2, 141, 29)];
	}

	if (!_touchDown)
	{
		_curPosition -= _curVelocity;

		if (_curPosition > 0)
			_curPosition = 0;
		if (_curPosition < (-60.0f * ([OsuFunctions max:[_txtTextures count] y:6] - 6)))
			_curPosition = (-60.0f * ([OsuFunctions max:[_txtTextures count] y:6]- 6));		
		
		_curVelocity *= FRICTION_COEFFICIENT;
	}

	glScissor(32, 40, 268, 400);
	glEnable(GL_SCISSOR_TEST);

	glTranslatef(0.0f, _curPosition, 0.0f);

	for (i = (_curPosition + 99) / -60.0f + 1; i < (_curPosition + 99) / -60.0f + 9 && i < [_txtTextures count]; i++)
	{
		BOOL textIsBlack = NO;
		if (_curState == kSongSelectionStates_SortedByTitle || _curState == kSongSelectionStates_SortedByArtist)
		{
			Beatmap *tmpBeatmap = [_curBeatmaps objectAtIndex:i];
			if ([tmpBeatmap.osuFileArray count] == 1) // crimson 220,20,60
				glColor4f(220.0f/255.0f, 20.0f/255.0f, 60.0f/255.0f, 0.7f);
			else if (tmpBeatmap.playcount == 0) // pink 255,192,203
				glColor4f(255.0f/255.0f, 192.0f/255.0f, 203.0f/255.0f, 0.7f);
			else // orange - 210,105,30
				glColor4f(210.0f/255.0f, 105.0f/255.0f, 30.0f/255.0f, 0.7f);
		}
		else if (_curState == kSongSelectionStates_DifficultySelect)
		{
			if (i == 0)
			{
				textIsBlack = YES;
				glColor4f(1.0f, 1.0f, 1.0f, 0.8f);
			}
			else if ([_selectedBeatmap getOsuFile:i-1].general_Playcount == 0) // pink
				glColor4f(255.0f/255.0f, 192.0f/255.0f, 203.0f/255.0f, 0.7f);
			else // orange - 210,105,30
				glColor4f(210.0f/255.0f, 105.0f/255.0f, 30.0f/255.0f, 0.7f);
		}
		else if (_curState == kSongSelectionStates_Scoreboard && i == 1)
		{
			if (_selectedOsufile.general_Playcount == 0) // pink
				glColor4f(255.0f/255.0f, 192.0f/255.0f, 203.0f/255.0f, 0.7f);
			else // orange - 210,105,30
				glColor4f(210.0f/255.0f, 105.0f/255.0f, 30.0f/255.0f, 0.7f);
		}
		else if (_curState == kSongSelectionStates_Scoreboard && i > 1)
		{
			glColor4f(0.0f, 0.0f, 1.0f, 0.2f);
		}
		else
		{
			textIsBlack = YES;
			glColor4f(1.0f, 1.0f, 1.0f, 0.7f);
		}

		[_textures[kTexture_MenuButtonBackground] drawInRectUpsideDown:CGRectMake(BUTTONS_LEFT, BUTTONS_TOP + 60 * i, BUTTONS_WIDTH, BUTTONS_HEIGHT)];
		if (textIsBlack)
			glColor4f(0.0f, 0.0f, 0.0f, 1.0f);
		else
			glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
		tmpTexture = [_txtTextures objectAtIndex:i];
		[tmpTexture drawInRectUpsideDown:CGRectMake(BUTTONS_LEFT + 23, BUTTONS_TOP + 22 + 60 * i, 500, -1)];
		glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

		int x = 0;
		if (_curState == kSongSelectionStates_SortedByTitle || _curState == kSongSelectionStates_SortedByArtist)
			[_textures[kTexture_Hit0] drawInRectUpsideDown:CGRectMake(580, BUTTONS_TOP + 60 * i + 20.0f, 60, 60)];
		else if (_curState == kSongSelectionStates_Scoreboard && i > 1)
			[_textures[kTexture_RankingSSSmall + [[[[[_selectedOsufile getHighscores] objectAtIndex:(i - 2)] componentsSeparatedByString:@","] objectAtIndex:1] intValue]] drawInRectUpsideDown:CGRectMake(BUTTONS_LEFT + 23, BUTTONS_TOP + 60 * i + 20.0f, -1, 60)];
		else if (_curState == kSongSelectionStates_DifficultySelect && i > 0 && [[_selectedBeatmap getOsuFile:i-1] getHighscores] && [[[_selectedBeatmap getOsuFile:i-1] getHighscores] count] > 0)
		{
			[_textures[kTexture_RankingSSSmall + [[[[[[_selectedBeatmap getOsuFile:i-1] getHighscores] objectAtIndex:0] componentsSeparatedByString:@","] objectAtIndex:1] intValue]] drawInRectUpsideDown:CGRectMake(BUTTONS_LEFT + 23, BUTTONS_TOP + 60 * i + 50.0f, -1, 40)];
			x = 30;
		}

		if (i && _curState == kSongSelectionStates_DifficultySelect || (_curState == kSongSelectionStates_Scoreboard && i == 1))
		{
			int j;
			for (j = 0; j < floor((_curState == kSongSelectionStates_DifficultySelect ? [_selectedBeatmap getOsuFile:i-1] : _selectedOsufile).difficulty_EyupStars); j++)
				[_textures[kTexture_Star] drawInRectUpsideDown:CGRectMake(BUTTONS_LEFT + 23 + j * 32 + x, BUTTONS_TOP + 60 * i + 55.0f, 32, 32)];
			[_textures[kTexture_Star] drawInRectUpsideDown:CGRectMake(BUTTONS_LEFT + 23 + j * 32 + x, BUTTONS_TOP + 60 * i + 55.0f, 32*((_curState == kSongSelectionStates_DifficultySelect ? [_selectedBeatmap getOsuFile:i-1] : _selectedOsufile).difficulty_EyupStars - j), 32) scaleX:((_curState == kSongSelectionStates_DifficultySelect ? [_selectedBeatmap getOsuFile:i-1] : _selectedOsufile).difficulty_EyupStars - j) scaleY:1.0f];
		}
	}
	glTranslatef(0.0f, -_curPosition, 0.0f);
	glDisable(GL_SCISSOR_TEST);

	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	[_textures[kTexture_MenuBack] drawInRectUpsideDown:CGRectMake(0, 380, -1, 100)];
	if (_curState == kSongSelectionStates_Scoreboard)
		[_textures[kTexture_MenuOsu] drawInRectUpsideDown:CGRectMake(580, 370, 170, 170)];
}

- (BOOL) doTouch:(int)type location:(CGPoint)location
{
	BOOL stateChange = NO;
	if (type == 0)
	{
		[_searchField removeFromSuperview];
		if (location.x > 60 && location.x < 660 && location.y > 30 && location.y < 435 && _curPosition - location.y < -45 && _curPosition - location.y > ([_txtTextures count] * -60.0f - 75.0f) && _curState != kSongSelectionStates_Downloading)
		{
			_touchDown = 1;
			_curLocation = location;
			_curVelocity = 0.0f;
		}
		else
		{
			for (int i = 0; i < 4; i++)
			{
				if (location.x > tabPositions[i] && location.x < tabPositions[i] + 141 && location.y > 0 && location.y < 29 && (_curState == kSongSelectionStates_SearchResults || _curState != i) && _curState != kSongSelectionStates_Downloading)
				{
					SoundEngine_StartEffect(_sounds[kSound_MenuClick]);
					[self goToState:i];
					stateChange = YES;
				}
			}
		}
	}
	else if (type == 1)
	{
		if (_touchDown)
		{
			_curPosition -= _curLocation.y - location.y;
			_curVelocity = _curLocation.y - location.y;

			if (_curPosition > 0)
				_curPosition = 0;
			if (_curPosition < (-60.0f * ([OsuFunctions max:[_txtTextures count] y:6] - 6)))
				_curPosition = (-60.0f * ([OsuFunctions max:[_txtTextures count] y:6]- 6));

			_curLocation = location;
			_touchDown = 2;
		}
	}
	else
	{
		if (_touchDown)
		{
			_curLocation.x = SCREEN_SIZE_X+100.0f;
			_curLocation.y = SCREEN_SIZE_Y+100.0f;

			if (_touchDown == 1)
			{
				if (location.x < 580.0f || (_curState != kSongSelectionStates_SortedByTitle && _curState != kSongSelectionStates_SortedByArtist))
				{
					[self makeSelection:[OsuFunctions min:([_txtTextures count] - 1) y:(-(_curPosition - location.y + 45.0f) / 60.0f)]];
					stateChange = YES;
				}
				else
				{
					_selectedIndex = [OsuFunctions min:([_txtTextures count] - 1) y:(-(_curPosition - location.y + 45.0f) / 60.0f)];
					[OsuFunctions doAlert:[NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?", ((Beatmap *)[_curBeatmaps objectAtIndex:_selectedIndex]).title] withCancel:YES delegate:self];
				}
			}

			_touchDown = 0;
		}
		else if (location.x > 0.0f && location.x < 148.6f && location.y > 380.0f && location.y < 480.0f && _curState != kSongSelectionStates_Downloading)
		{
			[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] doStateAction:kOsuStateActions_GoToMainMenu];
			stateChange = YES;
		}
		else if (location.x > 640.0f && location.y > 400.0f && _curState == kSongSelectionStates_Downloading && _totalDownloadLength != _downloadedData.length)
		{
			[OsuFunctions doAlert:@"Are you sure you want to stop downloading this song?" withCancel:YES delegate:self];
		}
		else if (location.x > 580.0 && location.y > 370.0f && _curState == kSongSelectionStates_Scoreboard)
		{
			SoundEngine_StartEffect(_sounds[kSound_MenuHit]);
			[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] startGame:_selectedOsufile];
		}
	}
	/*
	if (location.x >= BUTTONS_LEFT && location.y >= BUTTONS_TOP && location.x <= BUTTONS_LEFT + BUTTONS_WIDTH && type == 0)
	{
		for (int i = 4; i >= 0; i--)
		{
			if (_topIndex + i >= [_txtTextures count])
				continue;
			if (location.y <= BUTTONS_TOP + 70 * (i + 1) && location.y >= BUTTONS_TOP + 60 * i + 16)
			{
				SoundEngine_StartEffect(_sounds[kSound_MenuClick]);
				[self makeSelection:(i + _topIndex)];
				break;
			}
		}
	}
	*/
	return stateChange;
}

- (void)dealloc
{
	[_curBeatmaps release];
	[_txtTextures release];
	[_searchField release];
	if (_downloader)
		[_downloader release];
	if (_downloadedData)
		[_downloadedData release];

	[super dealloc];
}

@end
