//
//  SQLManager.h
//  Osu
//
//  Created by Christopher Luu on 12/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SQLManager : NSObject
{
	NSString *_databaseFilename;
	sqlite3 *database;
}

- (id)initWithDB:(NSString *)filename;
- (sqlite3 *)openDB;
- (void)closeDB;

@end
