//
//  OsuFunctions.m
//  Osu
//
//  Created by Christopher Luu on 8/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "OsuFunctions.h"
#import <CommonCrypto/CommonDigest.h>;

@implementation OsuFunctions

+ (void)doAlert:(NSString *)msg withCancel:(BOOL)withCancel delegate:(id)delegate
{
	UIAlertView *alert;
	alert = [[UIAlertView alloc] initWithTitle:@"Osu!" message:msg delegate:delegate cancelButtonTitle:(withCancel ? @"Cancel" : NULL) otherButtonTitles:@"OK", NULL];

	[alert show];
	[alert release];
}

+ (float) dist:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2
{
	return sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1));
}

+ (float) mapDifficultyRange:(float)difficulty min:(float)min mid:(float)mid max:(float)max
{
    if (difficulty > 5.0f)
		return mid + (max - mid)*(difficulty - 5.0f)/5.0f;
    if (difficulty < 5.0f)
		return mid - (mid - min)*(5.0f - difficulty)/5.0f;
    return mid;
}

+ (float) min:(float)x y:(float)y
{
	return (x < y ? x : y);	
}

+ (float) max:(float)x y:(float)y
{
	return (x > y ? x : y);
}

+ (NSString *) md5:(NSString *)str
{
	const char *cStr = [str UTF8String];
	unsigned char result[16];
	CC_MD5( cStr, strlen(cStr), result );
	return [NSString stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];
}

@end
