/// From mob/living/simple_animal/slime/attack_target(): (atom/target)
#define COMSIG_SLIME_ATTACK_TARGET "slime_attack_target"
	#define COMPONENT_SLIME_NO_ATTACK  (1<<0) //Cancels the attack
/// From mob/living/simple_animal/slime/can_feed_on(): (atom/target)
#define COMSIG_SLIME_CAN_FEED "slime_can_feed"
	#define COMPONENT_SLIME_NO_FEED  (1<<0) //Cancels the feeding
/// From mob/living/simple_animal/slime/regenerate_icons(): ()
#define COMSIG_SLIME_REGENERATE_ICONS "slime_regenerate_icons"
	#define COMPONENT_SLIME_NO_ICON_REGENERATION  (1<<0) //Cancels icon regeneration in case you, for some reason, want to keep the appearance
#define COMSIG_SLIME_POST_REGENERATE_ICONS "slime_post_regenerate_icons"
/// From mob/living/simple_animal/slime/feed_stop() and mob/living/simple_animal/slime/handle_digestion(): (atom/target)
#define COMSIG_SLIME_DIGESTED "slime_digested"
/// From mob/living/simple_animal/slime/start_moveloop(atom/move_target): (atom/move_target)
#define COMSIG_SLIME_START_MOVE_LOOP "slime_start_move_loop"
	#define COMPONENT_SLIME_NO_MOVE_LOOP_START  (1<<0)
/// From mob/living/simple_animal/slime/post_move(): (direction, datum/move_loop/move_loop, bumped)
#define COMSIG_SLIME_SQUEESING_ATTEMPT "slime_squeesing_attempt"
	#define COMPONENT_SLIME_NO_SQUEESING  (1<<0) //Cancels default squeesing in this direction
/// From mob/living/simple_animal/slime/feed_on(atom/target): (atom/target)
#define COMSIG_SLIME_FEEDON "slime_feedon"
/// From mob/living/simple_animal/slime/feed_stop(silent, living): (atom/target)
#define COMSIG_SLIME_FEEDSTOP "slime_feedstop"
/// From mob/living/simple_animal/slime/process(): ()
#define COMSIG_SLIME_BUCKLED_AI "slime_buckled_ai"
	#define COMPONENT_SLIME_ALLOW_BUCKLED_AI  (1<<0) //Allows AI when the slime is buckled
/// From mob/living/simple_animal/slime/stop_moveloop(): ()
#define COMSIG_SLIME_STOP_MOVE_LOOP "slime_stop_move_loop"
	#define COMPONENT_SLIME_NO_MOVE_LOOP_STOP  (1<<0)
/// From mob/living/simple_animal/slime/feed_on(atom/target): (atom/target)
#define COMSIG_SLIME_CAN_FEEDON "slime_can_feedon"
	#define COMPONENT_SLIME_NO_FEEDON  (1<<0)
/// From mob/living/simple_animal/slime/handle_speech(delta_time, times_fired): (to_say)
#define COMSIG_SLIME_ATTEMPT_SAY "slime_attempt_say"
	#define COMPONENT_SLIME_NO_SAY  (1<<0)
/// From mob/living/simple_animal/slime/set_target(atom/new_target): (atom/old_target, atom/new_target)
#define COMSIG_SLIME_SET_TARGET "slime_set_target"
	#define COMPONENT_SLIME_NO_SET_TARGET  (1<<0)
/// From mob/living/simple_animal/slime/process(): (atom/target)
#define COMSIG_SLIME_ATTEMPT_RANGED_ATTACK "slime_attempt_ranged_attack"
/// From mob/living/simple_animal/slime/proc/handle_boredom(delta_time, times_fired, hungry): (atom/possible_interest)
#define COMSIG_SLIME_CAN_TARGET_POI "slime_can_target_poi"
	#define COMPONENT_SLIME_TARGET_POI  (1<<0)
