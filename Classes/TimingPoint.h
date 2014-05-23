//
//  TimingPoint.h
//  Osu
//
//  Created by Christopher Luu on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TimingPoint : NSObject
{
@private
	int offsetMs;
	double beatLength;
	int sampleSetId;
	int useCustomSamples;
	int sampleVolume;
	bool isKiaiTime;
}

@property int offsetMs;
@property double beatLength;
@property int sampleSetId;
@property int useCustomSamples;
@property int sampleVolume;
@property bool isKiaiTime;

@end
