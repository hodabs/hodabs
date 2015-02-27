/* Copyright WTFPL 2.0 All rights reserved to be given away */
/* http://forums.capitalgames.com/showthread.php/71800-Battle-Simulator */
#import "actions.h"

// add characters here

#define CHANCE_MODERATE 0.5
#define CHANCE_SMALL 0.25
#define CHANCE_HIGH 0.75
#define CHANCE_FULL 1.0

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

- (double) curseResistanceGainFor: (Hero*)aHero
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
	if( drand48() > chance ) return NO;

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

- (void) curseTargets: (NSArray*) heroList
	   withChance: (double) curseChance
{
	for(Hero* foe in heroList )
	{
		if( foe.health > 0 )
		{
			[ foe makeCursed ];
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
	// It seems that AoE attack based on single value so let's calculate it here.
	_power = _hero.power;
	_power *= _critical ? 2 : 1 + ( drand48()/2 - 0.25 );

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

- (void) prepareDamage: (Action*) anAction
{
}

- (void) applyDamage: (Action*) anAction
{
}

- (void) finalizeDamage: (Action*) anAction
{
}

/* Random a power based on current power and critical status */
- (double) attackPower: (double) power
		    by: (Hero*) attacker
{
	return power;
}

- (double) attackPowerTo: (Hero*)target
{
	double powerForTarget = _power;

	if([_hero isCrossing: target ])
	{
		powerForTarget *= 1.25;
	}

	if( self.hero.isGreyWarden && target.isBlighted )
		powerForTarget *= 1.5;

	return [ target.action attackPower: powerForTarget
					by: self.hero ];
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

@implementation MultipleAction
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

- (BOOL) makeCursed
{
	if( _health < 0 ) return NO;

	if( drand48() > self.curseResistance )
	{
		_power = _base_power;
		_cursed = YES;
		return YES;
	}

	return YES;
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

- (void) attack
{
	[ super attack ];
	[ self slowTargets: self.targets
		withChance: CHANCE_SMALL ];
}

- (void) finalizeDamage: (Action*) anAction
{
	[ self bloodMageGain: anAction ];
}

- (double) stunResistanceGainFor: (Hero*)aHero
{
	if( aHero == self.hero )
		return 1.0;
	return 0.0;
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

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isCircle) return aHero.base_power * 0.35;
	else return 0;
}

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

- (void) prepareDamage: (Action*) anAction
{
	for(Hero* hero in anAction.targets )
	{
		if([ self.hero isAlly: hero ] && hero.isElf )
		{
			hero.action.power *= 0.9;
		}
	}
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

- (double) attackPower: (double) power
		    by: (Hero*) attacker
{
	if( attacker.isBlack )
	{
		if(do_battle_log) NSLog(@".... AJ is reducing black damage ");
		power *= 0.9;
	}

	return power;
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
	BOOL isDef = NO;

	for(Hero* hero in anAction.targets )
	{
		if([ self.hero isAlly: hero ] && self.hero != hero )
		{
			double prevPower = self.power;

			self.power += hero.action.power / 2.0;
			hero.action.power /= 2.0;
			if( do_battle_log )
			{
				if( isDef == NO )
				{
					NSLog(@".... %@ is defending.", self.hero.name);
					isDef = YES;
				}
				NSLog(@"...... %@ [%.1f → %.1f]:p", hero.name, prevPower, self.power);
			}
		}
	}
}

- (void) applyDamage: (Action*) anAction
{
	for(Hero* hero in anAction.targets )
	{
		if([ self.hero isAlly: hero ])
		{
			self.power += hero.action.power / 2.0;
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

@implementation Action_Tallis
- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isQunari ) return aHero.base_power * 0.50;
	else return 0;
}

- (void) attack
{
	[ super attack ];
	[ self stunTargets: self.targets
		withChance: CHANCE_SMALL ];
}
@end

@implementation Action_GWS
- (void) attack
{
	[ super attack ];
	[ self curseTargets: self.targets
		 withChance: CHANCE_FULL ];
}

- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances;
{
	double chances[] = { 0.1, 0.1, 0.1, 1.0, 1.0 };
	return [ super positionTargetsWithChances: chances ];
}

@end

@implementation Action_WCD

- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isRogue) return aHero.base_power * 0.25;
	else return 0;
}

- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances;
{
	double chances[] = { 0.1, 0.1, 0.1, 1.0, 1.0 };
	return [ super positionTargetsWithChances: chances ];
}

//Gain power

@end

@implementation Action_EH
- (double) powerGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && ( aHero.isRogue || aHero.isOrlesian )) return aHero.base_power * 0.25;
	else return 0;
}

//> ferelden + qunari
@end

@implementation Action_CZ

- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances;
{
	double chances[] = { 0.1, 0.1, 0.1, 1.0, 1.0 };
	return [ super positionTargetsWithChances: chances ];
}

- (void) attack
{
	[ super attack ];
	//FIXME drain a lot
	[ self drainTargets: self.targets
		 withChance: CHANCE_FULL ];
	[ self drainTargets: self.targets
		 withChance: CHANCE_FULL ];
}
@end

@implementation Action_Phoenix

- (double) healthGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team ) return aHero.base_health * 0.20;
	else return 0;
}

- (double) stunResistanceGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team ) return 0.15;
	return 0;
}

- (void) attack
{
	//FIXME not sure where healing power is coming from. looks like a reroll
	[ super attack ];

	[ self.hero applyHealth: self.power
			 byHero: self.hero ];
}

@end

@implementation Action_Ben

- (double) healthGainFor: (Hero*)aHero
{
	if( self.hero.team == aHero.team && aHero.isQunari ) return aHero.base_health * 0.25;
	else return 0;
}

@end

