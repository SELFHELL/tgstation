// simple_animal signals
/// called when a simplemob is given sentience from a potion (target = person who sentienced)
#define COMSIG_SIMPLEMOB_SENTIENCEPOTION "simplemob_sentiencepotion"

// /mob/living/simple_animal/hostile signals
///before attackingtarget has happened, source is the attacker and target is the attacked
#define COMSIG_HOSTILE_PRE_ATTACKINGTARGET "hostile_pre_attackingtarget"
	#define COMPONENT_HOSTILE_NO_ATTACK (1<<0) //cancel the attack, only works before attack happens
///after attackingtarget has happened, source is the attacker and target is the attacked, extra argument for if the attackingtarget was successful
#define COMSIG_HOSTILE_POST_ATTACKINGTARGET "hostile_post_attackingtarget"
///from base of mob/living/simple_animal/hostile/regalrat: (mob/living/simple_animal/hostile/regalrat/king)
#define COMSIG_RAT_INTERACT "rat_interaction"
///FROM mob/living/simple_animal/hostile/ooze/eat_atom(): (atom/target, edible_flags)
#define COMSIG_OOZE_EAT_ATOM "ooze_eat_atom"
	#define COMPONENT_ATOM_EATEN  (1<<0)
///From mob/living/simple_animal/slime/slime_step(): (atom/target)
#define COMSIG_SLIME_TAKE_STEP "slime_take_step"
	#define COLOR_SLIME_NO_STEP  (1<<0) //Cancels the AI movement in case slime color has it's own ways of transportation(bluespace slimes for example)
///From mob/living/simple_animal/slime/attack_atom(): (atom/target)
#define COMSIG_SLIME_ATTACK_ATOM "slime_attack_atom"
	#define COLOR_SLIME_NO_ATTACK  (1<<0) //Cancels the attack
