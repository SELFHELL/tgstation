//gold slime core spawning (used with var/mob_spawnable_type)
/// Mob cannot be spawned with a gold slime core
#define NO_SPAWN 0
/// Mob can spawned with a gold slime core with plasma reaction as a hostile creature
#define HOSTILE_SPAWN 1
/// Mob can be spawned with a gold slime core with blood reaction as a friendly creature
#define FRIENDLY_SPAWN 2

//slime core activation type
/// Jelly species slime ability that causes simple effects that require energized jelly
#define SLIME_ACTIVATE_MINOR 1
/// Jelly species slime ability that causes complex effects that require plasma jelly
#define SLIME_ACTIVATE_MAJOR 2

/// Determines how much light the jelly species emit
#define LUMINESCENT_DEFAULT_GLOW 2

/// How much gases and chemicals can xenoflora pod contain
#define XENOFLORA_MAX_MOLES 3000
#define XENOFLORA_MAX_CHEMS 500
/// How much gases our pod injects per tick(so if plant needs 3 moles of CO2 per tick, pod will inject CO2 until there's 3 * XENOFLORA_POD_INPUT_MULTIPLIER moles)
#define XENOFLORA_POD_INPUT_MULTIPLIER 10

/// How big can a slime pen be
#define MAXIMUM_SLIME_PEN_SIZE 50

#define BLUESPACE_ANCHOR_RANGE 5
#define PYRITE_THROWER_COOLDOWN 5 SECONDS

/// Slime core prices

#define SLIME_VALUE_TIER_1 200
#define SLIME_VALUE_TIER_2 400
#define SLIME_VALUE_TIER_3 800
#define SLIME_VALUE_TIER_4 1600
#define SLIME_VALUE_TIER_5 3200
#define SLIME_VALUE_TIER_6 6400
#define SLIME_VALUE_TIER_7 12800

#define SLIME_SELL_MODIFIER_MIN 	  -0.03
#define SLIME_SELL_MODIFIER_MAX 	  -0.01
#define SLIME_SELL_OTHER_MODIFIER_MIN 0.002
#define SLIME_SELL_OTHER_MODIFIER_MAX 0.005
#define SLIME_SELL_MAXIMUM_MODIFIER   2
#define SLIME_SELL_MINIMUM_MODIFIER   0.25
#define SLIME_RANDOM_MODIFIER_MIN -0.0003
#define SLIME_RANDOM_MODIFIER_MAX 0.0003

#define SLIME_DISCHARGE_PROB 30
#define SLIME_DISCHARGE_EFFECT_PROB 65
#define SLIME_DISCHARGER_NUTRIMENT_DRAIN 3
#define SLIME_DISCHARGER_AGGRESSIVE_EFFECT 5

//Slime evolution threshold. Controls how fast slimes can split/grow
#define SLIME_EVOLUTION_THRESHOLD 10

//Slime digestion speed, in percents per delta tick
#define SLIME_DIGESTION_SPEED 2
//How much nutrition slime gets from eating something each second, per percent
#define SLIME_DIGESTION_NUTRITION 3

//Slime commands defines
#define SLIME_FRIENDSHIP_FOLLOW 3 //Min friendship to order it to follow
#define SLIME_FRIENDSHIP_STOPEAT 5 //Min friendship to order it to stop eating someone
#define SLIME_FRIENDSHIP_STOPEAT_NOANGRY 7 //Min friendship to order it to stop eating someone without it losing friendship
#define SLIME_FRIENDSHIP_STOPCHASE 4 //Min friendship to order it to stop chasing someone (their target)
#define SLIME_FRIENDSHIP_STOPCHASE_NOANGRY 6 //Min friendship to order it to stop chasing someone (their target) without it losing friendship
#define SLIME_FRIENDSHIP_STAY 3 //Min friendship to order it to stay
#define SLIME_FRIENDSHIP_ATTACK 8 //Min friendship to order it to attack

/// How many seconds it takes for slime to generate a core
#define SLIME_MAX_CORE_GENERATION 30

/// If slime requires high temperatures and a hotspot is located, damage will be multiplied by this
#define HOT_SLIME_HOTSPOT_DAMAGE_MODIFIER 0.35
/// How much warp chance is added per second when a bluespace connected slime is being anchored
#define SLIME_WARPCHANCE_INCREASE 1

/// How much one energy one power level produces
#define SLIME_POWER_LEVEL_ENERGY 2500000 //Around 10 slimes should be enough to power xenobio I think?

/// Damages per second when slimes' requirements are not satisfied
#define SLIME_DAMAGE_LOW  (150 / 300)  //5 minutes to die
#define SLIME_DAMAGE_MED  (150 / 240)  //4 minutes to die
#define SLIME_DAMAGE_HIGH (150 / 180)  //3 minutes to die

/// Additional damage for mobs from slime being an adult
#define SLIME_ADULT_DAMAGE_BOOST 10
/// Additional damage for objects from slime being an adult
#define SLIME_ADULT_OBJ_DAMAGE_BOOST 15

/// How likely it is for a slime to use a POI when it's bored, per second. Every POI is has it's own check that should average at 25%
#define SLIME_POI_INTERACT_CHANCE 15

/// How likely it is for a slime to vent when bored and there's a vent nearby
#define SLIME_VENTCRAWL_CHANCE 2

/// Maximum slime mood
#define SLIME_MOOD_MAXIMUM 100
#define SLIME_MOOD_PASSIVE_LEVEL 50
#define SLIME_MOOD_GAIN_MODIFIER 0.2
/// At what level do slimes become happy
#define SLIME_MOOD_LEVEL_HAPPY 75
/// At what level do slimes start pouting
#define SLIME_MOOD_LEVEL_POUT 40
/// At what level do slimes become sad
#define SLIME_MOOD_LEVEL_SAD 25

/// How likely it is for a slime to misbehave when it's pouting, per second
#define SLIME_MISBEHAVE_CHANCE_POUTING 0.5
/// How likely it is for a slime to misbehave when it's sad, per second
#define SLIME_MISBEHAVE_CHANCE_SAD 2
/// How likely it is for a slime to attack whatever it bumps into from bad mood
#define SLIME_MOOD_OBJ_ATTACK_CHANCE 30 //12% chance on default mood

#define SLIME_SHOULD_MISBEHAVE(slime, delta_time) (!slime.discipline && (slime.mood_level < SLIME_MOOD_LEVEL_POUT) && DT_PROB((slime.mood_level < SLIME_MOOD_LEVEL_SAD) ? SLIME_MISBEHAVE_CHANCE_SAD : SLIME_MISBEHAVE_CHANCE_POUTING, delta_time))

/// Tags for slime colors

/// These slimes lose nutrition while in range of a slime discharger.
#define SLIME_DISCHARGER_WEAKENED (1<<0)
/// These slimes start teleporting uncontrollably when they're affected by a bluespace anchor
#define SLIME_BLUESPACE_CONNECTION (1<<1)
/// These slimes are immune to damage from water
#define SLIME_WATER_IMMUNITY (1<<2)
/// These slimes will trigger pyrite thrower
#define SLIME_HOT_LOVING (1<<3)
/// These slimes are immune to BZ stasis effect. Still affected by backpack stasis!
#define SLIME_BZ_IMMUNE (1<<4)
/// These slimes will attack other slimes
#define SLIME_ATTACK_SLIMES (1<<5)
/// These slimes can't be spawned randomly
#define SLIME_NO_RANDOM_SPAWN (1<<6)
/// These slimes don't lose mood when their requirement is not satisfied
#define SLIME_NO_REQUIREMENT_MOOD_LOSS (1<<7)
/// These slimes take x0.5 damage from water
#define SLIME_WATER_RESISTANCE (1<<8)
/// These slimes take x1.5 damage from water
#define SLIME_WATER_WEAKNESS (1<<9)
/// These slimes will attack the dead
#define SLIME_ATTACK_DEAD (1<<10)
/// These slimes will feel very lonely without at least 2 more slimes in their pen
#define SLIME_SOCIAL (1<<11)
/// These slimes will feel sad when theres more than 2 other slimes in their pen
#define SLIME_ANTISOCIAL (1<<12)

/// Slime requirements


/// At what temperature orange slimes start losing nutrition
#define ORANGE_SLIME_UNHAPPY_TEMP T0C+60
/// At what temperature orange slimes start taking damage
#define ORANGE_SLIME_DANGEROUS_TEMP T0C+30

/// At what concentration purple slimes become rabid and start taking damage
#define PURPLE_SLIME_N2O_REQUIRED 35
/// How much damage do purple slimes heal per 4.5 seconds
#define PURPLE_SLIME_HEALING 10
/// How likely it is for a purple slime to make a slime that they heal rabid to prevent abusing them in pens
#define PURPLE_SLIME_RABID_INFLICTION 15

/// At what temperature blue slimes start taking damage
#define BLUE_SLIME_DANGEROUS_TEMP T0C-10
/// How much water vapor blue slimes create after finishing digesting
#define BLUE_SLIME_PUFF_AMOUNT 10
/// Blue slimes won't puff water vapor if there's more gas than this
#define BLUE_SLIME_MAX_WATER_VAPOR 15

/// How much CO2 metal slimes require
#define METAL_SLIME_CO2_REQUIRED 40

/// How likely it's for yellow slime to zap per second, multiplied by it's power level
#define YELLOW_SLIME_ZAP_PROB 4
#define YELLOW_SLIME_ZAP_POWER 3000
/// How much damage yellow slime takes as a result of uncontained discharge
#define YELLOW_SLIME_DISCHARGE_DAMAGE 15 //10 discharges will kill the slime

/// How likely it is for silver slime to implode every second
#define SILVER_SLIME_IMPLODE_PROB 10

/// How much plasma does dark purple slime need
#define DARK_PURPLE_SLIME_PLASMA_REQUIRED 25
/// Maximum amount of oxygen dark purple slimes can handle
#define DARK_PURPLE_SLIME_OXYGEN_MAXIMUM 2
/// How likely it is for dark purple slimes to puff out flaming plasma when they're not satisfied
#define DARK_PURPLE_SLIME_PUFF_PROBABILITY 25

/// How cold it should be for dark blue slime
#define DARK_BLUE_SLIME_DANGEROUS_TEMP T0C-40
/// How much water vapor do dark blue slimes want
#define DARK_BLUE_SLIME_VAPOR_REQUIRED 7
/// How fast are we losing cores
#define DARK_BLUE_SLIME_CORE_LOSE 10

/// How much can bluespace slime travel in one teleport
#define BLUESPACE_SLIME_TELEPORT_DISTANCE 6
/// How many seconds it takes for a bluespace anchor to fully consume one charge
#define BLUESPACE_ANCHOR_CHARGE_TIME 5 MINUTES
/// Amount of charges bluespace anchor can hold
#define BLUESPACE_ANCHOR_CAPACITY 3

/// How much bz sepia slimes need
#define SEPIA_SLIME_BZ_REQUIRED 10
/// How likely it is for sepia slime to stop time when there's not enough hydrogen in the air
#define SEPIA_SLIME_TIMESTOP_CHANCE 10
/// How likely it is for sepia slime to stop time when it's attacking
#define SEPIA_SLIME_ATTACK_TIMESTOP_CHANCE 15
/// How long sepia timestop lasts
#define SEPIA_SLIME_TIMESTOP_DURATION 3 SECONDS
/// How long sepia slimes recover from timestop
#define SEPIA_SLIME_TIMESTOP_RECOVERY 17 SECONDS
/// How many moles of BZ does sepia slime consume per second
#define SEPIA_SLIME_BZ_CONSUME 0.01

/// Pyrite slimes will either need this temperature OR a hotspot ontop of them
#define PYRITE_SLIME_COMFORTABLE_TEMPERATURE T0C + 480
/// How long pyrite slimes can survive without fire before they get damaged, in seconds. While fiery charge is higher than zero their attacks also apply fire stacks and ignite
/// This is required due to flame and hotspot inconsistency
#define PYRITE_SLIME_MAX_FIERY_CHARGE 25

/// Maximum safe pressure for cerulean slimes
#define CERULEAN_SLIME_MAX_SAFE_PRESSURE 5
/// Cooldown between cerulean slime lunges
#define CERULEAN_SLIME_LUNGE_COOLDOWN 16 SECONDS
/// How likely it is for a cerulean slime to use TK when it's requirements are satisfied
#define CERULEAN_SLIME_TELEKINESIS_CHANCE 1 //Painting the windows of the pen black is probably a good idea
/// How likely it is for a cerulean slime to use TK when it's requirements are NOT satisfied
#define CERULEAN_SLIME_AGRESSIVE_TELEKINESIS_CHANCE 10
/// How much HP cerulean slimes regenerate per second in vacuum
#define CERULEAN_SLIME_VACUUM_HEALING 5

/// How much oil is applied per attack/projectile
#define OIL_SLIME_STACKS_PER_ATTACK 3
/// Whats the limit for oil from attacks
#define OIL_SLIME_OIL_LIMIT 10
/// What pressure oil slimes want
#define OIL_SLIME_REQUIRED_PRESSURE ONE_ATMOSPHERE * 6
/// How often can oil slime use its ranged attack
#define OIL_SLIME_PROJECTILE_COOLDOWN 10 SECONDS

/// How likely it is for the black slime to change a random turf around him, per second
#define BLACK_SLIME_CHANGE_TURF_CHANCE 15
/// Range of black slime turf conversion(circular)
#define BLACK_SLIME_TURF_CHANGE_RANGE 3
/// Healing provided by terraformed turfs, per second.
#define SLIME_TURF_HEALING 1

/// How likely it is for a golden slime to recruit one creature
#define GOLDEN_SLIME_RECRUIT_CREATURE_CHANCE 55
/// How likely it is for a golden slime to recruit one slime
#define GOLDEN_SLIME_RECRUIT_SLIME_CHANCE 35
/// Range in which golden slimes recruit creatures
#define GOLDEN_SLIME_RECRUIT_RANGE 5
/// Range in which golden slimes recruit creatures if they have a slime crown
#define GOLDEN_SLIME_KING_RECRUIT_RANGE 9

/// How likely it is for a green slime to enter mimick mode if they aren't mimicking something already, per second
#define GREEN_SLIME_MIMICK_CHANCE 7
/// How likely it is for a green slime to revert from a mimick form per second
#define GREEN_SLIME_UNMIMICK_CHANCE 5
/// In what range can green slimes pick up objects to mimick
#define GREEN_SLIME_MIMICK_RANGE 7
/// Damage boost that green slimes get while mimicking
#define GREEN_SLIME_MIMICK_DAMAGE_BOOST 15
/// How more likely it is for a green slime to turn into a human rather than into an object
#define GREEN_SLIME_HUMAN_MIMICK_WEIGHT 20

/// How many plushies pink slimes want in their pen if they don't have a giant slime one. Slime plushies count for two! Requirement is also halved if the slime is wearing a friendship necklace
#define PINK_SLIME_PLUSHIE_REQUIREMENT 5
/// How likely it is for a for a pink slime to apply hallucinations to mobs viewing it when unhappy
#define PINK_SLIME_HALLUCINATION_CHANCE 25

/// How long it takes for a light pink slime to take control over a body
#define LIGHT_PINK_SLIME_MIND_CONTROL_TIMER 10 SECONDS
/// How long it takes to resist out of light pink slime control
#define LIGHT_PINK_SLIME_RESIST_TIME 2 MINUTES //Like bucklecuffed
/// How much nutrition do light pinks get when finishing a critted target
#define LIGHT_PINK_SLIME_FINISHER_NUTRITION 75

/// Attack types for adamantine slime
#define ADAMANTINE_SLIME_MOVE_SLAM "slam"
#define ADAMANTINE_SLIME_MOVE_SUPLEX "suplex"
#define ADAMANTINE_SLIME_MOVE_GROUND_STRIKE "ground_strike"
/// How often do adamantine slimes need to exercise
#define ADAMANTINE_SLIME_EXERCISE_COOLDOWN 30 SECONDS
/// How long can adamantine slimes survive without exercising
#define ADAMANTINE_SLIME_EXERCISE_TOLERANCE 30 SECONDS
/// How likely are adamantine slimes to randomly use special attacks
#define ADAMANTINE_SLIME_RANDOM_ATTACK 10
/// Attack damages
#define ADAMANTINE_SLIME_SLAM_DAMAGE 35
#define ADAMANTINE_SLIME_SUPLEX_DAMAGE 20
#define ADAMANTINE_SLIME_GROUND_STRIKE_DAMAGE 15

///How often can fiery slime use its ranged attack
#define FIERY_SLIME_PROJECTILE_COOLDOWN 15 SECONDS
