/* Copyright WTFPL 2.0 All rights reserved to be given away */
/* http://forums.capitalgames.com/showthread.php/71800-Battle-Simulator */
#import "hodabs.h"
#import "actions.h"

// add characters here

#define CHANCE_MODERATE 0.5
#define CHANCE_SMALL 0.25
#define CHANCE_HIGH 0.75
#define CHANCE_FULL 1.0

@implementation HeroTemplate
static NSMutableDictionary* _template = nil;

+ (void) initialize
{
	_template = [ NSMutableDictionary dictionaryWithDictionary:
@{

// See templates.inc
#define ACT(NAME)  [ Action_ ## NAME class ]
#include "templates.inc"

}];
}

+ (NSArray*) templateFor: (NSString*) heroName
{
	return [_template objectForKey: heroName ];
}

+ (void) append: (NSDictionary*) myHeros
{
	[_template addEntriesFromDictionary: myHeros ];
}

@end

@implementation Team

- (id) init
{
	_layout = [ NSMutableArray arrayWithArray:@[ NOHERO,NOHERO,NOHERO,NOHERO,NOHERO ]];
	return self;
}

- (NSArray*) members
{
	NSMutableArray* members = [ NSMutableArray new ];
	for(Hero* h in _layout )
		if( h != NOHERO ) [ members addObject: h ];

	return members;
}

- (NSArray*) membersAtPositions: (Positions) pos
{
	NSMutableArray* ret = [ NSMutableArray new ];
	Hero* h;

	if( pos & POS_LC ) 
	{
		h = _layout[ LOC_LC ];
		if( h != NOHERO && h.health > 0 ) [ ret addObject: h ];
	}

	if( pos & POS_F )
	{
		if( pos & POS_FL )
		{
			h = _layout[ LOC_FL ];
			if( h != NOHERO && h.health > 0 ) [ ret addObject: h ];
		}
		if( pos & POS_FR )
		{
			h = _layout[ LOC_FR ];
			if( h != NOHERO && h.health > 0 ) [ ret addObject: h ];
		}
	}

	if( pos & POS_B )
	{
		if( pos & POS_BL )
		{
			h = _layout[ LOC_BL ];
			if( h != NOHERO && h.health > 0 ) [ ret addObject: h ];
		}
		if( pos & POS_BR )
		{
			h = _layout[ LOC_BR ];
			if( h != NOHERO && h.health > 0 ) [ ret addObject: h ];
		}
	}

	return ret;
}

- (Positions) positionsNeedsAlive: (BOOL) needAlive
{
	Positions p = POS_NONE;
	Hero* h;

	for(Location l = 0; l < MAX_UNIT; l++ )
	{
		h = _layout[ l ];
		if( h != NOHERO )
		{
			if( !needAlive || h.health > 0 )
			{
				p = p | 1 << l;
			}
		}
	}

	return p;
}

- (id) objectAtIndexedSubscript: (NSUInteger) idx
{
	return _layout[ idx ];
}

- (void)         setObject: (id) anObject
	atIndexedSubscript: (NSUInteger) idx
{
	if( anObject != NOHERO )
	{
		Hero* hero = anObject;
		NSAssert( hero.isGiant && idx == 0 ||
			 !hero.isGiant && idx != 0 , @"LC misplaced" );
		hero.team = self;
	}

	_layout[ idx ] = anObject;
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state
				   objects: (__unsafe_unretained id[]) stackbuf
				     count: (NSUInteger) len
{
	return [_layout countByEnumeratingWithState: state
					    objects: stackbuf
					      count: len ];
}

- (NSUInteger) index
{
	Team* aTeam = _field.teams[0];
	if( aTeam == self ) return 0;
	return 1;
}

- (Team*) opponent
{
	Team* opponent = _field.teams[0];
	if( opponent == self ) opponent = _field.teams[1];
	return opponent;
}

// Battle

- (void) attackWithAction: (Action*) action
{
	for(Hero* target in action.targets )
	{
		NSAssert( target.health > 0, @"I see dead people." );

		/* Minus initial damage in the target's action power */
		target.action.power = -[ action attackPowerTo: target ];
	}

	if( do_battle_log )
		NSLog(@"%@ (%.1f:p) is attacking (%@%@)", action.hero.name, action.power,
			action.hero.order < SPEED_NORMAL ? @"FAST" :
			action.hero.order < SPEED_SLOW   ? @"NORMAL" :@"SLOW",
			action.isCritical ? @" 2X" :@"" );

	[ self.field dealAction: action ];
}

@end

@implementation Field

- (id) initWithTeams: (Team*) team1 : (Team*) team2
{
	_team1 = team1;
	_team1.field = self;

	_team2 = team2;
	_team2.field = self;

	return self;
}

- (id) init
{
	return [ self initWithTeams:[ Team new ] :[ Team new ]];
}

- (NSArray*) teams
{
	return @[_team1, _team2 ];
}

- (NSArray*) members
{
	return [_team1.members arrayByAddingObjectsFromArray: _team2.members ];
}

- (void) _prepareHeroes
{
	_isPrepared = YES;

	/* Buffing */
	/* Max were initially fort power, I thought this wasn't fixed yet, was it?
	 * http://forums.capitalgames.com/showthread.php/69501-Changes-to-Aura-and-Rune-Stacking
	 * it should be (Base Health + Fortify) * (Optional 1.5 front row bonus) * (1+(sum of auras)) * (1+(sum of rune bonuses))
	 * Cr: Pe Wa
	 * Health
	 * [[[ Base + Event% ] + Fortification ] + (Sum of Auras%) ] + Front Row Bonus
	 * Power
	 * [[[ Base + Event% ] + Fortification ] + (Sum of Auras%) ] + Faction Bonus 
	 *
	 * Cr: Sarcodino
	 * Runes stack whit all other boost:
	 * HP: FR stacks whit auras and event bonus
	 * ((((Base * event %) + fort) * sum of auras) * 1.5 FR bonus) * rune * rune
	 *
	 * Power: faction bonus stacks whit auras and event bonus
	 * ((((Base * event %) + fort) * sum of auras) * faction bonus) * rune * rune 
	 *
	 * To explain the code, rather summing aura percent directly,
	 * I use -power/healthGainFor: to gather the absolute values.
	 * So the actual code would work like this.
	 *
	 * let base = base x event%
	 * base = base x auraA + base x auraB + base x auraC ...
	 * base = base x faction bonus
	 */


	/* calculate faction bonus (percent) */
	double faction_bonus[2] = {1.0,1.0};
	for(int i = 0; i < 2; i++ )
	{
		/* faction buffing */
		int factions[] = {0,0,0,0};

		for(Hero* hero in (i==0?_team1:_team2).members )
		{
			if( hero.isBlack ) factions[ COLOR_BLACK ]++;
			if( hero.isRed ) factions[ COLOR_RED ]++;
			if( hero.isWhite ) factions[ COLOR_WHITE ]++;
			if( hero.isBlue ) factions[ COLOR_BLUE ]++;
		}

		for(int fi = 0; fi < 4; fi++)
		{
			if( factions[fi] == 4 ) /* team filled with same faction heroes */
			{
				for(Hero* hh in (i==0?_team1:_team2).members )
				{
					if( hh.location == LOC_LC ) continue;
					switch( hh.rarity )
					{
						case RARITY_LEGENDARY:	faction_bonus[i] += 0.05; break;
						case RARITY_EPIC:	faction_bonus[i] += 0.04; break;
						case RARITY_RARE:	faction_bonus[i] += 0.03; break;
						case RARITY_UNCOMMON:	faction_bonus[i] += 0.02; break;
						case RARITY_COMMON:	faction_bonus[i] += 0.01; break;
						default:;
					}
				}
				break;
			}
		}
	}
//#ifdef BATTLELOG
	NSLog(@"1: faction bonus %.1f%%", (faction_bonus[0]-1) * 100);
	NSLog(@"2: faction bonus %.1f%%", (faction_bonus[1]-1) * 100);
//#endif

//	exit(0);
	/* Make debuffing the opponent side possible for future use */
	NSArray* allHeroes = self.members;

	for(Hero* h in allHeroes )
	{
		double power_boost_sum = 0;
		double health_boost_sum = 0;
		double nostun_sum = 0;
		double noslow_sum = 0;
		double nodrain_sum = 0;

		/* aura buffing */
		for(Hero* hh in allHeroes)
		{
			double pg = [ hh.action powerGainFor: h ];
			double hg = [ hh.action healthGainFor: h ];
			double st = [ hh.action stunResistanceGainFor: h ];
			double sl = [ hh.action slowResistanceGainFor: h ];
			double dr = [ hh.action drainResistanceGainFor: h ];
//#ifdef BATTLELOG
			if( pg > 0) NSLog(@"  [+%.1f:p] by %@", pg, hh.name);
			if( hg > 0) NSLog(@"  [+%.1f:h] by %@", hg, hh.name);
			if( st > 0) NSLog(@"  [+%.1f:%%] stun resistance by %@", st*100, hh.name);
			if( sl > 0) NSLog(@"  [+%.1f:%%] slow resistance by %@", sl*100, hh.name);
			if( dr > 0) NSLog(@"  [+%.1f:%%] drain resistance by %@", dr*100, hh.name);
//#endif
			power_boost_sum += pg;
			health_boost_sum += hg;
			nostun_sum += st;
			noslow_sum += sl;
			nodrain_sum += dr;
		}

		h.base_power += power_boost_sum;
		h.base_health += health_boost_sum;
		h.stunResistance = nostun_sum < 1.0 ? nostun_sum : 1.0;
		h.slowResistance = noslow_sum < 1.0 ? noslow_sum : 1.0;
		h.drainResistance = nodrain_sum < 1.0 ? nodrain_sum : 1.0;

		/* applying faction bonus */
		h.base_power *= faction_bonus[( h.team ==_team1 ?0:1)];

		/* front row health bonus */
		h.base_health *= ((1 << h.location) & POS_F ? 1.5 : 1.0 );
		/* back row crit bonus */
		h.criticalChance *= ((1 << h.location) & POS_B ? 2.0 : 1.0 );

		[ h refresh ];
//#ifdef BATTLELOG
		NSLog(@"= %@", h);
		NSLog(@"---------------");
//#endif
	}
}

- (NSUInteger) run
{
	_round = 0;

	_damageBy1 = 0;
	_damageBy2 = 0;

	if(!_isPrepared )[ self _prepareHeroes ];

	for(Hero* hero in self.members )
	{
		[ hero refresh ];
	}


	NSUInteger round;
	do {
		round = [ self _runRound ];

		_damageBy1 += _team1.roundDamage;
		_damageBy2 += _team2.roundDamage;

	} while( round );

	double sumBaseHP[2] = { 0, 0 };
	double sumHP[2] = { 0, 0 };

	for(Hero* hero in self.members )
	{
		int ti = hero.team == _team1 ? 0 : 1;
		sumHP[ti] += hero.health;
		sumBaseHP[ti] += hero.base_health;
	}

	/* FIXME Does winning based on % left? */
	sumHP[0] /= sumBaseHP[0];
	sumHP[1] /= sumBaseHP[1];

	return sumHP[0] > sumHP[1] ? 0 : 1;
}

#define MAXROUND 10
- (NSUInteger) _runRound
{@autoreleasepool{

	Hero* h;

	NSMutableArray* allHeroes = [ NSMutableArray arrayWithArray: self.members ];

	if( do_battle_log ) NSLog(@"<Round %d>",_round);
	_team1.roundDamage = 0;
	_team2.roundDamage = 0;

	/* Reset curse at the beginning of the new round */
	for( Hero* h in allHeroes )
	{
		h.cursed = NO;
	}

	while( allHeroes.count  )
	{
		for( h in allHeroes )
		{
			h.order = drand48() + h.speed + h.slowness;
		}

		[ allHeroes sortUsingComparator: (NSComparisonResult(^)(id,id))^( Hero* h1, Hero* h2)
		{
			if( h1.order < h2.order )
				return (NSComparisonResult)NSOrderedAscending; 
			else
				return (NSComparisonResult)NSOrderedDescending; 
		}];

		h = allHeroes[0];
		[ allHeroes removeObjectAtIndex: 0 ];

		[ h fire ];

		for(Team* t in self.teams )
		{
			BOOL stillAlive = NO;
			for(Hero* h in t.members )
			{
				if( h.health > 0 )
				{
					stillAlive = YES;
					break;
				}
			}

			if( !stillAlive )
			{
				return 0;
			}
		}
	}

	_round++;

	if(_round == MAXROUND + 1) return 0;

	return _round;
}}

- (void) dealAction: (Action*) attack
{
//	NSArray* members = self.members;
	/* At this state, damages were stored in the receiving heroes' action.power
	 * Inform all members that we are being attacked, so they may be able to
	 * do something about that
	 */

	double org_dmg[2][LOC_NONE];
	double abs_dmg[2][LOC_NONE];

	memset(org_dmg, 0, sizeof(org_dmg));
	memset(abs_dmg, 0, sizeof(abs_dmg));

	/* Save the original damage values so friends could alter the current
	 * damage value directly.
	 */
	for(Hero* target in attack.targets )
	{
		Location l = target.location;
		NSUInteger idx = target.team.index;

		org_dmg[ idx ][ l ] = target.action.power;
		abs_dmg[ idx ][ l ] = 0;
	}

	/* Let everybody prepare the initial damage, applying battle time aura factors */
	for(Hero* hero in self.members )
	{
		[ hero.action prepareDamage: attack ];

		/* Collect the modifications this hero did to the old values */
		for(Hero* target in attack.targets)
		{
			Location l = target.location;
			NSUInteger idx = target.team.index;

			abs_dmg[ idx ][ l ] += (target.action.power - org_dmg[ idx ][ l ]);
			//Restore old value back so all freinds see the same base.
			target.action.power = org_dmg[ idx ][ l ];
		}
	}

	for(Hero* hero in self.members )
	{
		[ hero.action applyDamage: attack ];
	}

	/* Applying the new power set as actual damage */
	for(Hero* target in attack.targets )
	{
		Location l = target.location;
		NSUInteger idx = target.team.index;

		org_dmg[ idx ][ l ] += abs_dmg[ idx ][ l ];

		//Damaging dont go above 0 or it would be healing.
		if( org_dmg[ idx ][ l ] > 0 ) org_dmg[ idx ][ l ] = 0;

		target.action.power = org_dmg[ idx ][ l ];

//		double prevHealthLog = target.health;
//		target.health -= org_dmg[ l ];

		[ target applyHealth: org_dmg[ idx ][ l ]
			      byHero: attack.hero ];

		//Logging
#if 0
		if( do_battle_log )
		{
			BOOL xf = NO;
			BOOL rowColLC = NO;

			if(( attack.hero.isBlack && target.isWhite ) ||
			   ( attack.hero.isBlue && target.isBlack ) ||
			   ( attack.hero.isRed && target.isBlue ) ||
			   ( attack.hero.isWhite && target.isRed ))
				xf = YES;

			if([ attack isKindOfClass:[ RowAction class ]] ||
			   [ attack isKindOfClass:[ ColAction class ]])
				rowColLC = target.isGiant ? YES : NO;

			NSLog(@".... [%.1f:p%@%@] %@ %@ (%.1f:h → %.1f:h)",
					org_dmg[ l ],
					xf?@" XF":@"",
					rowColLC?@" LC":@"",
					target.health > 0 ? @"attacks":@"KILLS",
					target.name,
					prevHealthLog,
					target.health);
		}
#endif
	}

	// Let all heroes learn about the damage.
	for(Hero* member in self.members )
	{
		[ member.action finalizeDamage: attack ];
	}

}

@end

@implementation BLog

static NSMutableArray* logBuffer = nil;
static BOOL doLog = NO;

+ (void) initialize
{
	logBuffer = [ NSMutableArray new ];
}

+ (void) format: (NSString*) format, ...;
{
	if( !doLog ) return;

	va_list ap;
	va_start(ap, format);

	[ logBuffer addObject:[ NSString stringWithFormat: format
						arguments: ap ]];
	va_end(ap);
}

+ (void) setLog: (BOOL) onOff
{
	doLog = onOff;
}

+ (NSUInteger) flush
{
	if( logBuffer.count > 0 )
	{
		if( doLog )
			NSLog(@"%@", logBuffer[0]);
		[ logBuffer removeObjectAtIndex: 0 ];
	}
	return logBuffer.count;
}

@end
