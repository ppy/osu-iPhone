//
//  OsuPlayer.h
//  Osu
//
//  Created by Christopher Luu on 8/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OsuPlayer : NSObject {
@private
	NSString *name;
	int score;
	float health;
	float displayedHealth;
	float healthUncapped;
	int curCombo;
	int maxCombo;
}

@property(assign) NSString *name;
@property int score;
@property float health;
@property float healthUncapped;
@property float displayedHealth;
@property int curCombo;
@property int maxCombo;

- (void)resetHealth;
- (void)increaseHealth:(float)amount;
- (void)decreaseHealth:(float)amount;
- (void)updateDisplayHealth;

@end
