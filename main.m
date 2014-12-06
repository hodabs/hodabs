#import "hodabs.h"

BOOL do_battle_log = NO;

#define CL(x) NSClassFromString(@#x)
#define ACT(NAME)  [ CL(Action_ ## NAME) class ]

int main(int argc, const char * argv[])
{@autoreleasepool{
	srand48(time(NULL));
//	srand48(1);

	[ HeroTemplate append:
@{
@"MyMorrigan" :		@[@3486 , @8573, @25, ACT(Morrigan), @"leg,red,slow,apostate,mage" ],
@"MyJowan" :		@[@3702, @14232, @25, ACT(AJ), @"leg,red,black,slow,apostate,bloodMage,mage" ],
@"MyUldred" :		@[@(3702), @(20396), @25, ACT(Uldred), @"leg,slow,blue,black,mage,bloodMage" ],
@"MyGEF" :		@[@(887 + 887), @(2354 + 0), @25, ACT(GEF), @"leg,normal,blue,white,circle,elf,mage" ],
@"MyKM" :		@[@(1051 + 0), @(2936 + 0), @25, ACT(KM), @"leg,normal,blue,circle,elf,mage" ],
@"MyGWB" :		@[@(1000), @(1691 + 0), @25, ACT(GWB), @"epic,normal,black,blue,ferelden,mage,greyWarden" ],
@"MyMer" :		@[@(1135), @(2208 + 0), @25, CL(AoEAction), @"leg,normal,black,blue,apostate,mage,bloodMage" ],
@"MyVT" :		@[@(2180 + 0), @(2643 + 0), @25,ACT(VT), @"leg,fast,red,white,dwarf,outlaw,rogue" ],
}];

	Field* battle_field = [ Field new ];

	int run = 1;

	for(int i = 1; i < argc; i++ )
	{
		if( 0 == strcmp( argv[i], "log" ))
		{
			do_battle_log = YES;
		}
		else if( 0 == strncmp( argv[i], "run:", 4 ))
		{
			run = atoi( &argv[i][4] );
		}
	}

	//Use NOHERO as empty slot.
	NSArray* hero_list = @[
		@[ // Team A

//			[ Hero summon:@"Hybris" ],
//			[ Hero summon:@"Varterral" ],
			[ Hero summon:@"Dragon Flemeth" ],
//			[ Hero summon:@"Harvester Orsino" ],
//			[ Hero summon:@"Varterral" ],
//			NOHERO,

//			[ Hero summon:@"Ancient Darkspawn" ],
//			[ Hero summon:@"Ancient Darkspawn" ],
//			[ Hero summon:@"Ancient Darkspawn" ],
//			[ Hero summon:@"Ancient Darkspawn" ],
//			[ Hero summon:@"Grand Enchanter Fiona" ],
//			[ Hero summon:@"Desire Demon" ],
//			[ Hero summon:@"Desire Demon" ],
//			[ Hero summon:@"Grey Warden Bethany" ],
//			[ Hero summon:@"Isabela" ],
//			[ Hero summon:@"Apostate Jowan" ],
//			[ Hero summon:@"Apostate Jowan" ],
//			[ Hero summon:@"Danarius" ],
//			[ Hero summon:@"Morrigan" ],
//			[ Hero summon:@"Desire Demon" ],
//			[ Hero summon:@"Velanna" ],
//			[ Hero summon:@"Apostate Jowan" ],
//			[ Hero summon:@"Apostate Jowan" ],
//			[ Hero summon:@"Morrigan" ],
//			[ Hero summon:@"Morrigan" ],
			[ Hero summon:@"MyJowan" ],
			[ Hero summon:@"MyMorrigan" ],
			[ Hero summon:@"MyMorrigan" ],
			[ Hero summon:@"MyMorrigan" ],
//			[ Hero summon:@"Morrigan" ],
//			[ Hero summon:@"Morrigan" ],
//			[ Hero summon:@"Morrigan" ],
//			[ Hero summon:@"Keeper Marethari" ],
//			[ Hero summon:@"Keeper Marethari" ],
//			[ Hero summon:@"Keeper Marethari" ],
//			[ Hero summon:@"Keeper Marethari" ],
//			[ Hero summon:@"Leliana" ],
//			[ Hero summon:@"Morrigan" ],
//			[ Hero summon:@"Sigrun" ],
//			[ Hero summon:@"Varric Tethras" ],
//			[ Hero summon:@"Zathrian" ],

//			[ Hero summon:@"MyGEF" ],
//			[ Hero summon:@"MyKM" ],
//			[ Hero summon:@"MyMer" ],
//			[ Hero summon:@"MyVT" ],
		],
		@[ // Team B
//			[ Hero summon:@"Varterral" ],
//			NOHERO,
//			[ Hero summon:@"Uldred" ],
//			[ Hero summon:@"The Architect" ],

#if 0
			[ Hero summon:@"Dragon Flemeth" ],
			[ Hero summon:@"Witherfang" ],
			[ Hero summon:@"Witherfang" ],
			[ Hero summon:@"Witherfang" ],
			[ Hero summon:@"Witherfang" ],
#endif
#if 1
			[ Hero summon:@"Harvester Orsino" ],
			[ Hero summon:@"MyUldred" ],
			[ Hero summon:@"Vengeance Anders" ],
			[ Hero summon:@"Vengeance Anders" ],
			[ Hero summon:@"Vengeance Anders" ],
#endif

		],
		];

	for(int t = 0; t < 2; t++)
	for(int i = 0; i < 5; i++)
	{
		Team* team = battle_field.teams[t];
		team[i] = hero_list[t][i];
	}


//Speed rune test
#if 0
	for(int i = 0; i < 5; i++)
	{
		Team* team = battle_field.teams[1];
		Hero* h = team[i];
		if( h != NOHERO )
			h.speed -= 2;
	}
#endif

	int ab[2] = {0,0};
	for(int i = 0; i < run; i++)
	{
		ab[[ battle_field run ]]++;
		if( do_battle_log )
			NSLog(@"___________________________________________________");
	}

	NSLog(@"Winning: A:%.0f%% vs B:%.0f%%",
			100*ab[0]/(double)run,
			100*ab[1]/(double)run
		);

	return 0;
}}
