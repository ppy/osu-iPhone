//
//  OsuFiletype.m
//  Osu
//
//  Created by Christopher Luu on 8/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "OsuAppDelegate.h"
#import "OsuFiletype.h"
#import "OsuFunctions.h"

typedef enum
{
	kFieldType_String,
	kFieldType_Int,
	kFieldType_Float,
} eParserFieldType;

typedef struct _parserFields
{
	NSString *name;
	eParserFieldType type;
	void *value;
} tParserFields;

#define SLIDER_DETAIL_LEVEL 50
#define SLIDER_CONSTANT_JUMPS (100.0f/SLIDER_TICKS_PER_BEAT)

@implementation OsuFiletype

@synthesize filename;
@synthesize osuFileFormat;

@synthesize general_AudioFilename;
@synthesize general_AudioHash;
@synthesize general_AudioLeadIn;
@synthesize general_PreviewTime;
@synthesize general_Countdown;
@synthesize general_SampleSet;
@synthesize general_StackLeniency;
@synthesize general_Mode;
@synthesize general_Playcount;
@synthesize general_TotalLength;

@synthesize pColours;
@synthesize numColours;

@synthesize metaData_Title;
@synthesize metaData_Artist;
@synthesize metaData_Creator;
@synthesize metaData_Version;
@synthesize metaData_Source;
@synthesize metaData_Tags;

@synthesize difficulty_HPDrainRate;
@synthesize difficulty_CircleSize;
@synthesize difficulty_OverallDifficulty;
@synthesize difficulty_SliderMultiplier;
@synthesize difficulty_SliderTickrate;
@synthesize difficulty_PreEmpt;
@synthesize difficulty_HitCircleSize;
@synthesize difficulty_EyupStars;

@synthesize hitObjects;
@synthesize events;
@synthesize timingPoints;

@synthesize HpMultiplierNormal;
@synthesize HpMultiplierComboEnd;
@synthesize HpDropRate;

tParserFields fields_General[] =
{
	{.name = @"AudioFilename", .type = kFieldType_String},
	{.name = @"AudioHash", .type = kFieldType_String},
	{.name = @"AudioLeadIn", .type = kFieldType_Int},
	{.name = @"PreviewTime", .type = kFieldType_Int},
	{.name = @"Countdown", .type = kFieldType_Int},
	{.name = @"SampleSet", .type = kFieldType_String},
	{.name = @"StackLeniency", .type = kFieldType_Float},
	{.name = @"Mode", .type = kFieldType_Int},
	{.name = NULL},
};

tParserFields fields_MetaData[] =
{
	{.name = @"Title", .type = kFieldType_String},
	{.name = @"Artist", .type = kFieldType_String},
	{.name = @"Creator", .type = kFieldType_String},
	{.name = @"Version", .type = kFieldType_String},
	{.name = @"Source", .type = kFieldType_String},
	{.name = @"Tags", .type = kFieldType_String},
	{.name = NULL},
};

tParserFields fields_Difficulty[] =
{
	{.name = @"HPDrainRate", .type = kFieldType_Int},
	{.name = @"CircleSize", .type = kFieldType_Int},
	{.name = @"OverallDifficulty", .type = kFieldType_Int},
	{.name = @"SliderMultiplier", .type = kFieldType_Float},
	{.name = @"SliderTickrate", .type = kFieldType_Float},
	{.name = NULL},
};

void parseIt(tParserFields *fields, NSScanner **pScanner)
{
	if (fields == NULL || pScanner == NULL)
		return;

	NSScanner *scanner = *pScanner;
	int curLocation, i;
	NSString *tmpString, *searchName;

	NSCharacterSet *charSet = [scanner charactersToBeSkipped];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@" :"]];
	while (1)
	{
		curLocation = [scanner scanLocation];

		if ([scanner scanUpToString:@":" intoString:&searchName] == NO)
			break;
		if ([searchName rangeOfString:@"["].location != NSNotFound)
		{
			[scanner setScanLocation:curLocation];
			break;
		}
		searchName = [searchName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		//NSLog(@"Searching for the '%@' field type\n", searchName);
		for (i = 0; fields[i].name != NULL; i++)
		{
			if ([searchName caseInsensitiveCompare:fields[i].name] == 0)
			{
				switch (fields[i].type)
				{
					case kFieldType_String:
						[scanner scanUpToString:@"\n" intoString:&tmpString];
						*((NSString **)fields[i].value) = [[tmpString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \r\n"]] retain];
						//NSLog(@"Scanned in String: '%@'\n", *(NSString *)fields[i].value);
						break;
					case kFieldType_Int:
						[scanner scanInt:(int *)fields[i].value];
						//NSLog(@"Scanned in Int: %d\n", *((int *)fields[i].value));
						break;
					case kFieldType_Float:
						[scanner scanFloat:(float *)fields[i].value];
						//NSLog(@"Scanned in Float: %f\n", *((float *)fields[i].value));
						break;
				}
				break;
			}
		}
		if (fields[i].name == NULL)
		{
			//NSLog(@"'%@' field type not found. Ignoring value...\n", searchName);
			[scanner scanUpToString:@"\n" intoString:NULL];
		}
		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
	}
	[scanner setCharactersToBeSkipped:charSet];
}

NSArray *parseEvents(NSScanner **pScanner)
{
	int tmp;
	OsuEvent *tmpEvent;
	NSString *tmpString;
	NSScanner *scanner = *pScanner;
	NSMutableArray *out = [[NSMutableArray alloc] init];

	while (1)
	{
		// Scan in events
		if ([scanner scanInt:&tmp] == YES)
		{
			//NSLog(@"Scanning in a main event...\n");
			tmpEvent = [[OsuEvent alloc] init];
			tmpEvent.type = tmp;
			//NSLog(@"Scanning in type %d\n", tmpEvent.type);
			switch (tmpEvent.type)
			{
				case kOsuEventType_Background:
					[scanner scanInt:&tmp];
					tmpEvent.layer = tmp;
					[scanner scanUpToString:@"\n" intoString:&tmpString];
					tmpEvent.filepath = [[tmpString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n\""]] retain];
					[out addObject:tmpEvent];
					break;
				case kOsuEventType_BreakPeriod:
					[scanner scanInt:&tmp];
					tmpEvent.x = tmp;
					[scanner scanInt:&tmp];
					tmpEvent.y = tmp;
					[out addObject:tmpEvent];
					break;
				default:
					// Error... unknown type
					[scanner scanUpToString:@"\n" intoString:NULL];
					break;
			}
			[tmpEvent release];
		}
		else if ([scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"FMSVRCLP"] intoString:&tmpString] == YES)
		{
			[scanner scanUpToString:@"\n" intoString:NULL];
			continue;
		}
		else if ([scanner scanString:@"//" intoString:NULL] == YES)
		{
			// comment
			//NSLog(@"Found a comment... skipping\n");
			[scanner scanUpToString:@"\n" intoString:NULL];
			continue;
		}
		else // done scanning events...
			break;
	}
	if ([out count] == 0)
	{
		[out release];
		out = NULL;
	}

	return out;
}

// returns NO if processing failed
- (BOOL)processFile
{
	NSString *tmpSampleSet = NULL;

	fields_General[0].value = &general_AudioFilename;
	fields_General[1].value = &general_AudioHash;
	fields_General[2].value = &general_AudioLeadIn;
	fields_General[3].value = &general_PreviewTime;
	fields_General[4].value = &general_Countdown;
	fields_General[5].value = &tmpSampleSet;
	fields_General[6].value = &general_StackLeniency;
	fields_General[7].value = &general_Mode;
	
	fields_MetaData[0].value = &metaData_Title;
	fields_MetaData[1].value = &metaData_Artist;
	fields_MetaData[2].value = &metaData_Creator;
	fields_MetaData[3].value = &metaData_Version;
	fields_MetaData[4].value = &metaData_Source;
	fields_MetaData[5].value = &metaData_Tags;
	
	fields_Difficulty[0].value = &difficulty_HPDrainRate;
	fields_Difficulty[1].value = &difficulty_CircleSize;
	fields_Difficulty[2].value = &difficulty_OverallDifficulty;
	fields_Difficulty[3].value = &difficulty_SliderMultiplier;
	fields_Difficulty[4].value = &difficulty_SliderTickrate;
	
	pColours = colours;
	general_Countdown = kOsuCountdown_Normal; // defaults to normal

	NSString *fileContents = [NSString stringWithContentsOfFile:filename];
	general_Md5Sum = [[OsuFunctions md5:fileContents] retain];
	
	if (fileContents)
	{
		NSScanner *scanner = [NSScanner scannerWithString:fileContents];
		NSString *tmpString = NULL;
		
		[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\r\n ,:|"]];
		
		if ([scanner scanString:@"osu file format v" intoString:NULL] == NO)
			return NO;
		if ([scanner scanInt:&osuFileFormat] == NO)
			return NO;
		
		//NSLog(@"Scanned osu file format v%d\n", osuFileFormat);
		
		while (1)
		{
			[scanner scanUpToString:@"[" intoString:NULL];
			if ([scanner scanString:@"[" intoString:NULL] == NO)
				break;
			if ([scanner scanUpToString:@"]" intoString:&tmpString] == NO)
				break;
			[scanner scanString:@"]" intoString:NULL];
			
			//NSLog(@"Now scanning [%@] Section\n", tmpString);
			
			if ([tmpString caseInsensitiveCompare:@"General"] == 0)
				parseIt(fields_General, &scanner);
			else if ([tmpString caseInsensitiveCompare:@"MetaData"] == 0)
				parseIt(fields_MetaData, &scanner);
			else if ([tmpString caseInsensitiveCompare:@"Difficulty"] == 0)
				parseIt(fields_Difficulty, &scanner);
			else if ([tmpString caseInsensitiveCompare:@"Events"] == 0)
				events = parseEvents(&scanner);
			else if ([tmpString caseInsensitiveCompare:@"TimingPoints"] == 0)
			{
				TimingPoint *tmpTimingPoint;
				int tmp;
				double tmpDouble;
				timingPoints = [[NSMutableArray alloc] init];
				NSArray *tmpArray;
				double lastTimingPoint = 0.0;

				while (1)
				{
					[scanner scanUpToString:@"\n" intoString:&tmpString];
					tmpArray = [tmpString componentsSeparatedByString:@","];
					if ([tmpArray count] < 2)
						break;

					if (osuFileFormat <= 3)
					{
						tmpDouble = [[tmpArray objectAtIndex:0] doubleValue];
						tmp = (int)tmpDouble;
					}
					else
					{
						tmp = [[tmpArray objectAtIndex:0] intValue];
					}
					tmpTimingPoint = [[TimingPoint alloc] init];
					tmpTimingPoint.offsetMs = tmp;
					//[scanner scanDouble:&tmpDouble];
					tmpTimingPoint.beatLength = [[tmpArray objectAtIndex:1] doubleValue];//tmpDouble;

					BOOL bTimingChange = YES;

					if ([tmpArray count] >= 4)
						tmpTimingPoint.sampleSetId = [[tmpArray objectAtIndex:3] intValue];//tmp;
					if ([tmpArray count] >= 5)
						tmpTimingPoint.useCustomSamples = [[tmpArray objectAtIndex:4] intValue];//tmp;
					if ([tmpArray count] >= 6)
						tmpTimingPoint.sampleVolume = [[tmpArray objectAtIndex:5] intValue];//tmp;
					if ([tmpArray count] >= 7)
						bTimingChange = [[tmpArray objectAtIndex:6] intValue] != 0;
					if ([tmpArray count] >= 8)
						tmpTimingPoint.isKiaiTime = [[tmpArray objectAtIndex:7] boolValue];

					if (tmpTimingPoint.beatLength > 0 && bTimingChange)
						lastTimingPoint = tmpTimingPoint.beatLength;
					else if (tmpTimingPoint.beatLength < 0)
						tmpTimingPoint.beatLength = lastTimingPoint * (tmpTimingPoint.beatLength / -100.0f);
					else
						tmpTimingPoint.beatLength = lastTimingPoint;

					//NSLog(@"Scanned in TimingPoint: %d,%f,%d,%d,%d\n", tmpTimingPoint.offsetMs, tmpTimingPoint.beatLength, tmpTimingPoint.sampleSetId, tmpTimingPoint.useCustomSamples, tmpTimingPoint.sampleVolume);
					[timingPoints addObject:tmpTimingPoint];
					[tmpTimingPoint release];
				}
			}
			else if ([tmpString caseInsensitiveCompare:@"Colours"] == 0)
			{
				int tmp;
				
				numColours = 0;
				
				for (int i = 0; i < 5; i++)
				{
					if ([scanner scanString:@"Combo" intoString:NULL] == NO)
						break;
					[scanner scanInt:&tmp];
					if (tmp != i + 1)
						break; // Some weirdness occurred... Combos not in order
					[scanner scanInt:&(colours[i].r)];
					[scanner scanInt:&(colours[i].g)];
					[scanner scanInt:&(colours[i].b)];
					//NSLog(@"Scanned in color: %d,%d,%d\n", colours[i].r, colours[i].g, colours[i].b);
					numColours++;
				}
			}
		}
		
		if (numColours == 0)
		{
			// set default colors
			numColours = 4;
			colours[0].r = 255; colours[0].g = 150; colours[0].b = 0;
			colours[1].r = 5; colours[1].g = 240; colours[1].b = 5;
			colours[2].r = 5; colours[2].g = 5; colours[2].b = 240;
			colours[3].r = 240; colours[3].g = 5; colours[3].b = 5;
		}
		if (general_StackLeniency == 0)
			general_StackLeniency = 1.0f;
		
		if (tmpSampleSet)
		{
			if ([tmpSampleSet caseInsensitiveCompare:@"Normal"] == 0)
				general_SampleSet = 0;
			else
				general_SampleSet = 1;
			[tmpSampleSet release];
		}
		else
			general_SampleSet = 0;
	}
	return YES;
}

- (id)initWithFilename:(NSString*)inFilename
{
	if (self = [super init])
	{
		filename = [inFilename retain];
		if ([self processFile])
			return self;
		[self release];
	}
	return NULL;
}

- (id)initWithTitle:(NSString*)inTitle artist:(NSString*)inArtist creator:(NSString*)inCreator filename:(NSString*)inFilename difficultyText:(NSString*)inDifficultyText difficultyEyupStars:(float)inDifficultyEyupStars hpDropRate:(float)inHpDropRate hpMultiplierNormal:(float)inHpMultiplierNormal hpMultiplierComboEnd:(float)inHpMultiplierComboEnd playcount:(int)inPlaycount highscores:(NSString*)inHighscores
{
	if (self = [super init])
	{
		metaData_Title = [inTitle retain];
		metaData_Artist = [inArtist retain];
		metaData_Creator = [inCreator retain];
		filename = [inFilename retain];
		metaData_Version = [inDifficultyText retain];
		difficulty_EyupStars = inDifficultyEyupStars;
		HpDropRate = inHpDropRate;
		HpMultiplierNormal = inHpMultiplierNormal;
		HpMultiplierComboEnd = inHpMultiplierComboEnd;
		general_Playcount = inPlaycount;
		general_Md5Sum = [[OsuFunctions md5:[NSString stringWithContentsOfFile:filename]] retain];
		highScores = [[NSMutableArray alloc] init];
		if (inHighscores && [inHighscores length] > 0)
			[highScores addObjectsFromArray:[inHighscores componentsSeparatedByString:@"\\"]];
		return self;
	}
	return NULL;
}

// Whether the fields of the osu files match that are supposed to
- (BOOL)matchGenericData:(OsuFiletype*)compareTo
{
	//NSLog(@"%@ %@, %d %d, %@ %@, %@ %@", general_AudioFilename, compareTo.general_AudioFilename, general_PreviewTime, compareTo.general_PreviewTime, metaData_Title, compareTo.metaData_Title, metaData_Artist, compareTo.metaData_Artist);
	return ([general_AudioFilename isEqual:compareTo.general_AudioFilename]) && 
		//(general_PreviewTime == compareTo.general_PreviewTime) &&
		([metaData_Title isEqual:compareTo.metaData_Title]) &&
		([metaData_Artist isEqual:compareTo.metaData_Artist]) &&
		([metaData_Creator isEqual:compareTo.metaData_Creator]);// &&
		//((metaData_Source == compareTo.metaData_Source) || ([metaData_Source isEqual:compareTo.metaData_Source])) &&
		//((metaData_Tags == compareTo.metaData_Tags) || ([metaData_Tags isEqual:compareTo.metaData_Tags]));
}

GLfloat *calcConstant(NSArray *tmpArray, int pixelLength, float sliderMultiplier, int *pCount)
{
	// constant speed points
	float curLength = 0.0f, curDist = 0.0f, curPos = 0.0f;
	NSMutableArray *retVal = [[NSMutableArray alloc] init];
	HitObject *cur, *next, *tmpHitObject;
	GLfloat *pFinal;

	int i = 0;
	cur = [tmpArray objectAtIndex:i];
	next = [tmpArray objectAtIndex:i+1];

	tmpHitObject = [[HitObject alloc] init];
	tmpHitObject.x = cur.x;
	tmpHitObject.y = cur.y;
	[retVal addObject:tmpHitObject];
	[tmpHitObject release];

	curDist = [OsuFunctions dist:cur.x y1:cur.y x2:next.x y2:next.y];
	curPos = sliderMultiplier * SLIDER_CONSTANT_JUMPS;
	while (curLength < pixelLength)
	{
		while (curDist < curPos)
		{
			curPos -= curDist;
			cur = next;
			i++;
			if (i < [tmpArray count] - 1)
				next = [tmpArray objectAtIndex:(i+1)];
			else
			{
				//NSLog(@"It's not long enough! That's what she said!");
				
				float totalDist = 0.0f;
				HitObject *lastpoint = [tmpArray objectAtIndex:0];
				for (HitObject *chrisTemp in tmpArray)
				{
					totalDist += [OsuFunctions dist:lastpoint.x y1:lastpoint.y x2:chrisTemp.x y2:chrisTemp.y];
					lastpoint = chrisTemp;
				}
				//NSLog(@"Total Distance: %f, pixelLength: %d", totalDist, pixelLength);
				break;
			}
			curDist = [OsuFunctions dist:cur.x y1:cur.y x2:next.x y2:next.y];
		}
		tmpHitObject = [[HitObject alloc] init];
		tmpHitObject.x = cur.x + (next.x - cur.x) * (curPos / curDist);
		tmpHitObject.y = cur.y + (next.y - cur.y) * (curPos / curDist);
		[retVal addObject:tmpHitObject];
		[tmpHitObject release];
		cur.x = tmpHitObject.x;
		cur.y = tmpHitObject.y;
		curLength += sliderMultiplier * SLIDER_CONSTANT_JUMPS;
		curDist -= curPos;
		curPos = sliderMultiplier * SLIDER_CONSTANT_JUMPS;
	}

	//NSLog(@"Returning constant speed points with count: %d\n", [retVal count]);

	pFinal = malloc(sizeof(GLfloat) * [retVal count] * 3);
	i = 0;
	for (tmpHitObject in retVal)
	{
		pFinal[i*3] = tmpHitObject.x;
		pFinal[i*3+1] = tmpHitObject.y;
		pFinal[i*3+2] = 0.0f;
		i++;
	}
	*pCount = [retVal count];

	[retVal release];
	return pFinal;
}

NSArray *createBezierHelper(NSArray *input)
{
	CGPoint working[[input count]];
	int i = 0;

	int points = SLIDER_DETAIL_LEVEL * [input count];
	NSMutableArray *output = [[NSMutableArray alloc] init];
	HitObject *tmpHitObject;

	for (int iteration = 0; iteration < points; iteration++)
	{
		for (tmpHitObject in input)
		{
			working[i].x = tmpHitObject.x;
			working[i].y = tmpHitObject.y;
			i++;
		}
		
		for (int level = 0; level < [input count]; level++)
		{
			for (i = 0; i < [input count] - level - 1; i++)
			{
				working[i].x = working[i].x + (working[i + 1].x - working[i].x) * ((float)iteration/points);
				working[i].y = working[i].y + (working[i + 1].y - working[i].y) * ((float)iteration/points);
			}
		}
		tmpHitObject = [[HitObject alloc] init];
		tmpHitObject.x = working[0].x;
		tmpHitObject.y = working[0].y;
		[output addObject:tmpHitObject];
		[tmpHitObject release];
	}

	return output;
}

GLfloat *createBezier(NSArray *input, int pixelLength, float sliderMultiplier, int *pCount)
{
	//HitObject *lastPoint = [input objectAtIndex:0];
	int lastIndex = 0;
	NSArray *thisLength;
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];

	for (int i = 0; i < [input count]; i++)
	{
		if ((i > 0 && ((HitObject*)[input objectAtIndex:i]).x == ((HitObject*)[input objectAtIndex:i-1]).x && ((HitObject*)[input objectAtIndex:i]).y == ((HitObject*)[input objectAtIndex:i-1]).y) || i == [input count] - 1)
		{
			thisLength = [input subarrayWithRange:NSMakeRange(lastIndex, i - lastIndex + 1)];
			lastIndex = i;

			NSArray *tmpArray2 = createBezierHelper(thisLength);
			[tmpArray addObjectsFromArray:tmpArray2];
			[tmpArray2 release];
		}
	}

	GLfloat *retVal = calcConstant(tmpArray, pixelLength, sliderMultiplier, pCount);
	[tmpArray release];
	return retVal;
}

CGPoint CatmullRom(CGPoint value1, CGPoint value2, CGPoint value3, CGPoint value4, float amount)
{
    CGPoint retVal;
    float num = amount * amount;
    float num2 = amount * num;
    retVal.x = 0.5f * ((((2.0f * value2.x) + ((-value1.x + value3.x) * amount)) + (((((2.0f * value1.x) - (5.0f * value2.x)) + (4.0f * value3.x)) - value4.x) * num)) + ((((-value1.x + (3.0f * value2.x)) - (3.0f * value3.x)) + value4.x) * num2));
    retVal.y = 0.5f * ((((2.0f * value2.y) + ((-value1.y + value3.y) * amount)) + (((((2.0f * value1.y) - (5.0f * value2.y)) + (4.0f * value3.y)) - value4.y) * num)) + ((((-value1.y + (3.0f * value2.y)) - (3.0f * value3.y)) + value4.y) * num2));
    return retVal;
}

GLfloat *createCatmull(NSArray *input, int pixelLength, float sliderMultiplier, int *pCount)
{
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
	HitObject *tmp;
	CGPoint v1, v2, v3, v4, v5;
	int k;

	//tmp = [input objectAtIndex:0];
	//[tmpArray addObject:tmp];

	for (int j = 0; j < [input count] - 1; j++)
	{
		v1.x = (j - 1 >= 0 ? ((HitObject*)[input objectAtIndex:(j-1)]).x : ((HitObject*)[input objectAtIndex:(j)]).x);
		v1.y = (j - 1 >= 0 ? ((HitObject*)[input objectAtIndex:(j-1)]).y : ((HitObject*)[input objectAtIndex:(j)]).y);
		v2.x = ((HitObject*)[input objectAtIndex:(j)]).x;
		v2.y = ((HitObject*)[input objectAtIndex:(j)]).y;
		v3.x = (j + 1 < [input count] ? ((HitObject*)[input objectAtIndex:(j+1)]).x : v2.x + (v2.x - v1.x));
		v3.y = (j + 1 < [input count] ? ((HitObject*)[input objectAtIndex:(j+1)]).y : v2.y + (v2.y - v1.y));
		v4.x = (j + 2 < [input count] ? ((HitObject*)[input objectAtIndex:(j+2)]).x : v3.x + (v3.x - v2.x));
		v4.y = (j + 2 < [input count] ? ((HitObject*)[input objectAtIndex:(j+2)]).y : v3.y + (v3.y - v2.y));

		for (k = 0; k < SLIDER_DETAIL_LEVEL; k++)
		{
			v5 = CatmullRom(v1, v2, v3, v4, (float)k / SLIDER_DETAIL_LEVEL);
			tmp = [[HitObject alloc] init];
			tmp.x = v5.x;
			tmp.y = v5.y;
			[tmpArray addObject:tmp];
			[tmp release];
		}
	}

	GLfloat *realRetVal = calcConstant(tmpArray, pixelLength, sliderMultiplier, pCount);
	[tmpArray release];
	return realRetVal;
}

- (float)difficultyEyupStars:(int)DrainLength normal:(int)countNormal slider:(int)countSlider spinner:(int)countSpinner
{
	int totalHitObjects = countNormal + 2*countSlider + 3*countSpinner;
	double noteDensity = (double) totalHitObjects/DrainLength;
	double difficulty;

	if (totalHitObjects == 0 || [timingPoints count] == 0)
		return 0;

	if ((float) countSlider/totalHitObjects < 0.1)
		difficulty = difficulty_HPDrainRate + difficulty_OverallDifficulty + difficulty_CircleSize;
	else
		difficulty = (difficulty_HPDrainRate + difficulty_OverallDifficulty + difficulty_CircleSize +
					  [OsuFunctions max:0
							   y:([OsuFunctions min:4 y:1000/((TimingPoint*)[timingPoints objectAtIndex:0]).beatLength*difficulty_SliderMultiplier - 1.5]*2.5)])*0.75;
	double star;
	
	if (difficulty > 21) //songs with insane accuracy/circle size/life drain
		star = ([OsuFunctions min:difficulty y:30]/3*4 + [OsuFunctions min:(20 - 0.032*pow(noteDensity - 5, 4)) y:20])/10;
	else if (noteDensity >= 2.5) //songs with insane number of beats per second
		
		star = ([OsuFunctions min:difficulty y:18]/18*10 +
				[OsuFunctions min:(40 - 40/pow(5, 3.5)*pow(([OsuFunctions min:noteDensity y:5] - 5), 4)) y:40])/10;
	//exponent of 3.5 is fudged to give better results
	else if (noteDensity < 1) //songs with glacial number of beats per second
		star = ([OsuFunctions min:difficulty y:18]/18*10)/10 + 0.25;
	else //all other songs of medium difficulty
		star = ([OsuFunctions min:difficulty y:18]/18*10 + [OsuFunctions min:25*(noteDensity - 1) y:40])/10;
	
	return [OsuFunctions min:5 y:star];
}

// This crazy function is courtesy of peppy... he's insane...
- (void)calcHPDropRate
{
	OsuPlayer *testPlayer = [[OsuPlayer alloc] init];

	double testDrop = 0.05f;

	double lowestHpEver = [OsuFunctions mapDifficultyRange:difficulty_HPDrainRate min:195 mid:160 max:60];
	double lowestHpComboEnd = [OsuFunctions mapDifficultyRange:difficulty_HPDrainRate min:198 mid:170 max:80];
	double lowestHpEnd = [OsuFunctions mapDifficultyRange:difficulty_HPDrainRate min:198 mid:180 max:80];
	double HpRecoveryAvailable = [OsuFunctions mapDifficultyRange:difficulty_HPDrainRate min:8 mid:4 max:0];

	int totalHits;

	float maxHp;
	
	HpMultiplierComboEnd = 1.0f;
	HpMultiplierNormal = 1.0f;
	
	int countNormal = 0, countSlider = 0, countSpinner = 0;
	int drainFirstTime = ((HitObject*)[hitObjects objectAtIndex:0]).startTime;
	int drainLastTime;
	int drainBreakTime;

	do
	{
		totalHits = 0;
		[testPlayer resetHealth];
		testPlayer.curCombo= 0;
		testPlayer.score = 0;

		double lowestHp = testPlayer.health;
		int lastTime = ((HitObject*)[hitObjects objectAtIndex:0]).startTime - difficulty_PreEmpt;

		BOOL fail = NO;
		int comboTooLowCount = 0;
		
		countSlider = countSpinner = countNormal = 0;
		drainBreakTime = 0;

		for (int i = 0; i < [hitObjects count]; i++)
		{
			HitObject *h = [hitObjects objectAtIndex:i];
			if (h.objectType & kHitObject_Slider)
				countSlider++;
			else if (h.objectType & kHitObject_Spinner)
				countSpinner++;
			else
				countNormal++;
			drainLastTime = h.startTime;

			OsuEvent *tmpEvent;
			for (tmpEvent in events)
			{
				if (tmpEvent.type == kOsuEventType_BreakPeriod && tmpEvent.x >= lastTime && tmpEvent.y <= h.startTime)
					break;
			}

			int breakTime = tmpEvent != NULL ? (tmpEvent.y - tmpEvent.x) : 0;
			drainBreakTime += breakTime;
			[testPlayer decreaseHealth:testDrop*(h.startTime - lastTime - breakTime)];

			lastTime = h.endTime;

			if (testPlayer.health < lowestHp)
				lowestHp = testPlayer.health;

			if (testPlayer.health <= lowestHpEver)
			{
				//NSLog(@"Overall score drops below %f at %d (%f, lowest %f)", lowestHpEver, lastTime, testDrop, lowestHp);
				fail = YES;
				testDrop *= 0.96f;
				break;
			}

			[testPlayer decreaseHealth:testDrop * (h.endTime - h.startTime)];
			if (h.objectType & kHitObject_Slider)
			{
				for (int j = 0; j < h.repeatCount; j++)
					[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] doScore:h score:kHitObjectScore_SliderRepeat x:0 y:0 player:testPlayer simulate:YES];
				for (int j = 0; j < (ceil((h.rotationRequirement_sliderCurveCount - 1) / (SLIDER_TICKS_PER_BEAT / difficulty_SliderTickrate)) - 1) * h.repeatCount; j++)
					[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] doScore:h score:kHitObjectScore_SliderTick x:0 y:0 player:testPlayer simulate:YES];
			}
			else if (h.objectType & kHitObject_Spinner)
			{	
				for (int j = 0; j < h.rotationRequirement_sliderCurveCount; j++)
					[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] doScore:h score:kHitObjectScore_SpinnerSpinPoints x:0 y:0 player:testPlayer simulate:YES];
			}

			if ((i == [hitObjects count] - 1) ||
				(((HitObject*)[hitObjects objectAtIndex:(i+1)]).objectType & kHitObject_NewCombo > 0))
			{
				[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] doScore:h score:kHitObjectScore_300 x:0 y:0 player:testPlayer simulate:YES];

				if (testPlayer.health < lowestHpComboEnd)
				{
					if (++comboTooLowCount > 2)
					{
						HpMultiplierComboEnd *= 1.07;
						HpMultiplierNormal *= 1.03;
						fail = YES;
						break;
					}
				}
			}
			else
				[(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] doScore:h score:kHitObjectScore_300 x:0 y:0 player:testPlayer simulate:YES];

			maxHp = testPlayer.health;
		}
		
		if (!fail && testPlayer.health < lowestHpEnd)
		{
			//NSLog(@"Health < lowestHpEnd... testDrop = %f", testDrop);
			fail = YES;
			testDrop *= 0.94f;
			HpMultiplierComboEnd *= 1.01;
			HpMultiplierNormal *= 1.01;
		}

		double recovery = (testPlayer.healthUncapped - HP_BAR_MAXIMUM)/[hitObjects count];
		if (!fail && recovery < HpRecoveryAvailable)
		{
			//NSLog(@"Song has average %f recovery - being more lenient", recovery);
			fail = YES;
			testDrop *= 0.96;
			HpMultiplierComboEnd *= 1.02;
			HpMultiplierNormal *= 1.01;
		}

		if (fail)
			continue;

		HpDropRate = testDrop;

		int drainLength = (drainLastTime - drainFirstTime - drainBreakTime)/1000;
		difficulty_EyupStars = [self difficultyEyupStars:drainLength normal:countNormal slider:countSlider spinner:countSpinner];

		//NSLog(filename);
		//NSLog(@"      hitcircles: %d", countNormal);
		//NSLog(@"         sliders: %d", countSlider);
		//NSLog(@"        spinners: %d", countSpinner);
		//NSLog(@"      drain rate: %f", (testDrop*60)/2);
		//NSLog(@"       lowest hp: %f", lowestHp/2);
		//NSLog(@"normal multiplier: %f", HpMultiplierNormal);
		//NSLog(@"combo multiplier: %f", HpMultiplierComboEnd);
		//NSLog(@" excess hp recov: %f/hitobject", (float) (testPlayer.healthUncapped - HP_BAR_MAXIMUM)/2/[hitObjects count]);
		//NSLog(@"    max final hp: %f", testPlayer.health/2);
		//NSLog(@"difficulty_EyupStars: %f", difficulty_EyupStars);

		break;
	} while (YES);

	[testPlayer release];
}

- (void)processHitObjects
{
	if (hitObjects)
		return;

	NSString *fileContents = [NSString stringWithContentsOfFile:filename];
	NSScanner *scanner = [NSScanner scannerWithString:fileContents];
	HitObject *tmpHitObject, *tmpSliderObject;
	NSString *tmpString;
	NSMutableArray *tmpArray;
	int tmp;
	int curColour = 1;
	int curCombo = 0;
	int curTimingPointIndex = 1;

	difficulty_PreEmpt = (int)[OsuFunctions mapDifficultyRange:difficulty_OverallDifficulty min:1800 mid:1200 max:450];
	difficulty_HitCircleSize = 64.0f * (1.0f - 0.7f*((difficulty_CircleSize-5.0f)/5.0f)) * 1.4f; // multiply by 1.5 for iPhone

	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@" ,"]];

	[scanner scanUpToString:@"[HitObjects]" intoString:NULL];
	[scanner scanString:@"[HitObjects]" intoString:NULL];

	[scanner scanUpToString:@"\n" intoString:NULL];
	[scanner scanString:@"\n" intoString:NULL];
	
	hitObjects = [[NSMutableArray alloc] init];

	do
	{
		tmpHitObject = [[HitObject alloc] init];
		if ([scanner scanInt:&tmp] == NO)
			break;
		tmpHitObject.x = tmp;
		if ([scanner scanInt:&tmp] == NO)
			break;
		tmpHitObject.y = tmp;
		if ([scanner scanInt:&tmp] == NO)
			break;
		tmpHitObject.startTime = tmpHitObject.endTime = tmp;
		if ([scanner scanInt:&tmp] == NO)
			break;
		tmpHitObject.objectType = tmp;
		if ([scanner scanInt:&tmp] == NO)
			break;
		tmpHitObject.soundType = tmp;

		if (tmpHitObject.objectType & kHitObject_NewCombo)
		{
			curColour++;
			curCombo = 0;
			
			if (curColour == numColours)
				curColour = 0;
		}
		tmpHitObject.colourIndex = curColour;
		curCombo++;
		tmpHitObject.comboNum = curCombo;

		if ([scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"BLC"] intoString:&tmpString] == YES)
		{
			// Slider

			tmpArray = [[NSMutableArray alloc] init];
			tmpSliderObject = [[HitObject alloc] init];
			tmpSliderObject.x = tmpHitObject.x;
			tmpSliderObject.y = tmpHitObject.y;
			//NSLog(@"Scanned in Slider: {%@,%f,%f}", tmpString, tmpSliderObject.x, tmpSliderObject.y);
			[tmpArray addObject:tmpSliderObject];
			[tmpSliderObject release];

			[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@":|"]];
			do
			{
				tmpSliderObject = [[HitObject alloc] init];

				if ([scanner scanInt:&tmp] == NO)
					break;
				tmpSliderObject.x = tmp;
				if ([scanner scanInt:&tmp] == NO)
					break;
				tmpSliderObject.y = tmp;

				//NSLog(@"Scanned in Slider: {%@,%f,%f}", tmpString, tmpSliderObject.x, tmpSliderObject.y);
				[tmpArray addObject:tmpSliderObject];
				[tmpSliderObject release];

			} while ([scanner scanString:@"," intoString:NULL] == NO);

			if ([scanner scanInt:&tmp] == NO)
				break;
			tmpHitObject.repeatCount = tmp;
			[scanner scanString:@"," intoString:NULL];
			if ([scanner scanInt:&tmp] == NO)
				break;
			tmpHitObject.endTime = tmp;
			if ([scanner scanString:@"," intoString:NULL] == YES) // per endpoint slider sounds exist
			{
				NSString *tmpString2;
				[scanner scanUpToString:@"\n" intoString:&tmpString2];
				tmpHitObject.sliderPerEndpointSounds = [[tmpString2 componentsSeparatedByString:@"|"] retain];
				//NSLog(@"Scanned in perendpointsounds: %@", [tmpHitObject.sliderPerEndpointSounds componentsJoinedByString:@"|"]);
			}
			[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@" ,"]];

			if ([tmpArray count] > 0)
			{
				// remove redundant point present in older osu formats
				if (((HitObject*)[tmpArray objectAtIndex:0]).x == ((HitObject*)[tmpArray objectAtIndex:1]).x && ((HitObject*)[tmpArray objectAtIndex:0]).y == ((HitObject*)[tmpArray objectAtIndex:1]).y)
					[tmpArray removeObjectAtIndex:0];
			}

			if ([tmpString isEqual:@"B"])
			{
				int count;
				tmpHitObject.pSliderCurvePoints = createBezier(tmpArray, tmpHitObject.endTime, difficulty_SliderMultiplier, &count);
				tmpHitObject.rotationRequirement_sliderCurveCount = count;
				tmpHitObject.sliderCurveType = kSlider_Bezier;
			}
			else if ([tmpString isEqual:@"L"])
			{
				int count;
				tmpHitObject.pSliderCurvePoints = calcConstant(tmpArray, tmpHitObject.endTime, difficulty_SliderMultiplier, &count);
				tmpHitObject.rotationRequirement_sliderCurveCount = count;
				tmpHitObject.sliderCurveType = kSlider_Linear;
			}
			else
			{
				int count;
				tmpHitObject.pSliderCurvePoints = createCatmull(tmpArray, tmpHitObject.endTime, difficulty_SliderMultiplier, &count);
				tmpHitObject.rotationRequirement_sliderCurveCount = count;
				tmpHitObject.sliderCurveType = kSlider_Catmull;
			}
			while (curTimingPointIndex < [timingPoints count] && ((TimingPoint*)[timingPoints objectAtIndex:curTimingPointIndex]).offsetMs <= tmpHitObject.startTime)
				curTimingPointIndex++;

			tmpHitObject.endTime = tmpHitObject.startTime + ((tmpHitObject.endTime / (difficulty_SliderMultiplier * 100.0f)) * ((TimingPoint*)[timingPoints objectAtIndex:curTimingPointIndex-1]).beatLength * tmpHitObject.repeatCount);

			//tmpHitObject.sliderTexture = [(OsuAppDelegate*)[[UIApplication sharedApplication] delegate] renderSlider:tmpHitObject];
			[tmpArray release];
		}
		else if ([scanner scanInt:&tmp] == YES)
		{
			// Spinner
			tmpHitObject.endTime = tmp;
			tmpHitObject.repeatCount = 0;
			tmpHitObject.rotationRequirement_sliderCurveCount = (int)((float) (tmpHitObject.endTime - tmpHitObject.startTime)/1000*[OsuFunctions mapDifficultyRange:difficulty_OverallDifficulty min:3 mid:5 max:7.5]) * 0.7f; // multiplied by 0.75 for iPhone
			tmpHitObject.maxAccel = 0.00008 + fabs((5000 - (double)(tmpHitObject.endTime - tmpHitObject.startTime)) / 1000.0f / 2000.0f);
		}
		//NSLog(@"Scanned in HitObject: {%f,%f,%d,%d,%d,%d,%d}\n", tmpHitObject.x, tmpHitObject.y, tmpHitObject.startTime, tmpHitObject.objectType, tmpHitObject.soundType, tmpHitObject.endTime, tmpHitObject.repeatCount);

		tmpHitObject.stackSize = 0;
		for (tmp = [hitObjects count] - 1; tmp >= 0; tmp--)
		{
			tmpSliderObject = [hitObjects objectAtIndex:tmp]; // not necessarily a slider object, just reusing a var
			if (tmpHitObject.startTime > tmpSliderObject.startTime + (difficulty_PreEmpt * general_StackLeniency) + FADE_TIME)
				break;
			if ([OsuFunctions dist:tmpHitObject.x y1:tmpHitObject.y x2:tmpSliderObject.x y2:tmpSliderObject.y] < 3.0f)
				tmpHitObject.stackSize += 1;
		}

		[hitObjects addObject:tmpHitObject];
		[tmpHitObject release];
		[scanner scanUpToString:@"\n" intoString:NULL];
		if ([scanner scanString:@"\n" intoString:NULL] == NO)
			break;
	} while (![scanner isAtEnd]);

	tmpHitObject = [hitObjects lastObject];
	general_TotalLength = tmpHitObject.endTime;
}

- (void)releaseGameElements
{
	[hitObjects release];
	hitObjects = NULL;
}

- (NSArray*)getHighscores
{
	return highScores;
}

- (BOOL)isHighscore:(int)newScore
{
	if ([highScores count] < 10)
		return YES;

	return newScore > [[highScores objectAtIndex:9] intValue];
}

NSInteger highScoreSort(id score1, id score2, void *context)
{
	int v1 = [score1 intValue];
	int v2 = [score2 intValue];

	if (v1 > v2)
		return NSOrderedAscending;
	else if (v1 < v2)
		return NSOrderedDescending;
	
	return NSOrderedSame;
}

- (void)addHighscore:(int)newScore rank:(int)newRanking name:(NSString*)newName combo:(int)newCombo
{
	NSString *newScoreString = [NSString stringWithFormat:@"%d,%d,%d,%@", newScore, newRanking, newCombo, newName];
	[highScores addObject:newScoreString];
	[highScores sortUsingFunction:highScoreSort context:NULL];
	while ([highScores count] > 10)
		[highScores removeLastObject];
}

- (void)dealloc
{
	[filename release];
	[general_Md5Sum release];
	[general_AudioFilename release];
	[general_AudioHash release];
	[metaData_Title release];
	[metaData_Artist release];
	[metaData_Creator release];
	[metaData_Version release];
	[metaData_Source release];
	[metaData_Tags release];
	[hitObjects release];
	[events release];
	[timingPoints release];
	if (highScores)
		[highScores release];

	[super dealloc];
}

- (void)putFilenameIntoArray:(id)array
{
	NSMutableArray *tmpArray = array;
	[tmpArray addObject:[filename lastPathComponent]];
}

- (void)putMd5SumsIntoArray:(id)array
{
	NSMutableArray *tmpArray = array;
	[tmpArray addObject:general_Md5Sum];
}

- (void)putDifficultyTextIntoArray:(id)array
{
	NSMutableArray *tmpArray = array;
	[tmpArray addObject:metaData_Version];
}

- (void)putHpDrainRatesIntoArray:(id)array
{
	NSMutableArray *tmpArray = array;
	[tmpArray addObject:[NSString stringWithFormat:@"%f", HpDropRate]];
}

- (void)putHpMultiplierNormalsIntoArray:(id)array
{
	NSMutableArray *tmpArray = array;
	[tmpArray addObject:[NSString stringWithFormat:@"%f", HpMultiplierNormal]];
}

- (void)putHpMultiplierComboEndsIntoArray:(id)array
{
	NSMutableArray *tmpArray = array;
	[tmpArray addObject:[NSString stringWithFormat:@"%f", HpMultiplierComboEnd]];
}

- (void)putDifficultyStarsIntoArray:(id)array
{
	NSMutableArray *tmpArray = array;
	[tmpArray addObject:[NSString stringWithFormat:@"%f", difficulty_EyupStars]];
}

- (void)putPlaycountIntoArray:(id)array
{
	NSMutableArray *tmpArray = array;
	[tmpArray addObject:[NSString stringWithFormat:@"%d", general_Playcount]];
}

- (void)putHighscoresIntoArray:(id)array
{
	NSMutableArray *tmpArray = array;
	[tmpArray addObject:[highScores componentsJoinedByString:@"\\"]];
}

@end
