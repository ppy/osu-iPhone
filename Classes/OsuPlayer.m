//
//  OsuPlayer.m
//  Osu
//
//  Created by Christopher Luu on 8/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "OsuPlayer.h"
#import "OsuFunctions.h"

@implementation OsuPlayer

@synthesize name;
@synthesize score;
@synthesize health;
@synthesize healthUncapped;
@synthesize displayedHealth;
@synthesize curCombo;
@synthesize maxCombo;

- (void)resetHealth
{file://localhost/Users/peppy/Documents/osu!/svn/osu!-iPhone/Classes/OsuPlayer.h
	health = healthUncapped = HP_BAR_MAXIMUM;
}

- (void)updateDisplayHealth
{
	if (abs(health - displayedHealth) > 0.1)
	{
		if (health > displayedHealth)
			displayedHealth += (health - displayedHealth)/8;
		else
			displayedHealth -= (displayedHealth - health)/4;
	}
}


- (void)increaseHealth:(float)amount
{
	healthUncapped += amount;
	health += amount;
	if (health > HP_BAR_MAXIMUM)
		health = HP_BAR_MAXIMUM;
	if (health < 0.0f)
		health = 0.0f;
}

- (void)decreaseHealth:(float)amount
{
	health -= amount;
	if (health < 0.0f)
		health = 0.0f;
	healthUncapped -= amount;
	if (healthUncapped < 0.0f)
		healthUncapped = 0.0f;
}

- (void)dealloc
{
	[name dealloc];
	[super dealloc];
}

@end
