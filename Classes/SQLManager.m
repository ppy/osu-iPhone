//
//  SQLManager.m
//  Osu
//
//  Created by Christopher Luu on 12/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SQLManager.h"

@implementation SQLManager

- (id)initWithDB:(NSString *)filename
{
	if (self = [super init])
	{
		_databaseFilename = [[NSString stringWithFormat:@"%@/osu/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], filename] retain];

		if (![[NSFileManager defaultManager] fileExistsAtPath:_databaseFilename])
		{
			[[NSFileManager defaultManager] copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename] toPath:_databaseFilename error:NULL];
		}
		return self;
	}

	return NULL;
}

- (sqlite3 *)openDB
{
	if (sqlite3_open([_databaseFilename UTF8String], &database) == SQLITE_OK)
		return database;

	return NULL;
}

- (void)closeDB
{
	sqlite3_close(database);
}

- (void)dealloc
{
	[_databaseFilename release];
	[super dealloc];
}

@end
