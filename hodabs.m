/* Copyright WTFPL 2.0 All rights reserved to be given away */
/* http://forums.capitalgames.com/showthread.php/71800-Battle-Simulator */
#import "hodabs.h"

// add characters here

#define CHANCE_MODERATE 0.5
#define CHANCE_SMALL 0.25
#define CHANCE_HIGH 0.75
#define CHANCE_FULL 1.0

@interface Action_AD : Action @end
@interface Action_AJ : RowAction @end
@interface Action_Archy : Action @end
@interface Action_BM : AoEAction @end
@interface Action_CSQ : RowAction @end
@interface Action_Dan : AoEAction @end
@interface Action_DD : AoEAction @end
@interface Action_DF : AoEAction @end
@interface Action_GEF : AoEAction @end
@interface Action_GWB : AoEAction @end
@interface Action_GWC : RowAction @end
@interface Action_HO : AoEAction @end
@interface Action_Hybris : ColAction @end
@interface Action_Izzy : ColAction @end
@interface Action_KM : AoEAction @end
@interface Action_Leliana : Action @end
@interface Action_Merrill : AoEAction @end
@interface Action_Morrigan : RowAction @end
@interface Action_Sigrun : Action @end
@interface Action_TF : Action @end
@interface Action_Uldred : AoEAction @end
@interface Action_VA : AoEAction @end
@interface Action_Vart : AoEAction @end
@interface Action_Velanna : AoEAction @end
@interface Action_VT : RowAction @end
@interface Action_WF : RowAction @end
@interface Action_Zathrian : ColAction @end

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

	/* Tell everybody including the attacking hero that we are attacking.
	 * They may also alter the action's power at this point
	 */
	for(Hero* hero in self.members )
	{
		[ hero.action prepareAttack: action ];
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
	_damageBy1 = 0;
	_damageBy2 = 0;

	if(!_isPrepared )[ self _prepareHeroes ];

	for(Hero* hero in self.members )
	{
		[ hero refresh ];
	}


	NSUInteger round;
	do {
		round = [ self _runBattle ];

		_damageBy1 += _team1.roundDamage;
		_damageBy2 += _team2.roundDamage;

	} while( round );

	for(Hero* hero in self.members )
	{
		if(hero.health > 0 )
		{
			if (hero.team == _team1)
				return 0;	//1 WIN
			else return 1;		//2 WIN
		}
	}

	return NSNotFound;
}

#define MAXROUND 10
- (NSUInteger) _runBattle
{@autoreleasepool{

	Hero* h;

	NSMutableArray* allHeroes = [ NSMutableArray arrayWithArray: self.members ];

	if( do_battle_log ) NSLog(@"<Round %d>",_round);
	_team1.roundDamage = 0;
	_team2.roundDamage = 0;

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

	/* Let everybody prepare the initial damage */
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

@implementation Action

// Battle Prep
- (double) powerGainFor: (Hero*)aHero
{
	return 0.0;
}

- (double) healthGainFor: (Hero*)aHero
{
	return 0.0;
}

- (double) stunResistanceGainFor: (Hero*)aHero
{
	return 0.0;
}

- (double) slowResistanceGainFor: (Hero*)aHero
{
	return 0.0;
}

- (double) drainResistanceGainFor: (Hero*)aHero
{
	return 0.0;
}

// Round Battle

#if 0
- (double) defend: (Hero*) aHero
	    power: (double) power
	     from: (Hero*) hisFoe
{
}

- (double) defend: (Hero*) aHero
	    drain: (double) power
	     from: (Hero*) hisFoe
{
}
#endif

- (BOOL) slow: (Hero*) anEnemy
       chance: (double) chance
{
	BOOL success = [ anEnemy makeSlower ];

	if( do_battle_log && success )
		NSLog(@"...... slows %@ ", anEnemy.name );

	return success;
}

- (BOOL) stun: (Hero*) anEnemy
       chance: (double) chance
{
	if( drand48() > chance ) return NO;

	BOOL success = [ anEnemy makeStunned ];

	if( do_battle_log && success )
		NSLog(@"...... stuns %@ ", anEnemy.name );

	return success;
}

- (double) drain: (Hero*) anEnemy
	  chance: (double) chance
{
	if( drand48() > chance ) return 0.0;

	double drainPower = _hero.power / 2.0;

	double foe_power = anEnemy.power;
	drainPower = [ anEnemy drainedWithPower: drainPower ];

	if( do_battle_log && drainPower > 0.0 )
		NSLog(@"...... drains %@ (%.1f:p → %.1f:p)",
				anEnemy.name, foe_power, anEnemy.power );

	return drainPower;

}

//TODO refactor this
- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances
{
	double chances[] = { CHANCE_LC, CHANCE_FL, CHANCE_FR, CHANCE_BL, CHANCE_BR };

	double total_chance = 0;

	for(Location l = LOC_LC; l < LOC_NONE; l++)
	{
		Hero* e = self.hero.team.opponent.layout[l];

		if( e != NOHERO && e.health > 0 )
		{
			if( posChances ) chances[l] = posChances[l];
			total_chance += chances[l];
		}
		else chances[l] = 0;
	}

	/* FIXME Need improvements for instance, should increase
	 * back row chances once the front row is missing.
	 * Some measurements would be required to implement the actual
	 * chances.
	 */

	double pos_rand = drand48() * total_chance;

	Location l;
	for( l = LOC_LC; l < LOC_NONE; l++ )
	{
		pos_rand -= chances[l];
		if( pos_rand < 0 )
		{
			break;
		}
	}

	return 1 << l;
}


#if 0
- (void) action: (Action*) anAction
     willAttack: (Hero*) aFoe
{
	//Subclass may override to modify initial factors.
}

- (void) attack: (Hero*) aFoe
	  power: (double) firePower
	 factor: (double) factor
{
	BOOL xf = NO;

	//Cross faction damage.

	double prevHP = aFoe.health;
	double fp = 
	[ aFoe receiveAttack: firePower
			from:_hero ];


}
#endif

- (void) stunTargets: (NSArray*) heroList
	  withChance: (double) stunChance
{
	for(Hero* foe in heroList )
	{
		if( foe.health > 0 )
		{
			[ self stun: foe chance: stunChance ];
		}
	}
}

- (void) slowTargets: (NSArray*) heroList
	  withChance: (double) slowChance
{
	for(Hero* foe in heroList )
	{
		if( foe.health > 0 )
		{
			[ self slow: foe chance: slowChance ];
		}
	}
}

- (void) drainTargets: (NSArray*) heroList
	   withChance: (double) drainChance
{
	for(Hero* foe in heroList )
	{
		if( foe.health > 0 )
		{
			[ self drain: foe chance: drainChance ];
		}
	}
}

- (void) attack
{
	// If it crits, all critted so let's decide here.
	_critical = drand48() * 100 < _hero.criticalChance ? YES : NO;

	// Obtails positions of opponents and define targets.
	_targets = [ self.hero.team.opponent
		membersAtPositions:[ self positionTargetsWithChances: NULL ]];

	// Initialize base action power
	_power = _hero.power;

	[ self.hero.team attackWithAction: self ];


#if 0
	double f = _hero.power;
	for(Hero* foe in _targets )
	{
		if( foe.health < 0 ) continue;

		double firePower =_critical ? f * 2 :
					  f + f * ( drand48()/2 - 0.25 );
		/* Prepare initial firepower and store it in foe's action
		 * so they may manipulate them */
		foe.action.power = firePower;

	}

	[ self.hero.team.opponent dealAction: self ];
#endif


}

- (void) prepareAttack: (Action*) anAction
{
}

- (void) prepareDamage: (Action*) anAction
{
}

- (void) finalizeDamage: (Action*) anAction
{
}

/* Random a power based on current power and critical status */
- (double) attackPowerTo: (Hero*)target
{
	double powerForTarget = _critical ? _power * 2 :
		_power + _power * ( drand48()/2 - 0.25 );

	if([_hero isCrossing: target ])
	{
		powerForTarget *= 1.25;
	}

	if( self.hero.isGreyWarden && target.isBlighted )
		powerForTarget *= 1.5;

	return powerForTarget;
}

- (void) grantPowerToAll: (double) gainPower
{
	for( Hero* member in self.hero.team.members )
	{
		[ self grantPower: gainPower
			       to: member ];
	}
}

- (void) grantPower: (double) power
		 to: (Hero*) aHero
{
	[ aHero applyPower: power ];
}

//FIXME it seems healing LC has X2 effects.

#if 0
- (void) healHero: (Hero*) aHero
	       by: (double) health
{
	if( aHero.isGiant ) health *= 2.0; //FIXME verify

	[ aHero applyHealth: health
		     byHero: self.hero ];
}
#endif

- (void) bloodMageGain: (Action*) anAttack
{
	double sum = 0;

	/* Verify: Blood mage also gains when team member do self-inflict damage, self damaging hero must add itself to action.targets. */
	for(Hero* hero in anAttack.targets )
	{
		if( hero.team == self.hero.team )
		{
			sum += hero.action.power;
		}
	}

	if( sum == 0 ) return;

	[ self.hero applyPower: -sum * 0.2 ];
}

/* FIXME What if opponent die in the process of killing the healer ?*/
/* FIXME I don't really know how this work */
- (void) healWhenOpponentsDied: (Action*) anAttack
{
	double sum = 0;

	for(Hero* hero in anAttack.targets )
	{
		if( hero.team != self.hero.team && hero.isDead )
		{
			/* Applying current hero's power, I think */
			sum += anAttack.hero.action.power;
		}
	}

	//FIXME I don't really know, I just made this 0.50 up
	if( sum != 0 )
		[ self.hero applyHealth: sum * 0.50
				 byHero: anAttack.hero ];
}

@end

@implementation DoubleAction

- (void) grantPower: (double) power
		 to: (Hero*) aHero
{
	/* According to JSA, LC seems to also gain 2X
	 * from a giving row/column hitter.
	 */
	if( aHero.isGiant ) power *= 2.0;

	[ aHero applyPower: power ];
}

- (double) attackPowerTo: (Hero*)target
{
	if( target.isGiant ) return 2 * [ super attackPowerTo: target ];
	return [ super attackPowerTo: target ];
}

@end

@implementation ColAction

- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances
{
	Positions p = [ super positionTargetsWithChances: posChances ];

	if( p & POS_L ) return POS_L;

	if( p & POS_R ) return POS_R;

	return p & [ self.hero.team.opponent positionsNeedsAlive: YES ];
}

@end

@implementation RowAction

- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances
{
	Positions p = [ super positionTargetsWithChances: posChances ];

	if( p & POS_F ) return POS_F;

	if( p & POS_B ) return POS_B;

	return p & [ self.hero.team.opponent positionsNeedsAlive: YES ];
}

@end

@implementation AoEAction

- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances
{
	return POS_ALL & [ self.hero.team.opponent positionsNeedsAlive: YES ];
}

@end

@implementation Hero
@synthesize name = _name;

- (NSString*) description
{
	return [ NSString stringWithFormat:@"%@ %.1f/%.1f:p %.1f/%.1f:h%@%@",
	       self.name,
	       self.power, self.base_power,
	       self.health, self.base_health,
	       self.slowness ? @" (Slow)":@"",
	       self.isStunned ? @" (Stunned)":@""
	       ];
}

+ (id) summon: (NSString*) aName
{
	NSArray* data = [ HeroTemplate templateFor: aName ];

	Rarity r = RARITY_COMMON;

	for(NSString* groupName in [ data[DATA_GROUPS] componentsSeparatedByString:@","])
	{
		if([ groupName isEqualToString:@"common" ])
		{
			r = RARITY_COMMON;
		}
		else if([ groupName isEqualToString:@"uncommon" ])
		{
			r = RARITY_UNCOMMON;
		}
		else if([ groupName isEqualToString:@"rare" ])
		{
			r = RARITY_RARE;
		}
		else if([ groupName isEqualToString:@"epic" ])
		{
			r = RARITY_EPIC;
		}
		else if([ groupName isEqualToString:@"leg" ])
		{
			r = RARITY_LEGENDARY;
		}
		else if([ groupName isEqualToString:@"legendary" ])
		{
			r = RARITY_LEGENDARY;
		}
	}

	return [ self summonHeroWithPower:[ data[DATA_POWER] doubleValue ]
				   health:[ data[DATA_HEALTH] doubleValue ]
			   criticalChance:[ data[DATA_CRIT] doubleValue ]
				   action:[ data[DATA_ACTIONS] new ]
				     name: aName
				   rarity: r
				    group: data[DATA_GROUPS] ];
}

static NSMutableSet* hero_props = nil;

+ (id) summonHeroWithPower: (double) newPower
		    health: (double) newHealth
	    criticalChance: (double) newCritChance
		    action: (Action*) newAction
		      name: (NSString*) newName
		    rarity: (Rarity) rarity
		     group: (NSString*) groups
{
	Hero* hero = [ self new ];

	hero.rarity = rarity;
	hero.base_power = newPower;
	hero.base_health = newHealth;
	hero.criticalChance = newCritChance;
	hero.speed = SPEED_NORMAL;
	hero.action = newAction;
	newAction.hero = hero;
	hero.name = newName;

	if( hero_props == nil )
	{
		hero_props = [ NSMutableSet set ];
		unsigned n;
		objc_property_t* props = class_copyPropertyList([hero class], &n);

		for(int i = 0; i < n; i++ )
		{
			objc_property_t p = props[i];
			[ hero_props addObject:[ NSString stringWithCString:property_getName(p) ]];
		}

		free(props);
	}

	for(NSString* groupName in [ groups componentsSeparatedByString:@","])
	{
		if([ groupName isEqualToString:@"slow" ])
		{
			hero.speed = SPEED_SLOW;
		}
		else if([ groupName isEqualToString:@"normal" ])
		{
			hero.speed = SPEED_NORMAL;
		}
		else if([ groupName isEqualToString:@"quick" ] || [ groupName isEqualToString:@"fast" ])
		{
			hero.speed = SPEED_FAST;
		}
		else if([ hero_props containsObject: groupName ])
		{
			[ hero setValue:[ NSNumber numberWithBool: YES ] forKey: groupName ];
		}
	}

	return hero;
}

- (BOOL) isAlly: (Hero*) aHero
{
	return self.team == aHero.team;
}

- (BOOL) isCrossing: (Hero*) aHero
{
	return ( self.isBlack && aHero.isWhite ) ||
	       ( self.isBlue && aHero.isBlack ) ||
	       ( self.isRed && aHero.isBlue ) ||
	       ( self.isWhite && aHero.isRed );
}

- (void) refresh
{
	_power = _base_power;
	_health = _base_health;
	_slowness = 0;
	_stunned = NO;
}


- (void) fire
{
	//Resetting the initial damage dealts
	for(Hero* hero in self.team.field.members )
	{
		hero.action.power = 0;
	}

	if(_health > 0 && _stunned )
	{
		if( do_battle_log )
		{
			NSLog(@"((STUNNED)) %@", self.name );
		}
	}
	else if(_health > 0 ) [_action attack ];

	_stunned = NO;
	_slowness = 0;
}

- (BOOL) makeStunned
{
	if( _health < 0 ) return NO;
	if( drand48() > self.stunResistance )
	{
		_stunned = YES;
		return YES;
	}

	return NO;
}

- (BOOL) makeSlower
{
	if( _health < 0 ) return NO;
	if( drand48() > self.slowResistance )
	{
		_slowness ++;
		return YES;
	}

	return NO;
}

- (BOOL) isDead
{
	return _health <= 0;
}

- (void) applyHealth: (double) addHealth
	      byHero: (Hero*) aHero
{
	if( _health <= 0 ) return;
	if( addHealth == 0 ) return;

	double orgHealth = _health;

	_health += addHealth;

	if(_health > _base_health) _health = _base_health;
	if(_health < 0 ) _health = 0;

	if( do_battle_log && _health != orgHealth )
		NSLog(@".... %@%.1f:h %@%@ [%.1f → %@]:h",
				addHealth > 0 ? @"+":@"-",
				fabs(addHealth),
				[ aHero isCrossing: self ] ? @"XF ":@"",
				self.name,
				orgHealth,
				_health == 0 ? @"Killed" : [ NSString stringWithFormat:@"%.1f", _health ]);
}

- (void) applyPower: (double) addPower
{
	if( _health <= 0 ) return;
	if( addPower == 0 ) return;

	double minPower = _base_power * 0.1;
	if( self.power == minPower ) return;

	double orgPower = _power;

	_power += addPower;

	if(_power < minPower )
	{
		_power = minPower;
	}

	if( do_battle_log && _power != orgPower )
		NSLog(@".... %@%.1f:p %@ [%.1f → %.1f]:p",
				addPower > 0 ? @"+":@"-",
				fabs(addPower),
				self.name,
				orgPower,
				_power);
}

/*
receiveDrain:
	from:
	*/
- (double) drainedWithPower: (double) drainPower
{
	drainPower *= (1 - self.drainResistance);
	if( drainPower < 0 ) return 0.0;

	[ self applyPower: drainPower ];

	return drainPower;
}

- (Location) location
{
	if(_team ) return [_team.layout indexOfObject: self ];
	return LOC_NONE;
}


- (void) setName: (NSString*) aString
{
	_name = aString;
}

- (NSString*) name
{
	return [ NSString stringWithFormat:@"%@:%@ %@",
	       _team == _team.field.teams[0]?@"1":@"2",
	       @[@"LC",@"FL",@"FR",@"BL",@"BR",@"  "][self.location],_name ];
}

@end



// character-specific implementations


@implementation Action_Dan

- (void) finalizeDamage: (Action*) anAction
{
	[ self bloodMageGain: anAction ];
}

@end

@implementation Action_DD

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_MODERATE ];
}

@end

@implementation Action_GEF

- (void) attack
{
	[ super attack ];
	[ self slowTargets: self.targets
		withChance: CHANCE_FULL ];
}

@end

@implementation Action_KM

- (void) attack
{
	[ super attack ];

	[ self grantPowerToAll: self.hero.power * 0.5 ];
}

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isElf) return aHero.base_power * 0.25;
	else return 0;
}

@end

@implementation Action_Merrill
- (void) attack
{
	[ super attack ];
	[ self drainTargets: self.targets
		 withChance: CHANCE_FULL ];
}

- (double) healthGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isElf) return aHero.base_health * 0.35;
	else return 0;
}

- (double) stunResistanceGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isElf ) return 0.15;
	return 0;
}
@end

@implementation Action_Izzy

- (double) stunResistanceGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isOutlaw ) return 0.15;
	return 0;
}
@end

@implementation Action_AJ

- (void) attack
{
	//FIXME not sure where healing power is coming from. looks like a reroll
	[ super attack ];
	double power = self.power;

	power = power + power * ( drand48()/2 - 0.25 );

	[ self.hero applyHealth: power
			 byHero: self.hero ];
}

- (void) finalizeDamage: (Action*) anAction
{
	[ self bloodMageGain: anAction ];
}

- (void) prepareDamage: (Action*) anAction
{
	if([ anAction.targets containsObject: self.hero ] && anAction.hero.isBlack )
	{
		if(do_battle_log) NSLog(@"AJ reduce black damage ");
		self.power *= 0.9;
	}
}


@end

@implementation Action_Morrigan

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_SMALL ];
}

- (double) healthGainFor: (Hero*)aHero
{
	if([ self.hero isAlly: aHero ]) return aHero.base_health * 0.35;
	else return 0;
}

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isApostate) return aHero.base_power * 0.35;
	else return 0;
}

- (void) finalizeDamage: (Action*) anAction
{
	[ self healWhenOpponentsDied: anAction ];
}

@end

@implementation Action_Hybris

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_SMALL ];
}

@end

@implementation Action_Leliana
- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isChantry) return aHero.base_power * 0.50;
	else return 0;
}

- (void) attack
{
	[ super attack ];
	[ self slowTargets: self.targets
		withChance: CHANCE_FULL ];
}

@end

@implementation Action_Sigrun

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isDwarf) return aHero.base_power * 0.50;
	else return 0;
}

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_SMALL ];
	[ self.hero applyPower: self.hero.power / 2.0 ];
}

@end

@implementation Action_Uldred

- (void) finalizeDamage: (Action*) anAction
{
	[ self bloodMageGain: anAction ];
}

- (double) drainResistanceGainFor: (Hero*)aHero
{
	if( aHero == self.hero ) return 1.0;
	return 0.0;
}
@end


@implementation Action_VT

- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances;
{
	double chances[] = { 0.1, 0.1, 0.1, 1.0, 1.0 };
	return [ super positionTargetsWithChances: chances ];
}

- (void) attack
{
	[ super attack ];
	[ self grantPowerToAll: self.hero.power * 0.25 ];
}

@end

@implementation Action_WF

- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances;
{
	double chances[] = { 0.1, 0.1, 0.1, 1.0, 1.0 };
	return [ super positionTargetsWithChances: chances ];
}

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_HIGH ];
}

- (double) powerGainFor: (Hero*)aHero
{
	if([ self.hero isAlly: aHero ] && ( aHero.isSpirit || aHero.isCreature)) return aHero.base_power * 0.50;
	else return 0;
}
@end


@implementation Action_AD

- (double) healthGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isBlighted ) return aHero.base_health * 0.35;
	else return 0;
}

//FIXME ally take 10% less damage
- (void) attack
{
	[ super attack ];
	[ self drainTargets: self.hero.team.opponent.members
		 withChance: CHANCE_MODERATE ];
}

@end

@implementation Action_Archy

- (double) healthGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isBlighted ) return aHero.base_health * 0.50;
	else return 0;
}

- (void) attack
{
	//FIXME not sure where healing power is coming from. looks like a reroll
	[ super attack ];
	double power = self.power;

	power = power + power * ( drand48()/2 - 0.25 );

	[ self.hero applyHealth: power
			 byHero: self.hero ];
}

@end

@implementation Action_BM

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_MODERATE ];
}

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isBlighted ) return aHero.base_power * 0.35;
	else return 0;
}

- (double) healthGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isBlighted ) return aHero.base_health * 0.35;
	else return 0;
}

- (double) drainResistanceGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team ) return 0.50;
	return 0.0;
}

@end

@implementation Action_CSQ

- (void) attack
{
	[ super attack ];
	[ self drainTargets: self.targets
		 withChance: CHANCE_FULL ];
}

- (double) drainResistanceGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isBlighted ) return 0.50;
	return 0.0;
}

@end


@implementation Action_DF
- (double) powerGainFor: (Hero*)aHero
{
	if([ self.hero isAlly: aHero ]) return aHero.base_power * 0.35;
	else return 0;
}
@end

@implementation Action_HO

- (double) healthGainFor: (Hero*)aHero
{
	if([ self.hero isAlly: aHero ] && aHero.isBloodMage ) return aHero.base_health * 0.50;
	else return 0;
}

- (void) attack
{
	[ super attack ];
	[ self slowTargets: self.targets
		withChance: CHANCE_FULL ];
}

@end

@implementation Action_VA

- (double) healthGainFor: (Hero*)aHero
{
	if([ self.hero isAlly: aHero ] && aHero.isMage ) return aHero.base_health * 0.50;
	else return 0;
}

@end

@implementation Action_Vart

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isElf) return aHero.base_power * 0.50;
	else return 0;
}

- (double) stunResistanceGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team ) return 0.15;
	return 0;
}

@end

@implementation Action_GWB

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isApostate ) return aHero.base_power * 0.50;
	else return 0;
}

- (double) attackPowerTo: (Hero*)target
{
	return [ super attackPowerTo: target ];
}

@end

@implementation Action_GWC

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_SMALL ];
}

- (void) prepareDamage: (Action*) anAction
{
	[ super prepareDamage: anAction ];

	/* Testing Absorb */
	for(Hero* hero in anAction.targets )
	{
		if([ self.hero isAlly: hero ])
		{
			self.action.power += hero.action.power / 2.0;
			hero.action.power /= 2.0;
		}
	}
}

@end

@implementation Action_TF

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isBlighted ) return aHero.base_power * 0.50;
	else return 0;
}

//FIXME ally take 10% less damage
- (void) attack
{
	[ super attack ];
	[ self drainTargets: self.targets
		 withChance: CHANCE_FULL ];
	[ self.hero applyPower: self.hero.power * 0.75 ];
}

@end


@implementation Action_Velanna

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isElf ) return aHero.base_power * 0.25;
	else return 0;
}

- (double) healthGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isElf ) return aHero.base_power * 0.25;
	else return 0;
}

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_SMALL ];
}

@end

@implementation Action_Zathrian
- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isElf ) return aHero.base_power * 0.50;
	else return 0;
}

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_SMALL ];
	[ self slowTargets: self.targets
		withChance: CHANCE_FULL ];
}

@end

