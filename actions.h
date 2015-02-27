#import "hodabs.h"

@interface Action : NSObject

@property double power; // Minus if being attacked. Plus if attacking.
@property (readonly) double roundPower;

@property Hero* hero;
@property (getter=isCritical) BOOL critical;
@property (readonly) NSArray* targets;


/* Random a power based on current power and critical status.
   Subclass may override to multiply factors to the initial power.

   For general targets eg. grey warden vs blighted or RLM vs mages.
 */
- (double) attackPowerTo: (Hero*)target;

/* called by -attackPowerTo:, a particular target may override to alter the final power.

   For specific target eg. mages vs RLM.
 */
- (double) attackPower: (double) power
		    by: (Hero*) attacker;

// Global notification. anyone may override this to alter the damaging power values.
- (void) prepareDamage: (Action*) anAttack;

/* Attack time notification, allow just in time unordered manipulations
 * of power values without any stack calculation. Mainly for defenders.
 */

- (void) applyDamage: (Action*) anAction;

// Global notification. anyone may override this to alter the damaging power values.
- (void) finalizeDamage: (Action*) anAttack;

- (void) bloodMageGain: (Action*) anAttack;
- (void) healWhenOpponentsDied: (Action*) anAttack;
////
#if 0
- (void) attack;
- (void) attack: (Hero*) aHero
	  power: (double) firePower
	 factor: (double) factor;
#endif

// Battle

- (void) attack;

// Round time extras
- (void) slowTargets: (NSArray*) heroList
	  withChance: (double) slowChance;
- (void) stunTargets: (NSArray*) heroList
	  withChance: (double) stunChance;
- (void) drainTargets: (NSArray*) heroList
	   withChance: (double) drainChance;

- (BOOL) slow: (Hero*) anEnemy
       chance: (double) chance;
- (BOOL) stun: (Hero*) anEnemy
       chance: (double) chance;
- (double) drain: (Hero*) anEnemy
	  chance: (double) chance;

- (void) grantPower: (double) gainPower
		 to: (Hero*) aHero;
- (void) grantPowerToAll: (double) gainPower;
/*
- (void) healHero: (Hero*) aHero
	       by: (double) health;
	       */

/* Pick the origin of attack and for now, actions may override to do row, col or aoe */
- (Positions) positionTargetsWithChances: (const double[MAX_UNIT])posChances;

- (double) powerGainFor: (Hero*) aHero;
- (double) healthGainFor: (Hero*) aHero;

- (double) curseResistanceGainFor: (Hero*)aHero;
- (double) drainResistanceGainFor: (Hero*)aHero;
- (double) stunResistanceGainFor: (Hero*)aHero;
- (double) slowResistanceGainFor: (Hero*)aHero;

/*
- (double) defend: (Hero*) aHero
	    power: (double) power
	     from: (Hero*) hisFoe;

- (double) defend: (Hero*) aHero
	    drain: (double) power
	     from: (Hero*) hisFoe;
- (void) prepare;
	     */


/*
- (void) prepareAoE;
- (void) prepareRow;
- (void) prepareColumn;
*/
@end

@interface MultipleAction : Action @end
@interface AoEAction : MultipleAction @end
@interface DoubleAction : MultipleAction @end
@interface RowAction : DoubleAction @end
@interface ColAction : DoubleAction @end

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
@interface Action_Tallis : RowAction @end
@interface Action_GWS : RowAction @end
@interface Action_WCD : Action @end
@interface Action_EH : RowAction @end
@interface Action_CZ : RowAction @end
@interface Action_Phoenix : AoEAction @end
@interface Action_Ben : AoEAction @end
