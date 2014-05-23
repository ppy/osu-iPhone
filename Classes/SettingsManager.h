//
//  SettingsManager.h
//  Osu
//
//  Created by Christopher Luu on 1/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLManager.h"

#define kSettings_PlayerNameKey @"playername"
#define kSettings_SkinKey @"skin"
#define kSettings_NoFailKey @"nofail"

#define kSettings_NumberKeys 3

@interface SettingsManager : NSObject
{
	SQLManager *_sqlManager;

	NSMutableDictionary *_settings;

	// Settings
	BOOL noFailMode;
}

@property(readonly) BOOL noFailMode;

- (id)initWithSql:(SQLManager*)inSqlManager;
- (void)setValue:(NSString *)value forKey:(NSString *)key;
- (NSString *)getValue:(NSString *)key;
- (void)commitChanges;

@end
