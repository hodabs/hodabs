#import <Foundation/Foundation.h>
#define MAXMEMBERS 10

//statistic
#define RUNS 1
#define ROUNDLOG

#define MAX_UNIT 5
extern BOOL do_battle_log;
@interface BLog : NSObject
+ (void) format: (NSString*) format, ...;
+ (void) setLog: (BOOL) onOff;
+ (NSUInteger) flush;
/*
+ (void) save;
+ (void) restore;
*/
@end

typedef enum : NSUInteger
{
	LOC_LC = 0,
	LOC_FL = 1,
	LOC_FR = 2,
	LOC_BL = 3,
	LOC_BR = 4,
	LOC_NONE = MAX_UNIT
} Location;

typedef enum : NSUInteger
{
	RARITY_COMMON = 1,
	RARITY_UNCOMMON = 2,
	RARITY_RARE = 3,
	RARITY_EPIC = 4,
	RARITY_LEGENDARY = 5
} Rarity;

typedef enum : NSUInteger
{
	POS_NONE = 0,
	POS_LC = 1 << LOC_LC,
	POS_FL = 1 << LOC_FL,
	POS_FR = 1 << LOC_FR,
	POS_BL = 1 << LOC_BL,
	POS_BR = 1 << LOC_BR,
	POS_F  = POS_FL | POS_FR,
	POS_B  = POS_BL | POS_BR,
	POS_L  = POS_FL | POS_BL,
	POS_R  = POS_FR | POS_BR,
	POS_ALL  = POS_F | POS_B | POS_LC,
} Positions;

typedef enum : NSUInteger
{
	SPEED_EXTRA_FAST = 0,
	SPEED_VERY_FAST = 1,
	SPEED_FAST = 2,
	SPEED_NORMAL = 3,
	SPEED_SLOW = 4,
	SPEED_VERY_SLOW = 5,
	SPEED_EXTRA_SLOW = 6
} Speed;

typedef enum : NSUInteger
{
	COLOR_BLACK = 0,
	COLOR_BLUE = 1,
	COLOR_RED = 2,
	COLOR_WHITE = 3,
	COLOR_GIANT = 4,
} Color;

typedef enum : NSUInteger
{
	FACT_BLACK = 1 << COLOR_BLACK,
	FACT_BLUE = 1 << COLOR_BLUE,
	FACT_RED = 1 << COLOR_RED,
	FACT_WHITE = 1 << COLOR_RED,
} Factions;

typedef enum : NSUInteger
{
	FORT_EPIC_LOW_HEALTH = 1,
	FORT_EPIC_MID_HEALTH = 2,
	FORT_EPIC_FULL_HEALTH = 3,
	FORT_LEG_LOW_HEALTH = 4,
	FORT_LEG_MID_HEALTH = 5,
	FORT_LEG_FULL_HEALTH = 6,

	FORT_EPIC_LOW_POWER = 0x10,
	FORT_EPIC_MID_POWER = 0x20,
	FORT_EPIC_FULL_POWER = 0x30,
	FORT_LEG_LOW_POWER = 0x40,
	FORT_LEG_MID_POWER = 0x50,
	FORT_LEG_FULL_POWER = 0x60,

	FORT_EPIC_LOW = FORT_EPIC_LOW_HEALTH | FORT_EPIC_LOW_POWER,
	FORT_EPIC_MID = FORT_EPIC_MID_HEALTH | FORT_EPIC_MID_POWER,
	FORT_EPIC_FULL = FORT_EPIC_FULL_HEALTH | FORT_EPIC_FULL_POWER,
	FORT_LEG_LOW = FORT_LEG_LOW_HEALTH | FORT_LEG_LOW_POWER,
	FORT_LEG_MID = FORT_LEG_MID_HEALTH | FORT_LEG_MID_POWER,
	FORT_LEG_FULL = FORT_LEG_FULL_HEALTH | FORT_LEG_FULL_POWER,

} Fortifications;


@class Hero;
@class Team;
@class Field;
@class Action;

#define NOHERO ((Hero*)[ NSNull null ])

#define CHANCE_LC 1.0
#define CHANCE_FR 1.0
#define CHANCE_FL 1.0
#define CHANCE_BR 0.1
#define CHANCE_BL 0.1

@interface Field : NSObject
{
	Team* _team1;
	Team* _team2;
	BOOL _isPrepared;

//statistics
	double _damageBy1;
	double _damageBy2;
}


@property (readonly) NSArray* teams;
@property (readonly) NSArray* members;
@property (readonly) NSUInteger round;

- (NSUInteger) run;
- (NSUInteger) _runRound;
- (void) _prepareHeroes;
- (id) initWithTeams: (Team*) team1 : (Team*) team2;
- (void) dealAction: (Action*) anAction;

@end

@interface Team : NSObject
@property NSMutableArray* layout;
@property (readonly) NSArray* members;
@property (weak) Field* field;
@property (readonly) Team* opponent;
@property (readonly) NSUInteger index;

//statistics
@property double roundDamage;

//handy
- (id) objectAtIndexedSubscript: (NSUInteger) idx;
- (void)         setObject: (id) anObject
	atIndexedSubscript: (NSUInteger) idx;
- (NSArray*) membersAtPositions: (Positions) pos;

//battle
- (void) attackWithAction: (Action*) anAction;

- (Positions) positionsNeedsAlive: (BOOL) needAlive;
@end

@interface Hero : NSObject
@property NSString* name;
@property Rarity rarity;
@property double power;
@property double base_power;
@property double health;
@property double base_health;
@property double criticalChance;

@property double curseResistance;
@property double drainResistance;
@property double stunResistance;
@property double slowResistance;

@property Action* action;
@property (weak) Team* team;
@property (readonly) Location location;

@property NSUInteger speed;
@property double order;
@property NSUInteger slowness;
@property (getter=isStunned) BOOL stunned;
@property (getter=isCursed) BOOL cursed;

@property (readonly) BOOL isDead;

/* Factions */
@property (getter=isRed)        BOOL red;
@property (getter=isBlack)      BOOL black;
@property (getter=isBlue)       BOOL blue;
@property (getter=isWhite)      BOOL white;
@property (getter=isGiant)      BOOL giant;
/* Group */
@property (getter=isApostate)   BOOL apostate;
@property (getter=isBlighted)   BOOL blighted;
@property (getter=isBloodMage)  BOOL bloodMage;
@property (getter=isChantry)    BOOL chantry;
@property (getter=isCircle)     BOOL circle;
@property (getter=isCreature)   BOOL creature;
@property (getter=isDemonic)    BOOL demonic;
@property (getter=isDwarf)      BOOL dwarf;
@property (getter=isElf)        BOOL elf;
@property (getter=isFerelden)   BOOL ferelden;
@property (getter=isGolem)      BOOL golem;
@property (getter=isGreyWarden) BOOL greyWarden;
@property (getter=isMage)       BOOL mage;
@property (getter=isNobility)   BOOL nobility;
@property (getter=isOrlesian)   BOOL orlesian;
@property (getter=isOutlaw)     BOOL outlaw;
@property (getter=isQunari)     BOOL qunari;
@property (getter=isRogue)      BOOL rogue;
@property (getter=isSpirit)     BOOL spirit;
@property (getter=isTemplar)    BOOL templar;
@property (getter=isTevinter)   BOOL tevinter;
@property (getter=isWarrior)    BOOL warrior;


+ (id) summon: (NSString*) aName;
+ (id) summonHeroWithPower: (double) newPower
		    health: (double) newHealth
	    criticalChance: (double) newCritPercent
		    action: (Action*) newAction
		      name: (NSString*) newName
		    rarity: (Rarity) rarity
		     group: (NSString*) groups;

- (BOOL) isAlly: (Hero*) aHero;
- (BOOL) isCrossing: (Hero*) aHero;

- (void) fire;
- (BOOL) makeSlower; //FIXME define degree of slowness
- (BOOL) makeStunned;
- (BOOL) makeCursed;
- (double) drainedWithPower: (double) drainPower;
- (void) refresh;
- (void) applyPower: (double) addPower; //Minus to drain
- (void) applyHealth: (double) addHealth //Minus to damage
	      byHero: (Hero*) aHero;

@end

/* Template datas */
#define DATA_POWER 0
#define DATA_HEALTH 1
#define DATA_CRIT 2
#define DATA_ACTIONS 3
#define DATA_GROUPS 4

@interface HeroTemplate : NSObject
+ (NSArray*) templateFor: (NSString*) heroName;
+ (void) append: (NSDictionary*) myHeros;
@end

