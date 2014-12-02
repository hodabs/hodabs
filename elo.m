#include "player.h"
#include <sqlite3.h>

#define MAX_INCREASE 32
#define INITIAL_SCORE 1500
#define AVERAGE_FACTOR 2.0

NYI
{
	NSMutableArray* teamList = [ NSMutableArray array ];

	/* Build team list */
	{
		Team* aTeam = [ Team new ];
		[ teamList addObject: aTeam ];
	}


	Team* teamA = nil,
	    * teamB = nil;

	[ teamList sortUsingComparator:
		^( Team* teamA, Team* teamB )
		{
			if( teamA.score > teamB.score )
				return NSOrderedAscending;

			if( teamB.score > teamA.score )
				return NSOrderedDescending;

			return NSOrderedSame;
		}
	];

	while ( 1 )
	{

		//teamA = something; //random A team
		//teamB = something; //random B team

		int winner = 0;

		//Matching

		if( winner == 0 ) continue;

		//Scoring
		double e0, e1;

		e0 = MAX_INCREASE / ( 1.0 + pow( 10 , ( teamB.score - teamA.score ) / 400 ));
		e1 = MAX_INCREASE / ( 1.0 + pow( 10 , ( teamA.score - teamB.score ) / 400 ));

		teamA.match++;
		teamB.match++;



		if( winner == 1 )
		{
			teamA.win ++;
			teamA.score += e1;
			teamB.score -= e1;

			if( teamB.winner == nil ) teamB.winner = [ NSMutableSet set ];
			[ teamB.winner addObject: teamA ];
			NSLog(@"%.1f", e1);
		}
		else
		{
			teamB.win ++;
			teamA.score -= e0;
			teamB.score += e0;

			if( teamA.winner == nil ) teamA.winner = [ NSMutableSet set ];
			[ teamA.winner addObject: teamB ];
			NSLog(@"%.1f", e0);
		}

		[ teamList sortUsingComparator:
			^( Team* mA, Team* mB )
			{
				if( mA.score > mB.score )
					return NSOrderedAscending;

				if( mB.score > mA.score )
					return NSOrderedDescending;
				
				return NSOrderedSame;
			}
		];


	}

}

