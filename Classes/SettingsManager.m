//
//  SettingsManager.m
//  Osu
//
//  Created by Christopher Luu on 1/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SettingsManager.h"

@implementation SettingsManager

@synthesize noFailMode;

void insertIntoSql(sqlite3 *db, NSString *key, NSString *value)
{
	sqlite3_stmt *compiledStatement;

	if(sqlite3_prepare_v2(db, "INSERT INTO settings (field, value) VALUES (?, ?)", -1, &compiledStatement, NULL) == SQLITE_OK)
	{
		sqlite3_bind_text(compiledStatement, 1, [key UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(compiledStatement, 2, [value UTF8String], -1, SQLITE_TRANSIENT);
		if (sqlite3_step(compiledStatement) != SQLITE_DONE)
			NSLog(@"Error while inserting data. '%s'", sqlite3_errmsg(db));
		sqlite3_finalize(compiledStatement);
	}
}

- (id)initWithSql:(SQLManager*)inSqlManager
{
	if (self = [super init])
	{
		_sqlManager = inSqlManager;
		_settings = [[NSMutableDictionary alloc] initWithCapacity:kSettings_NumberKeys];

		sqlite3 *db;
		sqlite3_stmt *compiledStatement;

		db = [_sqlManager openDB];
		if(sqlite3_prepare_v2(db, "SELECT * FROM settings", -1, &compiledStatement, NULL) == SQLITE_OK)
		{
			while (sqlite3_step(compiledStatement) == SQLITE_ROW)
			{
				[_settings setObject:[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 2)] forKey:[NSString stringWithUTF8String:(char*)sqlite3_column_text(compiledStatement, 1)]];
			}
			sqlite3_finalize(compiledStatement);
		}

		if (![_settings objectForKey:kSettings_PlayerNameKey])
		{
			insertIntoSql(db, kSettings_PlayerNameKey, @"Player");
			[_settings setObject:@"Player" forKey:kSettings_PlayerNameKey];
		}
		if (![_settings objectForKey:kSettings_SkinKey])
		{
			insertIntoSql(db, kSettings_SkinKey, @"default");
			[_settings setObject:@"default" forKey:kSettings_SkinKey];
		}
		if (![_settings objectForKey:kSettings_NoFailKey])
		{
			insertIntoSql(db, kSettings_NoFailKey, @"N");
			[_settings setObject:@"N" forKey:kSettings_NoFailKey];
		}

		noFailMode = [[_settings objectForKey:kSettings_NoFailKey] boolValue];
		[_sqlManager closeDB];

		return self;
	}
	return NULL;
}

- (void)commitChanges
{
	sqlite3 *db;
	sqlite3_stmt *compiledStatement;

	db = [_sqlManager openDB];
	for (NSString *key in _settings)
	{
		if(sqlite3_prepare_v2(db, "UPDATE settings SET value = ? WHERE field = ?", -1, &compiledStatement, NULL) == SQLITE_OK)
		{
			sqlite3_bind_text(compiledStatement, 1, [[_settings objectForKey:key] UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(compiledStatement, 2, [key UTF8String], -1, SQLITE_TRANSIENT);
			if (sqlite3_step(compiledStatement) != SQLITE_DONE)
				NSLog(@"Error while updating data. '%s'", sqlite3_errmsg(db));
			sqlite3_reset(compiledStatement);
		}
	}
	sqlite3_finalize(compiledStatement);

	[_sqlManager closeDB];
}

- (void)setValue:(NSString *)value forKey:(NSString *)key
{
	if ([key compare:kSettings_NoFailKey] == 0)
		noFailMode = [value boolValue];
	[_settings setObject:value forKey:key];
}

- (NSString *)getValue:(NSString *)key
{
	return [_settings objectForKey:key];
}

- (void)dealloc
{
	[_settings release];
	[super dealloc];
}

@end
