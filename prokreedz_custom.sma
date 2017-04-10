/*
 * ProKreedz by p4ddY
 * Customized by ChunYuha, Q(''Q)
 */
 
// p4ddY All rights reserved

#include <amxmodx>
#include <amxmisc>

#include <fun>				// For some Adminstuff
#include <engine>			// My most used module ;o
#include <cstrike>			// I need this to give somebody a nvg :(
#include <nvault>			// For top10

#include <fakemeta>
#include <fakemeta_const>
#include <fakemeta_stocks>

#define MAX_CPS 5 			// MUST be greater than 2
#define NOBLOCK_DISTANCE 120.0		// Distance between 2 players - if distance is smaller -> semiclip
#define CP_DISTANCE 35.0		// Distance between player and checkpoint
#define KZ_LEVEL ADMIN_KICK		// Adminlevel
#define BUTTON_DISTANCE 64.0//70	// 실제 버튼의 길이로 수정( 데모에서 보여주는 벽을 통해서 스톱이 가능함 )
#define MAX_TOP 30			// 순위 인원수
#define MENU_KEYS MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_0
#define MENU_KEYS_ADMIN MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
#define MENU_KEYS_BATTLE MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
#define MENU_KEYS_SCOUT MENU_KEY_1|MENU_KEY_0 // scout
#define MSG_RANK 0
#define MSG_WARN 1
#define MSG_BATTLE 2
#define TASK_SCOUT 5000
#define SCOUT_CHT 6000

#define FALSE 0
#define TRUE  1

//포인트
#define POINT 1

//hook
#define KZ_LEVEL ADMIN_KICK		// Adminlevel

new bool:canusehook[32]
new bool:ishooked[32]
new hookorigin[32][3]

//hook

new cc[32][2] // scout 치트 카운트

new bool:noblock[32]

new Float:checkpoints[32][MAX_CPS][3]
new checkpointnum[32]

new bool:needhelp[32]
new helpcount[32]

new bool:timer_started[32]
new timer_time[32]
new bool:showtimer[32]

new bhop[32]

new bool:usedbutton[32]

new bool:firstspawn[32]

// CVars (I like CVar pointers :o)
new kz_checkpoints
new kz_godmode
new kz_scout
new kz_help
new kz_semiclip
new kz_bhop
new kz_adminglow
new kz_cheatdetect
new kz_transparency
new bool:sc[32]
new autoshowmenu[64]
new climbstatus[64]
new float:climbtimes[32] // 실제 기록되고 마지막에 표시될 시간 계산 정밀도 높음
new rankedlist[32][32]

// Sprites
new Sbeam = 0

// hud
new msgSync
new msgSync1
new msgSync2


// 최종 도착시간 
new imin[32]
new float:isec[32]

// ==========================================================================

public plugin_init() 
{
	register_plugin("ProKreedz","1.1","ontale")
	
	register_cvar("prokreedz_version","1.1",FCVAR_SERVER)
	
	// CVars
	kz_checkpoints = register_cvar("kz_checkpoints","1")
	kz_godmode = register_cvar("kz_godmode","0")
	kz_scout = register_cvar("kz_scout","0")
	kz_help = register_cvar("kz_help","0")
	kz_semiclip = register_cvar("kz_semiclip","0")
	kz_bhop = register_cvar("kz_bhop","0")
	kz_adminglow = register_cvar("kz_adminglow","0")
	kz_cheatdetect = register_cvar("kz_cheatdetect","1")
	kz_transparency = register_cvar("kz_transparency","1")
	
	// Cmds
	register_clcmd("say .kreedz","kz_menu")
	register_clcmd("say /kreedz","kz_menu")
	register_clcmd("say .menu","kz_menu")
	register_clcmd("say /menu","kz_menu")
	register_clcmd("say .cstat","show_climb")
	register_clcmd("say /cstat","show_climb")
	register_clcmd("say .scout","scout" )
	register_clcmd("say /scout","scout" )
	register_clcmd("say .battle","battleMenu")
	register_clcmd("say /battle","battleMenu")
	register_clcmd("cp","checkpoint")
	register_clcmd("checkpoint","checkpoint")
	register_clcmd("say .cp","checkpoint")
	register_clcmd("say /cp","checkpoint")
	register_clcmd("say .checkpoint","checkpoint")
	register_clcmd("say /checkpoint","checkpoint")
	
	register_clcmd("tp","goto_checkpoint")
	register_clcmd("gocheck","goto_checkpoint")
	register_clcmd("say","goto_checkpoint_say")
	
	register_clcmd("stuck","goto_stuck")
	register_clcmd("unstuck","goto_stuck")
	register_clcmd("say .stuck","goto_stuck")
	register_clcmd("say /stuck","goto_stuck")
	register_clcmd("say .unstuck","goto_stuck")
	register_clcmd("say /unstuck","goto_stuck")
	
	register_clcmd("say .help","help")
	register_clcmd("say /help","help")
	
	register_clcmd("say .reset","reset_checkpoints")
	register_clcmd("say /reset","reset_checkpoints")
	
	register_clcmd("kz_unhelp","admin_unhelp",KZ_LEVEL)
	register_clcmd("kz_showhelp","admin_showhelp",KZ_LEVEL)
	register_clcmd("say .noclip","admin_noclip",KZ_LEVEL)
	register_clcmd("say /noclip","admin_noclip",KZ_LEVEL)
	register_clcmd("kz_laser","admin_laser",KZ_LEVEL,"[blue|yellow|green|red|orange]")
	
	// Some other admincmds
	register_clcmd("kz_noclip","admin_noclip",KZ_LEVEL,"<name|#userid|steamid|@ALL> <on/off>")
	register_clcmd("kz_teleport","admin_teleport",KZ_LEVEL,"<name|#userid|steamid> <name|#userid|steamid>")
	register_clcmd("kz_gravity","admin_gravity",KZ_LEVEL,"<name|#userid|steamid|@ALL> <gravity>")
	
	register_clcmd("say .amenu","kz_menu_admin_show",ADMIN_CVAR)
	register_clcmd("say /amenu","kz_menu_admin_show",ADMIN_CVAR)
	register_clcmd("say .adminmenu","kz_menu_admin_show",ADMIN_CVAR)
	register_clcmd("say /adminmenu","kz_menu_admin_show",ADMIN_CVAR)
	
	register_clcmd("say .respawn","respawn")
	register_clcmd("say /respawn","respawn")
	register_clcmd("say .spawn","respawn")
	register_clcmd("say /spawn","respawn")
	register_clcmd("say .start","respawn")
	register_clcmd("say /start","respawn")
	
	register_clcmd("say .top10","topten_show")
	register_clcmd("say /top10","topten_show")
	//xyz
	register_clcmd("say .top20","toptwenty_show")
	register_clcmd("say /top20","toptwenty_show")
	register_clcmd("say .top30","topthirty_show")
	register_clcmd("say /top30","topthirty_show")
	register_clcmd("say .rank","rank_show")
	register_clcmd("say /rank","rank_show")
	//xyz
	// point
	register_clcmd("say .pt","point_show")
	register_clcmd("say /pt","point_show")	
	register_clcmd("say .point","point_show")
	register_clcmd("say /point","point_show")
	// point
	//hook
	register_clcmd("+hook","hook_on",KZ_LEVEL)
	register_clcmd("-hook","hook_off",KZ_LEVEL)
	
	register_clcmd("kz_hook","give_hook",KZ_LEVEL,"<name|#userid|steamid|@ALL> <on/off>")
	//hook
	
	// Events
	register_event("WeapPickup","weappickup","be")
	register_event("HideWeapon","hideweapon","be")
	register_event("DeathMsg","deathmsg","a")
	register_event("ResetHUD","resethud","be")
	

	//register_touch("player","func_button","button_touch") SUCKS!
	
	// Menue
	register_menu("ScoutMenu",MENU_KEYS_SCOUT,"menu_scout_handler")
	register_menu("Ontale's JUMP SERVER",MENU_KEYS,"menu_handler")
	register_menu("Adminmenu",MENU_KEYS_ADMIN,"menu_handler_admin")
	register_menu("BattleMenu",MENU_KEYS_BATTLE,"menu_handler_battle")
	
	set_task(0.1,"noblock_task",1000,"",0,"ab")
	set_task(1.0,"timer_task",2000,"",0,"ab")
	//set_task(1.0,"show_systime",3000,"",0,"ab")
	
	new kreedz_cfg[128], cfgdir[64]
		
	get_configsdir(cfgdir,64)	
	format(kreedz_cfg,128,"%s/kreedz.cfg",cfgdir)
	
	//hud message
	msgSync = CreateHudSyncObj()
	msgSync1 = CreateHudSyncObj()
	msgSync2 = CreateHudSyncObj()
	
	if(file_exists(kreedz_cfg)) 
	{
		server_exec()
		server_cmd("exec %s",kreedz_cfg)
	}
}

public plugin_precache() 
{
	Sbeam = precache_model("sprites/laserbeam.spr")
}

// =================================================================================
// Global Functions
// =================================================================================
public hideweapon(id)
{
	client_print(id,print_chat,"public hideweapon(id)")
}
new health[32]
public respawn(id) 
{
	new pid = id < 100 ? id : id-100
	health[pid-1] = get_user_health(pid)
	spawn(pid)
}

public noblock_task() 
{
	if(get_pcvar_num(kz_semiclip) > -1) 
	{
		new bool:solid[32]
		new Float:origin[3]
		new Float:vorigin[3]
		for(new x=1;x<=get_maxplayers();x++) 
		{
			if(is_user_connected(x) && is_user_alive(x)) 
			{
				if(get_pcvar_num(kz_semiclip) == 1 || noblock[x-1]) 
				{
					entity_get_vector(x,EV_VEC_origin,origin)

					for(new i=1;i<=get_maxplayers();i++) 
					{
						if(x != i && is_user_connected(i) && is_user_alive(i)) 
						{
							entity_get_vector(i,EV_VEC_origin,vorigin)
							if(get_distance_f(origin,vorigin) <= NOBLOCK_DISTANCE) 
							{
								entity_set_int(x,EV_INT_solid,SOLID_NOT)
								entity_set_int(i,EV_INT_solid,SOLID_NOT)
								
								if(get_pcvar_num(kz_transparency) == 1) 
								{
									set_rendering(x,kRenderFxNone,255,255,255,kRenderTransAdd,60)
									set_rendering(i,kRenderFxNone,255,255,255,kRenderTransAdd,60)
								}
								
								solid[x-1] = true
								solid[i-1] = true
							}
							else if(!solid[i-1]) 
							{
								entity_set_int(i,EV_INT_solid,SOLID_BBOX)
								glow(i)
							}
						}
					}
				}
				else if(!solid[x-1]) 
				{
					entity_set_int(x,EV_INT_solid,SOLID_BBOX)
					glow(x)
				}
			}
		}
	}
	else 
	{
		for(new i=1;i<=get_maxplayers();i++) 
		{
			if(is_user_connected(i) && is_user_alive(i)) 
			{
				entity_set_int(i,EV_INT_solid,SOLID_BBOX)
				glow(i)
			}
		}
	}
}

// =================================================================================
// 표시되고 산술되는 시간은 시스템 시간을 기준으로 한다.
// 저장되어 다루어질땐( 결과 값 )
// climbtimes 배열에 담아놓고 사용한다.
// (get_user_time(i) - climbtimes[i-1]) 과의 혼용과 불필요하게 재 계산하는 것을 방지한다.
public timer_task() 
{
	new kreedztime, imin

	for(new i=1 ; i<=get_maxplayers() ; i++) 
	{
		if(showtimer[i-1] && timer_started[i-1]) 
		{
			//kreedztime = (get_user_time(i) - climbtimes[i-1]) 유저 타임을 얻는 과정에서 딜레이가 생기는 듯
			// timer_time[i-1] 출발시의 get_systime
			kreedztime = get_systime() - timer_time[i-1]
			
			if((kreedztime / 60.0) >= 1) 
			{
				imin = floatround(kreedztime / 60.0,floatround_floor)
				kreedztime -= imin * 60
			}

			client_print(i,print_center,"[ %02d 분 %02d 초 ]",imin,kreedztime)
		}
	}
	
}

// =================================================================================

public glow(id) 
{
	new colors[3]
	new userName[32] 
	get_user_name(id, userName, 32)

	if(needhelp[id-1] && get_pcvar_num(kz_help) == 1)
		colors = {255,0,0}
	else if(access(id,KZ_LEVEL) && get_pcvar_num(kz_adminglow) == 1)
		colors = {170,255,0}
	else
		colors = {0,0,0}

	if( equal( rankedlist[0], userName ) )// 1위 일때 황금 glow
		colors = { 251,246,121 }// 맵이 바뀌지 않는한 reconnect 해도 적용
		
	set_rendering(id,kRenderFxGlowShell,colors[0],colors[1],colors[2],kRenderNormal,100000)
}

// =================================================================================

public detect_cheat(id,reason[]) { // I saw this feature in kz_mulitplugin :o
// 훅훅훅
//	if(timer_started[id-1] && get_pcvar_num(kz_cheatdetect) == 1) {
//		client_print(id,print_chat,"[Ontale*] %s 이(가) 발견되었으므로 타이머가 정지됩니다.",reason)
//		timer_started[id-1] = false
//	}
}

// =================================================================================
// Cmds
// =================================================================================

public checkpoint(id) {
	if(get_pcvar_num(kz_checkpoints) == 1) {
		if(is_user_alive(id)) {
			if(entity_get_int(id,EV_INT_flags)&FL_DUCKING) {
				client_print(id,print_chat,"[Ontale*] 앉은 상태에선 저장할 수 없습니다.")
				return PLUGIN_HANDLED
			}
			
			for(new i=MAX_CPS-1;i>0;i--) {
				checkpoints[id-1][i][0] = checkpoints[id-1][i-1][0]
				checkpoints[id-1][i][1] = checkpoints[id-1][i-1][1]
				checkpoints[id-1][i][2] = checkpoints[id-1][i-1][2]
			}
			new Float:origin[3]
			entity_get_vector(id,EV_VEC_origin,origin)
			checkpoints[id-1][0][0] = origin[0]
			checkpoints[id-1][0][1] = origin[1]
			checkpoints[id-1][0][2] = origin[2]
			
			checkpointnum[id-1]++

			client_print(id,print_chat,"[Ontale*] %d번째 체크포인트가 생성되었습니다.", checkpointnum[id-1] )//이전 체크포인트와의 거리 : %dm",checkpointnum[id-1]+1,floatround(get_distance_f(checkpoints[id-1][1],origin) / 20,floatround_round))
		}
		else
			client_print(id,print_chat,"[Ontale*] 이 명령어를 사용하기 위해선 살아있는 상태여야 합니다.")
	}
	else
		client_print(id,print_chat,"[Ontale*] 체크포인트 사용이 불가합니다. cuz 서버세팅")
	
	return PLUGIN_HANDLED
}

// =================================================================================

public goto_checkpoint(id) {
	if(get_pcvar_num(kz_checkpoints) == 1) {
		if(is_user_alive(id)) {
			if(checkpointnum[id-1] > 0) {
				if(read_argc() == 2) {
					new szcp[8], cpnum
					read_argv(1,szcp,8)
					cpnum = str_to_num(szcp) - 1
						
					if(cpnum >= 0 && cpnum < MAX_CPS) {
						if(cpnum < checkpointnum[id-1])
							goto_cp(id,cpnum)
						else
							client_print(id,print_chat,"[Ontale*] 충분한 체크포인트가 생성되어있지 않습니다.")
					}
					else
						goto_cp(id,0)
				}
				else {
					goto_cp(id,0)
				}
			}
			else
				client_print(id,print_chat,"[Ontale*] 우선 체크포인트를 생성하세요.")
		}
		else
			client_print(id,print_chat,"[Ontale*] 이 명령어를 사용하기 위해선 살아있어야 됩니다.")
	}
	else
		client_print(id,print_chat,"[Ontale*] 체크포인트 사용이 불가능합니다.")
		
	return PLUGIN_HANDLED
}

public goto_checkpoint_say(id) {
	if(read_argc() == 2) {
		new szarg1[32], args1[16], args2[16]
		read_argv(1,szarg1,32)
		copyc(args1,16,szarg1,32)
		copy(args2,16,szarg1[strlen(args1)+1])
		if(equal(args1,".tp") || equal(args1,"/tp") || equal(args1,".gocheck") || equal(args1,"/gocheck")) {
			if(get_pcvar_num(kz_checkpoints) == 1) {
				if(is_user_alive(id)) {
					if(checkpointnum[id-1] > 0) {
						new cpnum = str_to_num(args2) - 1
						if(cpnum >= 0 && cpnum < MAX_CPS) {
							if(cpnum < checkpointnum[id-1])
								goto_cp(id,cpnum)
							else
								client_print(id,print_chat,"[Ontale*] 충분한 체크포인트가 생성되어있지 않습니다.")
						}
						else
							goto_cp(id,0)	
					}
					else
						client_print(id,print_chat,"[Ontale*] 우선 체크포인트를 생성하세요.")
				}
				else
					client_print(id,print_chat,"[Ontale*] 이 명령어를 사용하기 위해선 살아있어야 됩니다.")
			}
			else
				client_print(id,print_chat,"[Ontale*] 체크포인트 사용이 불가능합니다.")
				
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}

public goto_stuck(id) {
	if(get_pcvar_num(kz_checkpoints) == 1) {
		if(is_user_alive(id)) {
			if(checkpointnum[id-1] > 1)
				goto_cp(id,1)
			else
				client_print(id,print_chat,"[Ontale*] 충분한 체크포인트가 생성되어있지 않습니다.")
		}
		else
			client_print(id,print_chat,"[Ontale*] 이 명령어를 사용하기 위해선 살아있어야 됩니다.")
	}
	else
		client_print(id,print_chat,"[Ontale*] 체크포인트 사용이 불가능합니다.")
		
	return PLUGIN_HANDLED
}

// =================================================================================

public goto_cp(id,cp) {
	new semiclip = get_pcvar_num(kz_semiclip)
	if(semiclip == -1 || (!noblock[id-1] && semiclip == 0)) {
		new Float:origin[3]
		for(new i=1;i<=get_maxplayers();i++) 
		{
			if(id != i && is_user_connected(i) && is_user_alive(id)) {
				if(semiclip == -1 || (!noblock[i-1] && semiclip == 0)) 
				{
					entity_get_vector(i,EV_VEC_origin,origin)
					if(get_distance_f(checkpoints[id-1][cp],origin) <= CP_DISTANCE) {
						client_print(id,print_chat,"[Ontale*] 누군가가 당신의 체크포인트 가까이에 있습니다.")
						return false
					}
				}
			}
		}
	}
	
	entity_set_origin(id,checkpoints[id-1][cp])
	entity_set_vector(id,EV_VEC_velocity,Float:{0.0,0.0,0.0})
	spawnsprite(checkpoints[id-1][cp])
	set_user_gravity(id) // to fix the low gravity bug on kz_man_redrock (thanks to NoEx)
	noblock_task()
	
	return true
}

// =================================================================================

public spawnsprite(Float:origin[3]) 
{
	new iorigin[3]
	iorigin[0] = floatround(origin[0],floatround_ceil)
	iorigin[1] = floatround(origin[1],floatround_ceil)
	iorigin[2] = floatround(origin[2],floatround_ceil)
	
	message_begin(MSG_ALL,SVC_TEMPENTITY)
	write_byte(11)
	write_coord(iorigin[0])
	write_coord(iorigin[1])
	write_coord(iorigin[2])
	message_end()
}

// =================================================================================

public reset_checkpoints(id) 
{
	checkpointnum[id-1] = 0
	timer_started[id-1] = false
	client_print(id,print_chat,"[Ontale*] 타이머와 체크포인트가 초기화되었습니다.")

	if( ( sc[id-1] == true ) && ( !user_has_weapon( id,CSW_SCOUT ) ) )
		give_item(id,"weapon_scout")
	if( !user_has_weapon(id,CSW_USP ) )
		give_item(id,"weapon_usp")
	if( !user_has_weapon(id,CSW_C4 ) )
		give_item(id,"weapon_c4")

	climbstatus[id] = 0
	set_user_health(id, 100) // 초기화
//	drop_item(id,"item_assaultsuit") // 방어구 버리고
	cs_set_user_money ( id , 0, 0) // 돈 0 만들고
	cs_set_user_bpammo( id, CSW_USP, 24 )
	cs_set_user_armor ( id, 0, CS_ARMOR_VESTHELM  ) // 이걸로 방어구 없앰
	cs_set_weapon_ammo ( find_ent_by_owner(-1, "weapon_usp", id), 12 ) // 실제 탄창안의 총알수를 세팅한다

	cc[id-1][0] = 0 // 스카웃 치트 카운트 
	cc[id-1][1] = false

	return PLUGIN_HANDLED
}

// =================================================================================

public help(id) {
	if(get_pcvar_num(kz_help) == 1) {
		new name[32]
		get_user_name(id,name,32)
		if(needhelp[id-1]) {
			needhelp[id-1] = false
			client_print(0,print_chat,"[Ontale*] %s님은 더이상의 도움이 필요하지 않습니다.",name)
		}
		else {
			needhelp[id-1] = true
			helpcount[id-1]++
			client_print(0,print_chat,"[Ontale*] %s님이 도움을 요청합니다.",name)
			client_print(id,print_chat,"[Ontale*] 더이상의 도움이 필요없다면, '.help'를 다시 한번 치세요.",name)
		}
	}
	glow(id)
	
	return PLUGIN_HANDLED
}

// =================================================================================
// AdminCmds
// =================================================================================

public admin_unhelp(id,level,cid) 
{
	new name[32]
	get_user_name(id,name,32)
	
	if(read_argc() == 2) {
		if(!cmd_access(id,level,cid,2))
			return PLUGIN_HANDLED
			
		new sztarget[32]
		read_argv(1,sztarget,32)
		if(equal(sztarget,"@ALL")) {
			for(new i=1;i<=get_maxplayers();i++) {
				if(is_user_connected(i)) {
					if(needhelp[i-1]) {
						needhelp[i-1] = false
						client_print(i,print_chat,"[ProKreedz] Admin %s has helped you",name)
					}
					glow(i)
				}
			}
		}
		else {
			new target = cmd_target(id,sztarget,2)
			if(target > 0) {	
				if(needhelp[target-1]) {
					needhelp[target-1] = false
					client_print(target,print_chat,"[ProKreedz] Admin %s has helped you",name)
				}
				glow(target)
				
			}
		}
	}
	else {
		if(!cmd_access(id,level,cid,1))
			return PLUGIN_HANDLED
		
		new aimid, body
		get_user_aiming(id,aimid,body)
		if(aimid > 0 && aimid < 33) {
			needhelp[aimid-1] = false
			glow(aimid)
			client_print(aimid,print_chat,"[ProKreedz] Admin %s has helped you",name)
		}
	}
	
	return PLUGIN_HANDLED
}

// =================================================================================

public admin_showhelp(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	for(new i=1;i<=get_maxplayers();i++) {
		if(is_user_connected(i) && is_user_alive(i) && needhelp[i-1]) {
			message_begin(MSG_ONE,SVC_TEMPENTITY,{0,0,0},id)
			write_byte(8)			// TE_BEAMENTS
			write_short(id)			// start entity
			write_short(i)			// end entity
			write_short(Sbeam)		// sprite to draw (precached below)
			write_byte(0)			// starting frame
			write_byte(0)			// frame rate
			write_byte(100)			// life in 0.1s
			write_byte(3)			// line width in 0.1u
			write_byte(0)			// noise in 0.1u
			write_byte(255)			// R
			write_byte(0)			// G
			write_byte(0)			// B
			write_byte(200)			// brightness
			write_byte(2)			// scroll speed
			message_end()
		}
	}
	
	return PLUGIN_HANDLED
}

// =================================================================================

public admin_noclip(id,level,cid) {
	if(read_argc() == 1 || read_argc() == 2) {
		if(!cmd_access(id,level,cid,1)) {
			set_user_noclip(id,0)
			return PLUGIN_HANDLED
		}
		
		set_user_noclip(id,get_user_noclip(id) == 1 ? 0 : 1)
		if(get_user_noclip(id) == 1)
			detect_cheat(id,"Noclip")
	}
	else if(read_argc() == 3) {
		if(!cmd_access(id,level,cid,3))
			return PLUGIN_HANDLED
			
		new name[32]
		get_user_name(id,name,32)
		
		new szarg1[32], szarg2[8], bool:mode
		read_argv(1,szarg1,32)
		read_argv(2,szarg2,32)
		if(equal(szarg2,"on"))
			mode = true
		
		if(equal(szarg1,"@ALL")) {
			for(new i=1;i<=get_maxplayers();i++) {
				if(is_user_connected(i) && is_user_alive(i)) {
					set_user_noclip(i,mode ? 1 : 0)
					client_print(i,print_chat,"[ProKreedz] Admin %s %s noclip",name,mode ? "gave you" : "removed your")
					client_print(i,print_chat,"[ProKreedz] Type '.noclip' to remove it")
					if(mode)
						detect_cheat(i,"Noclip")
				}
			}
		}
		else {
			new pid = cmd_target(id,szarg1,2)
			if(pid > 0 && is_user_alive(pid)) {
				set_user_noclip(pid,mode ? 1 : 0)
				client_print(pid,print_chat,"[ProKreedz] Admin %s %s noclip",name,mode ? "gave you" : "removed your")
				client_print(pid,print_chat,"[ProKreedz] Type '.noclip' to remove it")
				if(mode)
					detect_cheat(pid,"Noclip")
			}
		}
	}
	
	return PLUGIN_HANDLED
}

// =================================================================================

public admin_teleport(id,level,cid) {
	new name[32]
	get_user_name(id,name,32)
	
	if(read_argc() == 3) {
		if(!cmd_access(id,level,cid,3))
			return PLUGIN_HANDLED
		
		new szarg1[32], szarg2[32]
		read_argv(1,szarg1,32)
		read_argv(2,szarg2,32)
		
		new id1 = cmd_target(0,szarg1,1&4), id2 = cmd_target(0,szarg2,4)
		if(id1 > 0 && id2 > 0) {
			new targetname[32]
			get_user_name(id2,targetname,32)
			
			if(entity_get_int(id2,EV_INT_flags)&FL_DUCKING)
				client_print(id,print_console,"%s is ducking. Can not teleport",targetname)
			else {
				new Float:origin[3]
				entity_get_vector(id2,EV_VEC_origin,origin)
				entity_set_origin(id1,origin)
				
				client_print(id1,print_chat,"[ProKreedz] Admin %s has teleported you to %s",name,targetname)
				detect_cheat(id1,"Teleport")
			}
		}
	}
	else {
		if(!cmd_access(id,level,cid,5))
			return PLUGIN_HANDLED
			
		new szarg1[32]
		read_argv(1,szarg1,32)
		
		new target = cmd_target(0,szarg1,1&4)
		if(target > 0) {
			new szargx[8], szargy[8], szargz[8]
			read_argv(2,szargx,8)
			read_argv(3,szargy,8)
			read_argv(4,szargz,8)
			
			new Float:origin[3]
			origin[0] = str_to_float(szargx)
			origin[1] = str_to_float(szargy)
			origin[2] = str_to_float(szargz)
			
			entity_set_origin(target,origin)
			client_print(target,print_chat,"[ProKreedz] Admin %s has teleported you",name)
			detect_cheat(target,"Teleport")
		}
	}
		
	return PLUGIN_HANDLED
}

// =================================================================================

public admin_gravity(id,level,cid) {
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
		
	new name[32]
	get_user_name(id,name,32)
	
	new szarg1[32], szarg2[8], gravity, Float:fgravity
	read_argv(1,szarg1,32)
	read_argv(2,szarg2,8)
	gravity = str_to_num(szarg2)
	fgravity = gravity / float(get_cvar_num("sv_gravity"))
	
	if(equal(szarg1,"@ALL")) {
		for(new i=1;i<=get_maxplayers();i++) {
			if(is_user_connected(i)) {
				set_user_gravity(i,fgravity)
				client_print(i,print_chat,"[ProKreedz] Admin %s has set your gravity to %d",name,gravity)
				if(fgravity != 1.0)
					detect_cheat(i,"Gravity")
			}
		}
	}
	else {
		new target = cmd_target(0,szarg1,2)
		if(target > 0) {
			set_user_gravity(target,fgravity)
			client_print(target,print_chat,"[ProKreedz] Admin %s has set your gravity to %d",name,gravity)
			if(fgravity != 1.0)
				detect_cheat(target,"Gravity")
		}
	}
		
	return PLUGIN_HANDLED
}

// =================================================================================

public admin_laser(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
		
	new colors[3]
	if(read_argc() > 1) {
		new szcolor[8]
		read_argv(1,szcolor,8)
		if(equal(szcolor,"red"))
			colors = {255,0,0}
		else if(equal(szcolor,"blue"))
			colors = {0,0,255}
		else if(equal(szcolor,"yellow"))
			colors = {255,255,0}
		else if(equal(szcolor,"orange"))
			colors = {255,150,0}
		else if(equal(szcolor,"green"))
			colors = {0,255,0}
		else
			colors = {255,255,255}
	}
	else
		colors = {255,255,255}
		
	new origin[3], aimorigin[3]
	get_user_origin(id,origin)
	get_user_origin(id,aimorigin,3)

	message_begin(MSG_ALL,SVC_TEMPENTITY)
	write_byte(0)			// TE_BEAMPOINTS
	write_coord(origin[0])		// start point
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(aimorigin[0])	// end point
	write_coord(aimorigin[1])
	write_coord(aimorigin[2])
	write_short(Sbeam)		// sprite to draw (precached below)
	write_byte(0)			// starting frame
	write_byte(0)			// frame rate
	write_byte(100)			// life in 0.1s
	write_byte(3)			// line width in 0.1u
	write_byte(0)			// noise in 0.1u
	write_byte(colors[0])		// R
	write_byte(colors[1])		// G
	write_byte(colors[2])		// B
	write_byte(200)			// brightness
	write_byte(2)			// scroll speed
	message_end()
	
	return PLUGIN_HANDLED
}

// =================================================================================
// Events / Forwards
// =================================================================================
public cheat_task(num[])
{
	new i = str_to_num( num )	

	cc[i-1][0]-=1//카운트다운

	if( cc[i-1][0] <= 0 )
	{// 시간 초과 초기화 & 벌금 부과(추가)
		remove_task( i + SCOUT_CHT ) // set_tast종룐
		drop_item( i, "weapon_scout" )
		reset_checkpoints(i) //리셋
		respawn(i)//시작으로
		cc[i-1][1]=false // 카운트 삭제됨
		updatePoint(i,-5);
	}
	else
	{
		if( cc[i-1][0]%10 == 0 )
			client_print(i,print_chat,"[Ontale*] !!주의!! 인증되지 않은 SCOUT을 소지. %02d초안에 버리거나 인증을 획득하십시오.",cc[i-1][0]/10)
		
		new Weapons[32] 
		new numWeapons, j
		get_user_weapons(i, Weapons, numWeapons) 
		new bool:detect = false
	
		for (j=0; j<numWeapons; j++) 
		{ 
		    if( Weapons[j] == CSW_SCOUT )
			detect = true;
		}

		if( detect == false || sc[i-1] == true )
		{
			remove_task( i + SCOUT_CHT )
			client_print(i,print_chat,"[Ontale*] 불법 소지 해재.....!!")
			cc[i-1][1]=false // 카운트 삭제됨
		}
	}

}

public weappickup(id)
{
	if( timer_started[id-1] && sc[id-1] == false )
	{// 불법 스카웃 소지
		new Weapons[32] 
		new num[8]
		new numWeapons, i
		get_user_weapons(id, Weapons, numWeapons) 

		for (i=0; i<numWeapons; i++) 
		{ 
			if( Weapons[i] == CSW_SCOUT )
			{
				client_cmd(id, "spk fvox/warning.wav" )
				if( cc[id-1][1] == FALSE ) // task 등록은 한번만
				{
					if( cc[id-1][0] == 0 )
						cc[id-1][0] = 100
					num_to_str( id, num, 8 )
					set_task(0.1,"cheat_task",id+SCOUT_CHT,num,8,"ab") //1/10초 단위로 발생
				}
				if( cc[i-1][0]%10 == 0 )
					client_print(id,print_chat,"[Ontale*] !!주의!! 인증되지 않은 SCOUT을 소지. %02d초안에 버리거나 인증을 획득하십시오.",cc[id-1][0]/10)
				// 워닝~
				cc[id-1][1]=true
		      }					
		} 
	}
}

new scout_timer[32]

public scout_task( id[] )
{
	new i = str_to_num( id )
	scout_timer[i-1] +=1
	
	if( scout_timer[i-1] >= 3 )
	{
		show_menu(i,0," ") // 3 초후 자동 메뉴 종료" "빈 문자열로는 안되고 스페이스 문자로 해야 생각처럼 작동했다.
		remove_task( i+TASK_SCOUT ) // task 삭제(+111)을 한 이유는 hook 쪽에서도 id로 task 를 등록하게 되는데
		// 중복되면서 한쪽 task 가 오작동한다.
	}
}

public resethud(id) 
{//spawn(pid) 후에 이벤트 발생하고 이 함수가 실행되는 듯
	if(get_pcvar_num(kz_godmode) == 1)
		set_user_godmode(id,1)
	else
		set_user_godmode(id)
	
	if(get_pcvar_num(kz_scout) == 1 && !user_has_weapon(id,CSW_SCOUT))
		give_item(id,"weapon_scout")
	if(!user_has_weapon(id,CSW_KNIFE))
		give_item(id,"weapon_knife")
	// 이 시점에선 그냥 give_item하면 오버플로우 에러가난다.
	// 그래서 반드시 아이템이 있는지 먼저 검사를 해야하는데
	// 검사 자체가 flag 오프 시켜놓는 수단인 것 같다.
	// 사용전 flag를 off 시켜놓아야만 give_item이 정상 작동되는 것 같다.
	if(!user_has_weapon(id,CSW_C4 ))
		give_item(id,"weapon_c4")
		
	glow(id)

//	if( timer_started[id-1] )
//	{// 타이머 진행중 리스폰이라면 리셋된 몇가지를 다시 복귀 시켜야 타당하다
// 죽어서 리스폰인 경우는 예외
	if( health[id-1] > 0 )
		set_user_health(id,health[id-1])
//	}
	
	cs_set_user_nvg(id)
	
	if(firstspawn[id-1]) 
	{
		new num[8]
		climbstatus[id] = 0
		client_print(id,print_chat,"[Ontale*] '.menu'를 치시면 메뉴가 뜹니다.")

		scout(id) 
		// 스카웃 자동 닫힘 기능을 위해
		num_to_str( id, num, 8 )
		set_task(1.0,"scout_task",id+TASK_SCOUT,num,8,"ab")
		

		cs_set_user_money ( id, 0, 0)
		//kz_menu(id)
		if(get_pcvar_num(kz_checkpoints) == 1)
			client_print(id,print_chat,"[Ontale*] '.cp'는 체크포인트 생성, '.tp'는 체크포인트로 이동합니다.")
		else
			client_print(id,print_chat,"[Ontale*] 체크포인트 이용이 불가합니다.")
	}
	firstspawn[id-1] = false
}

// =================================================================================

public client_disconnect(id) 
{
	scout_timer[id-1] = 0 // 스카웃 메뉴 자동 종료
	climbstatus[id] = 0
	checkpointnum[id-1] = 0
	needhelp[id-1] = false
	helpcount[id-1] = 0
	health[id-1] = 0
	
	timer_started[id-1] = false
	showtimer[id-1] = false
	
	usedbutton[id-1] = false
	firstspawn[id-1] = true
	
	bhop[id-1] = 0
	
	noblock[id-1] = true
	sc[id-1] = false
	autoshowmenu[id-1] = 0

	remove_hook(id)
}

public client_putinserver(id) 
{
	health[id-1] = 0
	scout_timer[id-1] = 0 // 스카웃 메뉴 자동 종료
	climbstatus[id] = 0
	checkpointnum[id-1] = 0
	needhelp[id-1] = false
	helpcount[id-1] = 0
	
	timer_started[id-1] = false
	showtimer[id-1] = true
	
	usedbutton[id-1] = false
	firstspawn[id-1] = true
	
	bhop[id-1] = 0
	
	noblock[id-1] = true
	sc[id-1] = false
	autoshowmenu[id-1] = 1
	//kz_menu(id)

	remove_hook(id)
}

// =================================================================================

public deathmsg() 
{
	new victim = read_data(2)
	set_task(0.5,"respawn",100+victim)
}

// =================================================================================
// Menu
// =================================================================================

public kz_menu(id) {
	new menu[512], szbhop[64], sznoblock[64], szscout[64]
	
	if(get_pcvar_num(kz_semiclip) == -1)
		format(sznoblock,64,"\r01. Semiclip disabled by server\w")
	else if(get_pcvar_num(kz_semiclip) == 1)
		format(sznoblock,64,"\r01. Semiclip enabled by server\w")
	else {
		if(noblock[id-1])
			format(sznoblock,64,"\w01. 세미클립(On)\w")
		else
			format(sznoblock,64,"\d01. 세미클립(Off)\w")
	}
	// muh
	if(get_pcvar_num(kz_bhop) == 0)
		format(szbhop,64,"\r03. 버니합모드 OFF상태입니다.\w")
	else if(get_pcvar_num(kz_bhop) == 1) {
		if(bhop[id-1] == 0)
			format(szbhop,64,"\d03. Bhop\w")
		else
			format(szbhop,64,"\w03. Bhop - No Slowdown\w")
	}
	else if(get_pcvar_num(kz_bhop) == 2) {
		if(bhop[id-1] == 2)
			format(szbhop,64,"\w03. Bhop - Autojump\w")
		else if(bhop[id-1] == 1)
			format(szbhop,64,"\w03. Bhop - No Slowdown\w")
		else
			format(szbhop,64,"\d03. Bhop\w")
	}
	if( sc[id-1] == false )
	{
		format(szscout,64,"\w4. 스카웃(Scout) 받기^n      \d(랭킹 등록불가)\w")
	}
	else
		format(szscout,64,"\w4. 스카웃(Scout) 반납^n      \d(랭킹 등록가능)\w")

	format(menu,512,"\Ontale's JUMP SERVER\w^n                \dSpecial Thanks to Q(''Q)^n%s^n%s^n%s^n^n%s^n^n05. 시작지점으로^n06. 초기화(Reset)^n^n07. 1337Climber Status^n^n00. 닫기",sznoblock,showtimer[id-1] ? "\w02. 타이머 보여주기" : "\d02. 타이머 보여주기\w",szbhop,szscout)
	show_menu(id,MENU_KEYS,menu)
}

public menu_handler(id,key) {
	switch(key) {
		case 0:{
			if(get_pcvar_num(kz_semiclip) != -1 && get_pcvar_num(kz_semiclip) != 1)
				noblock[id-1] = (noblock[id-1] == false)
			
			kz_menu(id)
		}
		case 1:{
			showtimer[id-1] = (showtimer[id-1] == false)
			kz_menu(id)
		}
		case 2:{
			if(get_pcvar_num(kz_bhop) == 1) {
				if(bhop[id-1] == 0)
					bhop[id-1] = 1
				else
					bhop[id-1] = 0
			}
			else if(get_pcvar_num(kz_bhop) == 2) {
				if(bhop[id-1] == 0)
					bhop[id-1] = 1
				else if(bhop[id-1] == 1)
					bhop[id-1] = 2
				else
					bhop[id-1] = 0
			}
			kz_menu(id)
		}
		case 3:{
			if(timer_started[id-1] == true) 
			{
				client_print(id,print_chat,"[Ontale*] 이미 타이머가 작동중입니다. 초기화 하신 후 다시 시도하세요.")
				scout(id)
			} 
			else 
			{
				if( sc[id-1] == false )
				{
					give_item(id,"weapon_scout")
					sc[id-1] = true
					client_print(id,print_chat,"[Ontale*] 스카웃이 제공되었습니다. 랭킹등록 불가합니다. 반납후 가능합니다.")
				}
				else
				{
					if( user_has_weapon(id,CSW_SCOUT) )
						drop_item(id, "weapon_scout")
				/*	new Weapons[32] 
					new numWeapons, i
					get_user_weapons(id, Weapons, numWeapons) 
					strip_user_weapons ( id ) 
					for (i=0; i<numWeapons; i++) 
					{ 
					     switch( Weapons[i] )
					     {
					      case CSW_USP:
						    give_item( id, "weapon_usp" )
					      case CSW_C4:
						    give_item( id, "weapon_c4" )
					      case CSW_AWP:
					            give_item( id, "weapon_awp" )
					      case CSW_KNIFE:
						    give_item( id, "weapon_knife" )
					      }					

					}  */
					sc[id-1] = false
					client_print(id,print_chat,"[Ontale*] 스카웃이 반납되었습니다. 랭킹 참여가 가능합니다.")					
				}
			}
		}
		case 4:{
			respawn(id)
		}
		case 5:{
			reset_checkpoints(id)
		}
		case 6:{
			show_climb(id)
		}
		case 9:{
			show_menu(id,0,"")
		}
	}
}


// =================================================================================
// Show 1337 Climber Status
// =================================================================================
public show_climb(id) 
{
	new buffer[1536]
	new players[32], inum 
	get_players(players,inum)

	add(buffer,1536,"<html><head><style>")
	add(buffer,1536,"body { background-color:#000000;font-family:Tahoma;  font-size:10px; color:#FFFFFF; }")
	add(buffer,1536,".t { border-style:solid; font-size:10px;border-width:1px;}")
	add(buffer,1536,".h { background-color:#292929;font-size:10px;}")
	add(buffer,1536,".i { color:yellow; } .c { color:#ccff99; }")
	add(buffer,1536,"</style></head><body>")
	add(buffer,1536,"<center><img src='http://img255.imageshack.us/img255/482/top10logoxc7.jpg'></center><br><table border=0 cellspacing=0 cellpadding=1 width=90% align=center class=t>")	
	add(buffer,1536,"<tr><td class=h>#</td><td class=h>Name</td><td class=h>Status</td><td class=h>Climb Time</td></tr>")

//	new len = format( buffer, 2047, "<table cellspacing=0 rules=all border=2 frame=border>" )
//	len += format( buffer[len], 2047-len, "<tr><th> # <th> Nick <th> Status <th>Current Time" )

// =========== 수정 07,4,17 테스트 못해봄 ===========
// 횟수에 상관없이 고정적으로 쓰이는 변수들을 위로 올림
	new name[32]
	new j[8]
	new currenttime[32]
	new climbtime
	new status[24]
	
	for(new i = 0; i < inum; i++) 
	{
		
		if(climbstatus[players[i]] == 2)
		{
			climbtime = climbtimes[players[i]] // 가끔 게임을 하다보면 14초에 눌렀는데 15초로 판정 저장되는 경우가 많다. 아무래도 저장될때 약간 늦게 저장되면서 1초 정도 늦게 판정된거 같다. 그래서
			// 여기서 얻는 climbtimes[players[i]] 가 더 정확하다고 판단된다.
			// 결과적으로 기록이 파일로 저장될때 오차를 없애면 되겠다.

			// 등반이 완료 되었다면 그 결과가 스톱 스위치 눌렸을때의 루틴에서
			// imin과 isec에 개별 아이디별로 저장되어 있음
			format(currenttime, 31, "(%d:%f)", imin[i], isec[i] )
			format( status, 41, "Had finished map!" )
			add(buffer,1536,"<tr class='i'><td>") // 하이라이트 클래스 사용으로<font color등의 폰트 태그를 사용치 않으므로 글자수 절약
		} 
		else if( climbstatus[players[i]] == 1 ) 
		{
			climbtime =  get_systime() - timer_time[players[i]-1] // 등산할때의 1~2초 시간 오차는 아무 문제가 없음( 오차가 있는지 모르겠지만.. ) 하지만, 등산 후 결과 시간은 정확했으면 좋겠음 바로 위 조건일때..
			format(currenttime, 31, "(%d:%02d)", (climbtime/60), (climbtime%60) )
			format( status, 41, "Is Climbing, Now" )
			add(buffer,1536,"<tr class='c'><td>") // 하이라이트
		} 
		else
		{		
			format(currenttime, 31, "Not Started" )
			format( status, 41, "Not Started" )
			add(buffer,1536,"<tr><td>")
		}
		// 중복 조건을 위처럼 하나로 합침
		get_user_name(players[i], name, 32)

		format(j, 7, "%d", i + 1)
//		add(buffer,1536,"<tr><td>")
		add(buffer,1536,j)
		add(buffer,1536,"</td><td>")
		add(buffer,1536,name)
		add(buffer,1536,"</td><td>")
		add(buffer,1536,status)
		add(buffer,1536,"</td><td>")
		add(buffer,1536,currenttime)
		add(buffer,1536,"</td></tr>")
		// format(line, 255, "<tr><td> %d. <td> %s <td> %s <td> %s", (i+1), name, status, currenttime)			
		// len += format( buffer[len], 2047-len, line )
	}
	// format(line, 255, "</table>" )
	// len += format( buffer[len], 2047-len, line )		
	add(buffer,1536,"</table><br><br><font color=yellow>*yellow-color means 1337 climber!</font></body></html>")
	show_motd(id, buffer, "1337 Climber Status")  
} 

// =================================================================================
public kz_menu_admin_show(id,level,cid) {
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
		
	kz_menu_admin(id)
	
	return PLUGIN_HANDLED
}

// =================================================================================
public kz_menu_admin(id) {
	new menu[512], szcheckpoints[32], szgodmode[32], szhelp[32], szscout[32], szadminglow[32], sznoblock[32], sztransparency[32], szcheatdetect[32], szbhop[32]
	// this is the onliest fucking way.. else pawn tells me that the line is too long :o
	
	if(get_pcvar_num(kz_checkpoints) == 1)
		format(szcheckpoints,32,"\w01. Checkpoints\w")
	else
		format(szcheckpoints,32,"\r01. Checkpoints\w")
		
	if(get_pcvar_num(kz_godmode) == 1)
		format(szgodmode,32,"\w02. Godmode\w")
	else
		format(szgodmode,32,"\r02. Godmode\w")
		
	if(get_pcvar_num(kz_help) == 1)
		format(szhelp,32,"\w03. Help\w")
	else
		format(szhelp,32,"\r03. Help\w")
		
	if(get_pcvar_num(kz_scout) == 1)
		format(szscout,32,"\w04. Scout\w")
	else
		format(szscout,32,"\r04. Scout\w")
		
	if(get_pcvar_num(kz_adminglow) == 1)
		format(szadminglow,32,"\w05. Adminglow\w")
	else
		format(szadminglow,32,"\r05. Adminglow\w")
	
	if(get_pcvar_num(kz_semiclip) == -1)
		format(sznoblock,32,"\r06. Semiclip\w")
	else if(get_pcvar_num(kz_semiclip) == 1)
		format(sznoblock,32,"\w06. Semiclip\w")
	else
		format(sznoblock,32,"\w06. Semiclip - Client\w")
		
	if(get_pcvar_num(kz_bhop) == 0)
		format(szbhop,32,"\r07. Bhop\w")
	else if(get_pcvar_num(kz_bhop) == 1)
		format(szbhop,32,"\w07. Bhop - No Slowdown\w")
	else if(get_pcvar_num(kz_bhop) == 2)
		format(szbhop,32,"\w07. Bhop - Autojump\w")
		
	if(get_pcvar_num(kz_transparency) == 1)
		format(sztransparency,32,"\w08. Transparency\w")
	else
		format(sztransparency,32,"\r08. Transparency\w")
		
	if(get_pcvar_num(kz_cheatdetect) == 1)
		format(szcheatdetect,32,"\w09. Cheatdetect\w")
	else
		format(szcheatdetect,32,"\r09. Cheatdetect\w")
	
	format(menu,512,"^n^n^n\yProKreedz by ontale - Adminmenu^n^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n^n00. Close",szcheckpoints,szgodmode,szhelp,szscout,szadminglow,sznoblock,szbhop,sztransparency,szcheatdetect)
	show_menu(id,MENU_KEYS_ADMIN,menu)
}

public menu_handler_admin(id,key) 
{
	switch(key) {
		case 0:{
			if(get_cvar_num("kz_checkpoints") == 0) {
				set_cvar_num("kz_checkpoints",1)
				client_print(0,print_chat,"[ProKreedz] Checkpoints are enabled now")
				client_print(0,print_chat,"[ProKreedz] Type '.cp' to create a checkpoint and '.tp' to go to your last one")
			}
			else {
				set_cvar_num("kz_checkpoints",0)
				client_print(0,print_chat,"[ProKreedz] Checkpoints are disabled now")
			}
			kz_menu_admin(id)
		}
		case 1:{
			if(get_cvar_num("kz_godmode") == 0) {
				set_cvar_num("kz_godmode",1)
				client_print(0,print_chat,"[ProKreedz] Godmode is enabled now")
				
				for(new i=1;i<=get_maxplayers();i++) {
					if(is_user_connected(i))
						set_user_godmode(id,1)
				}
			}
			else {
				set_cvar_num("kz_godmode",0)
				client_print(0,print_chat,"[ProKreedz] Godmode is disabled now")
				
				for(new i=1;i<=get_maxplayers();i++) {
					if(is_user_connected(i))
						set_user_godmode(id,0)
				}
			}
			kz_menu_admin(id)
		}
		case 2:{
			if(get_cvar_num("kz_help") == 0) {
				set_cvar_num("kz_help",1)
				client_print(0,print_chat,"[ProKreedz] Backup is enabled now")
				client_print(0,print_chat,"[ProKreedz] Type '.help' if you need help")
				for(new i=1;i<=get_maxplayers();i++) {
					if(is_user_connected(i))
						glow(i)
				}
			}
			else {
				set_cvar_num("kz_help",0)
				client_print(0,print_chat,"[ProKreedz] Backup is disabled now")
				for(new i=1;i<=get_maxplayers();i++) {
					if(is_user_connected(i))
						glow(i)
				}
			}
			kz_menu_admin(id)
		}
		case 3:{
			if(get_cvar_num("kz_scout") == 0) {
				set_cvar_num("kz_scout",1)
				client_print(0,print_chat,"[ProKreedz] You will get a scout after respawn")
			}
			else {
				set_cvar_num("kz_scout",0)
				client_print(0,print_chat,"[ProKreedz] You will no longer get a scout")
			}
			kz_menu_admin(id)
		}
		case 4:{
			if(get_cvar_num("kz_adminglow") == 0) {
				set_cvar_num("kz_adminglow",1)
				client_print(0,print_chat,"[ProKreedz] Admins glow green now")
				
				for(new i=1;i<=get_maxplayers();i++) {
					if(is_user_connected(i))
						glow(i)
				}
			}
			else {
				set_cvar_num("kz_adminglow",0)
				client_print(0,print_chat,"[ProKreedz] Admins are no longer glowing")
				
				for(new i=1;i<=get_maxplayers();i++) {
					if(is_user_connected(i))
						glow(i)
				}
			}
			kz_menu_admin(id)
		}
		case 5:{
			if(get_cvar_num("kz_semiclip") == -1) {
				set_cvar_num("kz_semiclip",0)
				client_print(0,print_chat,"[ProKreedz] Semiclip is enabled now. Type '.menu' to enable/disable it")
			}
			else if(get_cvar_num("kz_semiclip") == 0) {
				set_cvar_num("kz_semiclip",1)
				client_print(0,print_chat,"[ProKreedz] Semiclip is enabled now")
			}
			else {
				set_cvar_num("kz_semiclip",-1)
				client_print(0,print_chat,"[ProKreedz] Semiclip is disabled now")
			}
			kz_menu_admin(id)
		}
		case 6:{
			if(get_cvar_num("kz_bhop") == 0) {
				set_cvar_num("kz_bhop",1)
				client_print(0,print_chat,"[ProKreedz] Bhop (No Slowdown) is enabled now")
			}
			else if(get_cvar_num("kz_bhop") == 1) {
				set_cvar_num("kz_bhop",2)
				client_print(0,print_chat,"[ProKreedz] Bhop (Autojump) is enabled now")
			}
			else {
				set_cvar_num("kz_bhop",0)
				client_print(0,print_chat,"[ProKreedz] Bhop is disabled now")
			}
			kz_menu_admin(id)
		}
		case 7:{
			if(get_cvar_num("kz_transparency") == 0) {
				set_cvar_num("kz_transparency",1)
				client_print(0,print_chat,"[ProKreedz] If someone activates semiclip he will be transparent")
			}
			else {
				set_cvar_num("kz_transparency",0)
				client_print(0,print_chat,"[ProKreedz] If someone activates semiclip he won't appear transparent any longer")
			}
			kz_menu_admin(id)
		}
		case 8:{
			if(get_cvar_num("kz_cheatdetect") == 0) {
				set_cvar_num("kz_cheatdetect",1)
				client_print(0,print_chat,"[Ontale*] 치트방지모드가 활성화 되어있습니다.")
			}
			else {
				set_cvar_num("kz_cheatdetect",0)
				client_print(0,print_chat,"[ProKreedz] Anti-Cheat is disabled now")
			}
			kz_menu_admin(id)
		}
		case 9:{
			show_menu(id,0,"")
		}
	}
}

// =================================================================================
// Timersystem
// =================================================================================
// 현재 3가지 종류의 버튼중 현재 월드안에 존재하는 버튼의 종류를 찾아 번호를 넘겨준다(target)

// RIKO님이 데모에서처럼 벽을 통한 스톱 스위치 작동이 가능했으면 한다고하여 그렇게 바꾸었다.
// prokreedz 에선 aim으로 타겟을 지정했을때만 즉, 스톱이나 시작 버튼을 조준하고 있을때만이 가능하다
// 게다가 장애물이 가리고 있다면 그 aim은 0을 가리키게되어 벽을 통한 스위치 유무를 판단하지 못했다.
// 그래서 그 부분을 수정하고 약간의 세팅을 하였다.

// 데모( 맵 디폴트 버튼 거리 )를 조율한 결과 64라는 거리를 얻었다.
// 이 거리는 E 버튼을 눌렀을시 스톱이나 시작 버튼이 "뚜" 라고 작동음을 발생시키는 최장 거리이다.

// 버그 발견

// "firsttimerelay" 이 스위치를 찾을 때 문제가 발생했다.(kz_cellblock 의 버튼 같은 경우다 ) 
// find_ent_by_target 함수의 버그인 것으로 판단되는데
// start 스위치만 인덱스가 실제 대상의 인덱스보다 241 낮게 주어진다는 것이다.
// 다행이도 버그가 규칙적이라 판단되어 스타트 스위치에 241만 더해주면 해결된다.

// 추가 ( kz_cellblock ) + 241

// "firsttimerelay" 버튼도 또 한 종류가 아니라 지금 까지 두 종류 발견했는데
// 후자의 것은 정상적인 인덱스를 찾고 있다.
// 고로 241을 바로 더해줄 것이 아니라( 후자의 것에선 정상 인덱스에 추가되는 것 이므로 )
// 실제 주변에 스위치가 있고 그것이 시작이나 종료인지 확인하는 부분에서 먼저 기본 인덱스를 판단해보고
// 문제가 있다면 241 더한 인덱스를 확인해보면 큰 무리없이 지금 과정에선 해결 된다.
// ( ( detectS = find_ent_in_sphere(start-1,origin,BUTTON_DISTANCE) ) == start || detectS == start + 241 )
// 이 부분이 그 것이다.

// 추가 203 ( kz_real_islands )
// 추가 203 ( sn_mountsnow ) 버튼 스타일이firsttimerelay 는 맞는데 외형은 counter_start 랑 유사
// 318 sn_beachcliff 테스트 필요 

// 쭉 맵을 해보니 start 

public search_button( id, &start, &end )
{
	if( ( start = find_ent_by_target(0,"counter_start") ) )
	{
		client_print(id,print_chat,"이 버튼 counter_star" )
		end = find_ent_by_target(0,"counter_off") 
		return true
	}
	else if( ( end = find_ent_by_target(0,"clockstop") ) )
	{
		client_print(id,print_chat,"이 버튼은 'firsttimerelay'" )
		new Float:origin[3]
		entity_get_vector(id,EV_VEC_origin,origin)

		start = find_ent_by_target(0,"firsttimerelay")
		if( !(find_ent_in_sphere(start-1,origin,BUTTON_DISTANCE ) == start) )
			start = find_ent_by_target( start+1,"firsttimerelay")
		return true
	// 최종 정리 
	// "firsttimerelay" 스타일의 버튼을 쓰는 맵은 같은 이름의 entity 가 3개가 있다.(예외도 있음)
	// 먼저 처음 한개를 지나 바로 +1 번호로 같은 이름의 버튼 이름 entity가 또 있다.
	// 하지만 이 둘은 실제 눌려지는 스위치가 아니다
	
	// 이를 넘어 3번째 버튼의 index를 얻어 사용하면 정상 작동 된다.
	// 좀 더 간단한 규칙이 있다면 찾아 수정하도록 하자.
	}
	else  if( ( start = find_ent_by_target(0,"clockstartbutton") ) )
	{
		client_print(id,print_chat,"이 버튼 clockstartbutton!" )	
		end = find_ent_by_target(0,"clockstopbutton")
		return true
	}
	else  if( ( start = find_ent_by_target(0,"multi_start") ) )
	{ // kz_kzfr_nuke 맵 스타일 버튼 
		client_print(id,print_chat,"이 버튼 multi_start" )	
		end = find_ent_by_target(0,"multi_stop")
		return true
	}

	return false
}

	new v

public client_PreThink(id) 
{
	if(get_pcvar_num(kz_bhop) > 0 && bhop[id-1] > 0)
		entity_set_float(id,EV_FL_fuser2,0.0)
		
	new buttons = get_user_button(id)
	
	if(get_pcvar_num(kz_bhop) == 2 && bhop[id-1] == 2) 
	{
		if(buttons&IN_JUMP) 
		{ // Credits to ts2do (cs13 plugin)
			new flags = entity_get_int(id,EV_INT_flags)
			if(flags&FL_ONGROUND && flags|FL_WATERJUMP && entity_get_int(id,EV_INT_waterlevel)<2) 
			{
				new Float:velocity[3]
				entity_get_vector(id,EV_VEC_velocity,velocity)
				velocity[2] += 260.0
				entity_set_vector(id,EV_VEC_velocity,velocity)
				entity_set_int(id,EV_INT_gaitsequence,6) // Play the Jump Animation
			}
		}
	}

	if(buttons&IN_USE) 
	{
		//client_print(id,print_chat,"FFFFFFFFFFFFFFFFF %d", v++)
		if(!usedbutton[id-1]) 
		{
			usedbutton[id-1] = true
		//	client_print(id,print_chat,"TTTTTTTTTTTTTTTT")
			new start, end
				
			if( search_button( id, start, end ) )// 어떤 버튼이건 찾았다면
			{//************* 나중에 맵이 바뀌었을ㄸ 자동으로 버튼 번호를 갱신해서 담아두고 쓰는 식으로하면
			 // 재차 검색해서 쓸 필요 없겠다.
				new Float:origin[3]
				entity_get_vector(id,EV_VEC_origin,origin)
				
				client_print(id,print_chat,"find_ent : %d  start : %d end : %d",( find_ent_in_sphere(start-1,origin,BUTTON_DISTANCE) ),start, end )	
			
				if( ( !timer_started[id-1] ) && ( find_ent_in_sphere(start-1,origin,BUTTON_DISTANCE ) == start ) ) 
				{ // Man hat den Startbutton gedrueckt // 스타트 버튼 눌렀을때
					if(checkpointnum[id-1] < 1) 
					{
						new bool:clean = true

						if(get_pcvar_num(kz_cheatdetect) == 1) 
						{
							if(get_user_noclip(id) == 1) 
							{
								client_print(id,print_chat,"[Ontale*] 노클립(Noclip) 상태이므로 시작할 수 없습니다.")
								clean = false
							}
							else if(get_user_gravity(id) != 1.0) 
							{
								client_print(id,print_chat,"[Ontale*] 당신의 중력이 변경되었으므로 시작할 수 없습니다.")
								clean = false
							}
							else 
							{ // Now we check, whether the client uses hook or is grabbed :o
								if(callfunc_begin("is_hooked","prokreedz_hook.amxx") == 1) 
								{
									callfunc_push_int(id)
									if(callfunc_end()) 
									{
										clean = false
										client_print(id,print_chat,"[Ontale*] 훅(hook) 권한을 갖고 있기 때문에 시작할 수 없습니다.")
									}
								}
								else if(callfunc_begin("is_user_grabbed","prokreedz_grab.amxx") == 1) 
								{ // maybe it doesn't work Oo
									callfunc_push_int(id)
									if(callfunc_end() != -1) 
									{
										clean = false
										client_print(id,print_chat,"[Ontale*] grab 권한을 갖고 있으므로 시작할 수 없습니다.")
									}
								}
							}
						}

						if(clean) // 체크 포인트가 없을때
						{
							timer_time[id-1] = get_systime()
							client_print(id,print_center,"[ 00 분 00 초 ]")
							client_cmd(id, "spk radio/letsgo.wav" )
							client_print(id,print_chat,"[Ontale*] 타이머가 시작되었습니다. 출발하세요 :)")
							climbstatus[id] = 1
							//climbtimes[id-1] = get_user_time(id)
						
							climbtimes[id-1] = engfunc( EngFunc_Time )// 시간 정밀도 소수점 아래 6자리까지 
							if( !user_has_weapon(id,CSW_C4 ) )
								give_item(id,"weapon_c4")
							if( get_user_health(id) < 200 )
								set_user_health(id, 200)
							give_item(id,"item_assaultsuit")
							cs_set_user_bpammo( id, CSW_USP, 120 )
	
							client_print(id,print_chat,"climbtimes[id-1] : %f", climbtimes[id-1] )
							timer_started[id-1] = true
							bbazk(id) // 빠찡꼬
							weappickup(id) // 스카웃 확인
						}
					  }
					  else 
					  {
						client_print(id,print_chat,"[Ontale*] 이미 체크포인트가 생성되어 있으므로 '.reset'을 치시고 시작하세요.")
					  }
				}

				// 역시 엔드 버튼을 찾았고 근접해 있다면 
				if( ( timer_started[id-1] )&&( find_ent_in_sphere(end-1,origin,BUTTON_DISTANCE) == end ) ) 
				{ // Man hat den Stopbutton gedrueckt // 스톱 버튼을 눌렀을때
					new name[32]
					// 실제 timer_task가 중앙에 등반중 시간을 표시하고 있는데
					// 그곳에서는 서버 시간으로 계산하고
					// 등산후엔 유저 시스템 시간으로 책정하고 있다.
					//climbtime= (get_user_time(id) - climbtimes[id-1])
					// 스타트 버튼을 누른후 스톱 버튼을 누르기 까지 소요된 시간 
				
					client_print(id,print_chat,"engfunc( EngFunc_Time ) : %f",engfunc( EngFunc_Time ))
					client_print(id,print_chat,"climbtimes[id-1] : %f", climbtimes[id-1] )
					// 만약 0시경에 갱신되면 문제 소지 있음 ( **** 추가 ***** )
					// 차 구한 뒤 절대값
					climbtimes[id-1] = floatabs( floatsub( engfunc( EngFunc_Time ), climbtimes[id-1] ) )
					climbstatus[id] = 2
					
					// ex) 61.541523 라면 어떻게 시간을 분리해 내어야 할까?
					// 먼저 이는  1분 1.541523초라 표기되어야 하는데
					// 소수점 아래는 일단 모두 버리고 60으로 나누어 분을 구한다.(1분)
					// 그 분을 구한 뒤 분에 60을 곱하여 초로 바꾼뒤 제하여
					// 61.561523 - (1분*60) = 1.561523
					// 초를 구한다.
					client_print(id,print_chat,"climbtimes[id-1] : %f", climbtimes[id-1] )
					isec[id-1] = climbtimes[id-1] // 61.541523
					imin[id-1] = floatround(isec[id-1] ,floatround_floor) // 61
					imin[id-1] = floatround(imin[id-1] / 60.0,floatround_floor)//1
					isec[id-1] = floatsub( isec[id-1], (imin[id-1] * 60.0) )

//					isec[id-1] -= imin[id-1] * 60 // 61.541523 - (1*60) = 1.541523 BUG

// 스톱 누르고 이전 타이머 초기화 제대로 해야 되겠다.
// 다시 스타트 누를때 이전 기록이 나온다는 경우가 있었음
//605.130859
//10:
					client_print(id,print_center,"[ %d 분 %f 초 ]",imin[id-1],isec[id-1])

					get_user_name(id,name,32)
					timer_started[id-1] = false
				
					// 마지막 등반 완료 시간 표시( 동기화 문제 있음 )
					

					if(sc[id-1] == true) 
					{
						client_print(0,print_chat,"[Ontale*] %s님이 %d분 %f초 (%d번의 체크포인트 생성)만에 도착하였습니다. (Scout 사용)",name,imin[id-1], isec[id-1] ,checkpointnum[id-1]) // kreedztime ist in diesem Fall die uebrigen Sekunden
					} 
					else 
					{
						client_print(0,print_chat,"[Ontale*] %s님이 %d분 %f초 (%d번의 체크포인트 생성)만에 도착하였습니다.",name,imin[id-1], isec[id-1] ,checkpointnum[id-1])
					}
					
					topten_update(id)

				}
			}//findit
		}//if(!usedbutton[id-1]) 
	}
	else
		usedbutton[id-1] = false
}

// =================================================================================================
// Top10
// =================================================================================================

getTopTenPlace(id) 
{        
    new currentMap[32], authid[32]
    get_mapname(currentMap, 32)
    get_user_authid( id, authid ,31 )
    
    new userName[32]
    get_user_name(id, userName, 32)

    new topTenVault[64];
    format(topTenVault, 64, "pk_%s", currentMap);
  
 //   kzTime = get_systime() - timer_time[id-1];
    
    new vault = nvault_open(topTenVault);
    new vaultKey[8];
    new vaultReturn[128];
    //=====================================
    new arg1[32], arg2[32], arg3[8], arg4[32]; //arg3추가
    
 //   new ret=0;

    if(vault != INVALID_HANDLE) 
    {    
        for(new i = 1; i <= MAX_TOP; i++) 
	{
            format(vaultKey, 8, "%d", i); 
            nvault_get(vault, vaultKey, vaultReturn, 128);
            
            if(parse(vaultReturn, arg1, 32, arg2, 32, arg3,8, arg4, 32) != 0) // 추가
	    {	
		new float:reTime = str_to_float(arg2)
                // 이전의 경우 시간이 같을 확률이 좀 있었지만
		// 초 정밀도가 높아지면서 같아질 확률 아예 없다고 판단
		// 같은 경우 처리를 완전 삭제할 생각이다.
		if( floatcmp( climbtimes[id-1], reTime ) == -1 ) // || ( floatcmp( kzTime, reTime ) == 0 ) ) //변경
		{
		/*  if( floatcmp( kzTime, reTime ) == 0 ) // 추가
		    {//시간이 같을때
		           if( checkpointnum[id-1] < str_to_num(arg3) )
			   {
			        nvault_close(vault);
				return i;
			   }
		    }
		    else
		    {
		  */
			   nvault_close(vault)
			   return i
		 // }
                } 

		//if( equal( arg4, authid ) )
		if( equal( arg1, userName ) )
		{ // 비교 대상이 본인이었음에도 나아지지 못했다면 갱신할 필요가 없다. 
			 nvault_close(vault)
			 return -1
		}
            } 
	    else 
	    {//현재 순위권자들보다 빠르진 않았지만 순위권인 경우
	    // 다시말해  if(parse(vaultReturn, arg1, 32, arg2, 8, arg3,8, arg4, 32) != 0) 에서
	    // 0으로 판정되는 즉, 데이터가 없는 경우 그 데이터 없는 곳에 위치하게 된다
                nvault_close(vault);
		return i;           
            }        
        }// for
	nvault_close(vault) // 오류가 안난경우에만 닫는다.
    }// if(vault != INVALID_HANDLE)    
    
    return -1; // 순위에 못들었을때 갱신 할 필요 없음
}

// ==================

isPlayerInTopTen(id) 
{
    new userName[32]
    get_user_name(id, userName, 32)

    new currentMap[32]
    get_mapname(currentMap, 32)
    
    new topTenVault[64];
    format(topTenVault, 64, "pk_%s", currentMap)
    
    new vault = nvault_open(topTenVault)
    new vaultKey[8]
    new vaultReturn[128]
  //=======================================================================
    new arg1[32]//, arg2[32],arg3[8], arg4[32] // 변경
    new authid[32] // 2) 추가
    get_user_authid( id, authid ,31 )
//=======================================================================
    
    new ret
    
    if(vault != INVALID_HANDLE) 
    {
        for(new i = 1; i <= MAX_TOP; i++) 
	{
            format(vaultKey, 8, "%d", i)   
            nvault_get(vault, vaultKey, vaultReturn, 128)
            

   //       if(parse(vaultReturn, arg1, 32, arg2, 32, arg3,8, arg4,32 ) != 0 && equal(authid, arg4)) 
   //       {

	    // 테스트용( 고유 아이디로 갱신 사용안함)
	    // if(parse(vaultReturn, arg1, 32, arg2, 32) != 0 && equal(userName, arg1)) 
	    // 근데 왜 이름만 비교하면 되는데 시간까지 받고 있었지?
	    // 삭제한다.

//	    *******************************
	    // 나중에는 다 받아야 될 듯 고유 아이디가 맨 마지막이니..( 필요에따라 앞으로 수정 요망 )
	    if(parse(vaultReturn, arg1, 32) != 0 && equal(userName, arg1)) 
	    {
                ret = i
                break
            }
//==================== 수정 수정 수정 수정 수정 =======================================================	 
// 맵 레코드 데이터에 기록 수를 저장해서 사용하자 코드가 많이 바뀔 것 같으니 
// 지금 생긴 문제는 이후에 생각하기로 하자.
// 제일 먼저 맵 레코드 데이터에 데이터 기록 
// 데이터를 읽어들여 최대한 활용
// 불필요한 코드 삭제
// 최적화
	    else if( equal(vaultReturn, "") )
	    {
                ret = i+100; // 임시로 100으로 조건 분기하게 만들기 위해서 
		// 100 보다 크다는 건 빈 공간은 있지만 oldPlace의 의미는 아니라는 것
		break;
//==================== 수정 수정 수정 수정 수정 =======================================================	    
            }
	    else
		ret = 0; // 탑30 다 찼고 플레이어는 없음
        }
    
    }
    
    nvault_close(vault);
    
    return ret;
}

// ==================

showTime(id, newPlace) 
{
    if(sc[id-1] == true) 
    { // scout checking
//	client_print(id,print_chat,"[Ontale*] 스카웃을 받으셨기 때문에 랭킹등록이 불가합니다. 재접속을 하면 사라집니다.");
    } 
    else 
    {
	   new userName[32];
	   get_user_name(id, userName, 32);

	   if(newPlace == 1)
	   {
               client_print(0,print_chat,"[Ontale*] %s 님이 신기록을 세우셨습니다! 축하합니다! ",userName);
        
           } 
           else if( newPlace > 1 ) 
           {
               client_print(0,print_chat,"[Ontale*] %s님이 Top30에 속하는 기록을 세우셨습니다! 축하합니다!", userName);
           }
     } 
} 

// ==================

public topten_update(id) 
{
    rank_to_point( id ) // 기본 도착 순서 포인트 제

    new newPlace = getTopTenPlace(id);   

    if( newPlace > 0 ) // 기록이 오히려 나빠졌을땐 newPlace를 -1로 한다. 기록될 새로운 위치가 없다는 뜻이다.
    {
	 if(sc[id-1] == true) 
	 { // scout checking
	    	client_print(id,print_chat,"[Ontale*] 스카웃을 반납하고 랭킹 기록에 도전해보세요.( %d위 성적 달성 )", newPlace);
	 }
	 else
	 {
		new oldPlace = isPlayerInTopTen(id);
		new userName[32], currentMap[32], authid[32]

	        get_user_name(id, userName, 32);
		get_mapname(currentMap, 32);
		get_user_authid( id, authid ,31 )
		
		// 정밀도 높임.. 기록 전 수정 // showtop도 수정 요망
		new float:kzTime = climbtimes[id-1] // 수정, 모든 판정되고 기록되는 시간 climbtimes[id-1] 로 통일
		client_print(id,print_chat,"climbtimes[id-1] : %f kzTime : %f", climbtimes[id-1], kzTime  );	
		new vaultEntry[128]; // 1) 고유 아이디를 마지막에 기록 해둔다
		// username, kzTime, checkpointnum[id-1], authid 
		format(vaultEntry, 128, "^"%s^" ^"%f^" ^"%d^" ^"%s^"", userName, kzTime, checkpointnum[id-1], authid);

		new vault
		new key[8]    

       		new topTenVault[64];
		format(topTenVault, 64, "pk_%s", currentMap);
		topten_point( id, newPlace, oldPlace ) // 포인트 기록 수정되기 전에 적용

		//{    // 새로 기록되거나, 이전보다 상위이거나, 같은 순위에 기록만 좋아지거나

		// 이건 단지 포인트 적용시 필요한 부분이라 해재(-100)
		if( oldPlace > 100 )
			oldPlace -= 100
	
		vault= nvault_open(topTenVault);
		for(new i = oldPlace; i > newPlace; i--)
		{
		new temp[128], tempKey[8]
		format(tempKey,8,"%d",i-1)           
		nvault_get(vault,tempKey,temp,128)
		format(tempKey,8,"%d",i)         
		nvault_pset(vault,tempKey,temp)                   
		}

		format(key, 8, "%d", newPlace); 
		nvault_pset(vault, key, vaultEntry); // 요 부분에서 새로운 위치에 데이터 삽입     
		nvault_close(vault);   	       
		showTime(id, newPlace);
	 }
    }
}

//xyz
public top_show(id, level) 
{
//xyz
	new motd[1536] //버퍼 크기를 줄임으로 할당되는 메모리량을 줄임( 실제 show_motd가 수용할 수 있는 글자가 1200자 안팍이지만 엔터나 빈 공간은 포함되지 않을때 1200자 인것 같다. 고로 고려하여 1536정도면 충분할 것 같다. 실제 이들을 고려하여 1516이란 사람도 있었다.)
	new szvault[64], szmap[32]
	get_mapname(szmap,32)
	format(szvault,64,"pk_%s",szmap)
	
	//xyz // 자신의 순위는 하이라이트하기 위해
	new authid[32] // 고유 아이디
	get_user_authid( id, authid ,31 )

	new userName[32]; // test용 [Ontale*] %s님은 순위에 없습니다.", 에서 사용됨
	get_user_name(id, userName, 32);
	new isRank=0; // 랭크용일때 참
	
	// rank 루틴일때 1,2,3위 빼곤 모두 4번째에 위치하여 현재 순위를 명시한다.
	if( level == 0 )
	{
		// 랭크용
		new myRank = isPlayerInTopTen( id )
		if( !( (myRank > 100) || (myRank == 0) ) )
		{	
			level = myRank - 3
			if( level < 1 )
			    level = 1
			isRank=1
		}
		else
		{
			client_print(id,print_chat,"[Ontale*] %s님은 순위에 없습니다.", userName)
			return 0;
		}
	}
	//xyz

	new vault = nvault_open(szvault)
	if(vault != -1) 
	{
		add(motd,1536,"<html><head><style>")
		add(motd,1536,"body { background-color:#000000;font-family:Tahoma;  font-size:10px; color:#FFFFFF; }")
		add(motd,1536,".t { border-style:solid; font-size:10px;border-width:1px;}")
		add(motd,1536,".h { background-color:#292929;font-size:10px;}")
		add(motd,1536,".i { color:yellow; }")
		add(motd,1536,"</style></head><body>")
		add(motd,1536,"<center><img src='http://img255.imageshack.us/img255/482/top10logoxc7.jpg'></center><br><table border=0 cellspacing=0 cellpadding=1 width=90% align=center class=t>")
		add(motd,1536,"</td></tr><tr class=h><td>#</td><td>Name</td><td>Time</td><td>Checkpoints</td></tr>")
		new szkey[8]
		
		for(new i=level;i<=(level+9);i++) 
		{
			new szreturn[128]
			format(szkey,8,"%d",i)
			nvault_get(vault,szkey,szreturn,128)
			//xyz 
			if( equal(szreturn,"") ) // 탑 쇼를 하기위해 리스트를 만들때 만약 빈 공간이라면 이후 랭킹이 없는 것이므로 종료하고 랭크된 순위까지만 출력한다.
				break;
			//xyz
			new arg1[32], arg2[32], arg3[8], arg4[32]
			if(parse(szreturn,arg1,32,arg2,32,arg3,8,arg4,32) != 0) 
			{
			//xyz
				new sztime[32]
				new float:isec
				new imin

				isec = str_to_float( arg2 ) // 61.541523
				imin = floatround(isec, floatround_floor) // 61
				imin = floatround(imin / 60.0,floatround_floor)//1
				isec = floatsub( isec, (imin * 60.0) )
				//isec -= imin * 60 // 61.541523 - (1*60) = 1.541523

				format(sztime,32,"%d min %f sec",imin,isec)

				if( equal(arg1,userName) ) // 테스트 끝나면 equal(arg1,userName)를 equal(arg4,authid) 로 교체 
				    add(motd,1536,"<tr class=i><td>") //해당 이용자의 순위일 경우 하이라이트	
				else
				    add(motd,1536,"<tr><td>")
			        add(motd,1536,szkey)
			        add(motd,1536,"</td><td>")
			        add(motd,1536,arg1)
			        add(motd,1536,"</td><td>")
			        add(motd,1536,sztime)
			        add(motd,1536,"</td><td>")
			        add(motd,1536,arg3)
	  		        add(motd,1536,"</td></tr>")
			}
		}
		
		nvault_close(vault)
		
		add(motd,1536,"</table></body></html>")
		if( isRank == 1  )
		{
			show_motd(id,motd,"RANK");
		}
		else
		{
			switch( level )
			{
			   case 1:{
				show_motd(id,motd,"TOP10")
				}
			   case 11:{
				show_motd(id,motd,"TOP20")
				}
			   case 21:{
				 show_motd(id,motd,"TOP30")
				 }		   			
			}
		}
	}
	return 0
}
//xyz
// 한 화면에 30위까지 모두 출력하려 했으나
// 출력하는 함수인 show_motd함수가 최대 수용할 수 있는 글자수가 1200개 안팍이라한다.
// 고로 그 이상의 글자수 대략 탑 12위 정도까지 출력하려 했을때 오탈자가 생기고 테이블이 깨지는 버그가
// 발생했다.
// 스크립트 한계상 show_motd함수를 수정할 수 없기에 아래와 같이 하였다.
public topten_show( id )  // 1~10위까지
{
	top_show( id, 1 );
}

public toptwenty_show( id ) // 11~20위까지
{
	top_show( id, 11 );
}

public topthirty_show( id ) // 21~30위까지
{
	top_show( id, 21 );
}

public rank_show( id )
{
	top_show( id, 0 );
}
//xyz


//====================== [근성 포인트] 제도 =========================
// 작성일 07.4.18
// $포인트 제도의 개요$ 
// 서버에 접속하면 융통성 있게(포인트를 보려하거나 새로운 포인트 기록 조건에 부합할때) 고유아이디 기반으로 개인 파일이 생성된다.
// 이 파일명은 고유아이디로 할 생각이다.
// 해당 파일은 해당 이용자의 포인트 정보를 담을 것이다.
// 이 파일을 읽고 씀으로해서 앞으로 구현할 포인트 제도가 구현 가능해 지는 것이다.
//
// 첫째로, 등반 완료시 순위에 따른 적절한 포인트를 획득 할 수 있다.
// 이 경우 만약 5위를 했다면 그에 따른 점수를 받고 이후 5위 이상으로 갱신되지 않는다면
// 추가 포인트가 없다. 이는 각 맵별로 이루어진다. 적절한 포인트 분배를 요한다.
// 포인트는 새로운 포인트 순위를 만들어 낼 것이다.
// 둘째로, 포인트로 여러가지 기능을 살 수가 있다.
// 등반을 완료시 매점 기능을 활성화하여 훅이나 낙하산 또는 약간의 총들을 포인트를 할애하여 살 수 있게한다.
// 셋째로, 포인트를 놓고 서로 배틀을 할 수 있게 한다.
// 예로 랜덤 또는 1:1 지명 또는 1:1:1 로 서로 신청하고 응해서 조건에 합당하다면
// 적절하게 대결 할 수 있게하여 순위별로 서로의 포인트를 나누어 가지게 하는 것이다.
// 예를 들자면, 1:1은 100% 승자에게 1:1:1은 1위 70% 2위 30% 3위 0%를 획득한다.
//
// $작업일지$
// 070418
// 프로파일을 읽고 쓰는 것 작성
// tip) 전체 포인트 순위를 위해 전체 목록 따로 유지할 필요 있음 
// 프로필 데이터를 얻는다.
// str은 읽어올 문자열 버퍼, len 은 그 길이
// str[128] 이라면
// get_profile( id, str, 128 )로 호출하면 해당 유저의 데이터를 읽어올 수 있다.

public get_profile( id, str[], len, key )
{	
	new authid[32] // 고유 아이디
	get_user_authid( id, authid ,31 )

	new fileName[32];
	
// 파일명으로 쓸 수 있게 ':' 문자 0으로 대채
// 루프를 돌릴 필요 없이 위치는 고정적인 것 같다.
	authid[7] = '0'
	authid[9] = '0'

	format( fileName, 31, "pt_%s", authid )

	new szTemp[128]; //데이터를 담을 공간
	new tempKey[8];

	new vault = nvault_open(fileName) // 파일이 없을시 자동 생성
	if( vault != INVALID_HANDLE ) 
	{
		format(tempKey,7,"%d",key)
		nvault_get(vault,tempKey,szTemp,128) // 데이터 읽어오기
		if( equal( szTemp,"" ) && (key==POINT) ) // 처음 만들어졌고 POINT 값을 얻으려 할때
			format( str,(len-1),"%s","50" ); // 기본 50점
		else
			format( str,(len-1),"%s",szTemp ); // str로 읽혀진 데이터 복사 
		nvault_close(vault) // 파일 닫기
		
		return 1;
	}
	else
		client_print(id,print_chat,"파일 오픈 실패 id %d", id);

	return 0;
}

// 프로필을 쓰는 함수
public set_profile( id, str[], key )
{
	new authid[32] // 고유 아이디
	get_user_authid( id, authid ,31 )

	new fileName[32];

	authid[7] = '0'
	authid[9] = '0'

	format( fileName, 31, "pt_%s", authid )

	new tempKey[8];

	new vault = nvault_open(fileName) // 파일이름이 없을시 자동 생성
	if( vault != INVALID_HANDLE ) 
	{
		format(tempKey,7,"%d",key)
		nvault_pset(vault,tempKey,str) // 데이터 쓰기
		nvault_close(vault) // 파일 닫기
		return 1;
	}
	else
		client_print(id,print_chat,"파일 오픈 실패 id %d" , id);

	return 0;
}

// 위 두 함수로 해당 이용자의 데이터를 key로 나누어 검색하고 저장할 수 있다.
// 예로 키 1번을 포인트로 한다면 키 값에 1을 주면 된다.
// 이런 키들은 따로 #define 해서 쓸 생각이다.
// 여하튼, 데이터별로 분류하고 얻어올 수 있다.
// 유저별로 구별은 이미 파일에서 되므로 따로 정보를 두지 않을 것이다.
// 가장 포인트가 키 1번으로 쓰이고
// 두번째로는 키 2번으로는 맵별 순위 현황을 기록해두어 모두 통틀어 볼 수 있도록 정보를 담아둔다.
// 키 2번은 topten_update 함수에서 구현하면 된다.

// 일단 등산을 완료하면 뜨는 포인트만 마무리하고 나머진 응용하자.

// 포인트를 보는 함수
public point_show( id )
{
	new userName[32] 
	get_user_name(id, userName, 32)

	// 일단 챗창에만 뜨게끔
	new point[32]

	get_profile( id, point, 32, POINT )
	
	client_print(id, print_chat, "[Ontale*] %s님의 [근성 포인트]는 %s점 입니다.(Beta 0.1)", userName, point )
}

// point 책정 
// 추후에 좀 더 융통성 있게 수정 
// =============================================================================
// 기록의 총 수를 건내줌
// 좀 더 최적화를 위해 맵 기록 파일에 기록될때마다 기록 파일 32번째 키 데이터로 크기를 저장한다.
public isRecordCount( mapName[] )
{
	new szTemp[128], tempKey[8]
	new fileName[32]
	new i

	format( fileName, 31, "pk_%s", mapName )

	new vault = nvault_open(fileName) 

	if( vault != INVALID_HANDLE )
	{
		for( i  = 0 ; i < MAX_TOP ; i++ )
		{//0개~30개
			format(tempKey,7,"%d",i+1 )	
			nvault_get(vault,tempKey,szTemp,128)

			if( equal( szTemp, "" ) )
			{
				nvault_close(vault)
				return i
			}
		}
		nvault_close(vault)
	}
	else
	{
		client_print(0,print_chat,"파일 오픈 실패");
		return -1;
	}
	return i
}

public calc_point( rank, type )
{
	new rc
	new point = 0

	if( type == 1 )
	{// 포인트 제도 1
		new szvault[64], szmap[32]
		get_mapname(szmap,32)
		format(szvault,64,"pk_%s",szmap)

		rc = isRecordCount( szmap )

	}
	else if( type == 2 )
	{// 포인트 제도 2
		rc = get_playersnum() - 1
		//client_print(0, print_chat, "[Ontale*] rcrcrcrc %d ", rc )
	}

	if( rc != -1 )
	{	
		// 획득 포인트 계산 법
		// 현재 맵의 기록들의 수에서 기록한 랭킹을 가중치로두고
		// 최대 MAX_TOP(30)개의 기록으로 차등 포인트 적용하고 있다.
		// 2명중 1등 했을때와 30명중 1등 했을때 포인트를 동일 적용하는건 옳지 않다.
		// 이제 전자의 것은 66점을 얻을 것이고 후자의 것은 1000점을 얻을 것이다.
		// 예로 몇가지 경우를 더 추가하자면
		// 10 명중 5등은 200점 얻고
		// 9 명중 5등은 166점을( 170 )
		// 8명중 5등은 133점을 얻는다.( 130 )
		// 꼴찌는 점수를 얻을 수 없다.
		// 다만, 30명이 다 찬 경우 30등을 할땐 꼴찌라도 갱신이므로 예외

		// 일자리수를 반올림해서 적용할 생각( 적용 후 )
		if( rc == 0 && type == 1 )
		{
			client_print(0, print_chat, "[Ontale*] 첫 순위 등록자가 탄생 했습니다. 보너스 적용(Beta 0.1)" )
			point = 100;
		}
		else if( !( rc+1 == rank ) ) // 꼴지가 아닐때만
			point = floatround( (( rc+1-rank ) * 100.0 ) / MAX_TOP, floatround_round ) * 10 // 최저 30 풀 레코드에서 1등의 경우 천점까지 얻을 수 있음
		else 
			point = 5 // 기본점수 등수에 못들었거나 꼴지( 기본 완수 점수 )
	}	
	
	return point;
}
//============================================================================

// 포인트 쓰기 이전 포인트를 얻어서 합한뒤 다시 쓴다.
public topten_point( id, newrank, oldrank )
{	
	if( newrank > 0 )
	{
		new point = 0

		if( oldrank > 100 )// 새로운 기록
		{
			point = calc_point( newrank, 1 ) // 추가
			if( point > 0 )
				client_print(id, print_chat, "[Ontale*] 신규 랭킹이 등록되어 [근성 포인트] %d점을 획득하셨습니다.(Beta 0.1)", point )
		}
		else if( newrank == oldrank )
		{// 순위가 동일할때 향상된 기록이면 이 곳으로 들어오게되고
		// 향상되지 못했을땐 못들어오는데..
		// 만약 향상되었다면 약간의 추가 포인트를 
			point = 5;
			client_print(id, print_chat, "[Ontale*] 순위 변화는 없으나 기록이 향상되어 [근성 포인트] %d점이 추가되었습니다.(Beta 0.1)", point )	
		}
		else
		{
		       point = calc_point( newrank, 1 ) - calc_point( oldrank, 1 )
		       client_print(id, print_chat, "[Ontale*] 순위가 상승하여 [근성 포인트] %d점이 추가되었습니다.(Beta 0.1)", point )
		}

		updatePoint( id, point )
	}
	else // 드물겠지만 순위에 못들었을 경우
		return 0 // 새로 쓸 필요없다. 포인트 획득 실패

	return 1
}

// 예상 포인트 획득 경로..( 일단 3가지 예상 )
// topten 기록을 통해서
// 맵이 바뀔때마다 유저들과의 배틀을 통해서( topten 순위와는 상관없음 )
// 1:1 지명 배틀을 통해서..

// ===============================================================================


new basetime = 0

public show_systime()
{
	new imin, now
	if( basetime == 0 )
		basetime = get_systime()

	now = get_systime() - basetime

	imin = floatround(now / 60.0,floatround_floor)
	now -= imin * 60
//	new float:eftime = engfunc( EngFunc_Time )
//	EF_Time( eftime )
	
//	client_print(0, print_chat, "[Ontale*] systime : %d     vvvvv %d : %d,,,,,,,,, mftime : %f", get_systime(), imin, now, eftime )
}

//================================================================================
// 새로운 맵으로 바뀌고 등반한 순서대로 포인트 차등 적용 
// 동일인이 깬 다음 다시 깰경우 기본점수 5점만 받는다.
// 주의 : top30과는 무관하다.

// 후에 동일 고유 아이디로 비교하여 동일인인지 아닌지 판단하도록 한다.


public rank_to_point( id )
{
	new i
	new userName[32] 
	get_user_name(id, userName, 32)
	new inum = get_playersnum()
	new point;
	new buff[256]

	for( i = 1 ; i <= get_maxplayers() ; i++ ) // 플레이어 한명 나갔을때 버그 픽스
	{
		if( equal( rankedlist[i-1], userName ) )
		{// 이미 등반한 순위자인지 판단하고
			client_print(id, print_chat, "[Ontale*] %s님의 순위를 확인해 보세요.",userName )		
			point = 5; // 기본 완수 점수
			break
		}
		else if( equal( rankedlist[i-1], "" ) )
		{// 새로운 순위에 등록
			format(rankedlist[i-1],32,"%s",userName) // 나중에 authid로 수정 
			//client_print(0, print_chat, "[Ontale*] %s님의 아이디는 %d(1~32) rankedlist[i-1] : %s", userName, id,rankedlist[i-1] )
			
			
			if( i - inum > 0 ) // 나간 인원이 있다면
				point = calc_point( i-(i-inum), 2 ) // 포인트 계산에서 만약 2명이서 게임하다 한명이
				// 1등하고 나가면 2등한 나머지 사람이 원래는 5점을 받아야(기본점수) 정상인데
				// 현재 인원이 1명이 되면서 2등을 기록한 것으로 계산되어 
				// -30 점이 된다.
				// 고로 이 부분에서 순위를 나간사람만큼 빼주어 계산이 틀리지 않게 한다.
			else
				point = calc_point( i, 2 )
			// 포인트도 역시 수정해야 하는데.. 


			// 이부분 약간 수정 요망
			// 3명이서 게임하다가 두명이 모두 깨고 마지막으로 내가 깻는데
			// 두명중 한명이 나가버렸다.
			// 만약 그렇다면 아래 조건이 없다면 결과에 2명중 3등으로 표시될 것이다.
			// 이를 순위 차(나간 인원 수)를 현 인원에 더하여 공백을 적절히 매꿔 표시한다.
			client_print(id, print_chat, "[Ontale*] %d명중 %d위로 클리어 하셨습니다.(#순위 기준)",( i - inum > 0 )?(inum += (i-inum)):inum, i )
			format( buff, 256, "%d위 %s +point:%d", i, rankedlist[i-1], point )
			print_hudmessage( id, MSG_RANK, buff )
			if( i == 1 ) // 1위 일때 황금 glow
				glow(id)
			break
		}
	} 

	updatePoint( id, point )
}
// ================================================================================

public updatePoint( id, pt )
{
	if( pt != 0 )
	{
		new szPoint[10]

		get_profile( id, szPoint, 10, POINT )
		new point = str_to_num( szPoint );
		
		point += pt
		if( pt > 0 )
			client_print(id, print_chat, "[Ontale*] 포인트 %d점을 얻었습니다.(Beta 0.1)", pt )
		else if( pt < 0 )
			client_print(id, print_chat, "[Ontale*] 포인트 %d점을 잃었습니다.(Beta 0.1)", abs(pt) )

		num_to_str( point, szPoint, 9 ) // 문자열로 바꾸고
		set_profile( id, szPoint, POINT ) // 저장
	}
}

//==================================================================================================
// 1:1 지명 배틀
// 지명 배틀은 A라는 사람이 B라는 사람에게 신청하여 쌍방의 동의하에 누가 먼저 스톱 스위치를 누르는가
// 를 겨루는 것이다.

// 여하튼, 오늘 할 것은 
// 
// 서버안에 있는 유저들을 /battle 메뉴를 통해 리스트화 하고 선택할 수 있게 하는 것을 할 것이다.
// 이 기능은 1:1 배틀이 발생하게되는 시초 메뉴로써 지정한 사람과 지정된 사람과의 처리는 이후에 하면 된다.
new battleSection[32] // 메뉴 구성중 몊 페이지인지 판단

public battleMenu(id, sNum) // sNum 0~31
{
	new players[32], inum 
	get_players(players,inum)
	new buffer[256]
	new name[32]
	new form[32]
	
	format( buffer, 256, "\yBattleMenu\w^n^n" );

	for(new i = sNum, j=1; i < (sNum+7); i++,j++) // 7명씩
	{
		get_user_name(players[i],name,31)//0~6

		if( i>=inum )
		{
			client_print(0, print_chat, "DEBUG : %d 명 뿐이군......(나 혼자 일지도..) %d", i, inum )
			break;
		}
		format( form, 32, "%d. %s^n", j, name ) 
		add(buffer,256, form ) // 플레이어 리스트화		
	} 

	if( sNum - 7 >= 0 ) // 이전 있음
	{
		add(buffer,256,"^n8. 이전")
		battleSection[id-1] = sNum-7
	}
	
	if(sNum+7 < inum)//다음 있음
	{
		add(buffer,256,"^n9. 다음")
		battleSection[id-1] = sNum+7//0,7,14,21,28
	}

	// 취소는 항상 있음
	add(buffer,256,"^n0. 취소")

	show_menu(id,MENU_KEYS_BATTLE, buffer)
}

public menu_handler_battle( id, key )
{
	if( key == 9 ) // 종료
	{
		battleSection[id-1]=0 // 페이지 초기화
		show_menu(id,0,"")
	}
	else if( key == 7 || key == 8 ) // 이전, 다음
	{//반응하거나 않거나
		battleMenu( id, battleSection[id-1] )		
	}
	else
	{
		new SelectedId = battleSection[id-1]+key+1
		new name[32]
		get_user_name(SelectedId,name,31) // 유저번호 1번부터 시작
	
		if( !equal( name, "" ) ) // 정확히 지정했을때( 상대가 있을때 )
		{// 이곳에서 선택된 사람과의 배틀을 초기화하고 준비하면 된다
			client_print(0, print_chat, "DEBUG : %d번 유저인 %s 님을 선택했다.",SelectedId, name )
			battleSection[id-1]=0 // 페이지 초기화
			// task로 상대방에게 메뉴를 띄운뒤 일정시간동안 응답을 기다리다
			// 결정이 되면 준비 task로 넘어가고
			// 취소 되면 거기서( 적당히 초기화하고 ) 끝낸다.
		}
		// 그밖에 취소가 아닌이상 메뉴 유지
		else
			battleMenu( id, battleSection[id-1] )		
	}			
}


// 스카웃 메뉴
// 메뉴 띄우는 함수

public scout(id) 
{
	new menu[640], szscout[128], firstMenu[64]

	if( sc[id-1] == false )
	{
		format(szscout,128,"\w1. 스카웃(Scout) 받기^n      \d(랭킹 등록불가 - 반납 후엔 가능)\w")
	}
	else
		format(szscout,128,"\w1. 스카웃(Scout) 반납^n      \d(랭킹 등록가능)\w")
	if( scout_timer[id-1] == 0 )
		format( firstMenu, 64, "\y( 3초후 메뉴 자동 닫힘 )^n" )
	else
		format( firstMenu, 64, "" )
	format(menu,512,"\yScoutMenu(/scout)\w^n      \dSpecial Thanks to Q(''Q)^n\d랭킹 등록 가능 여부를 꼭 확인하세요^n%s^n%s^n0. 닫기",firstMenu,szscout)
	show_menu(id,MENU_KEYS_SCOUT,menu)
}

// 선택된 메뉴에 따른 처리 함수
public menu_scout_handler( id, key )
{
	switch(key) 
	{
		case 0:
		{
			if(timer_started[id-1] == true) 
			{
				client_print(id,print_chat,"[Ontale*] 이미 타이머가 작동중입니다. 초기화 하신 후 다시 시도하세요.")
				scout(id)
			} 
			else 
			{
				if( sc[id-1] == false )
				{
					// 자동 메뉴 닫힘 메뉴 활성화시 눌러진 1이라면 삭제 
					if( task_exists( id + TASK_SCOUT ) )
					{
						scout_timer[id-1]++ // 메뉴에서 0으로 비교되지 않기 위해
						remove_task( id+TASK_SCOUT )
					}

				// set_hudmessage ( red=200, green=100, blue=0, 
				//Float:x=-1.0, Float:y=0.35, effects=0, 
				//Float:fxtime=6.0, 
				//Float:holdtime=12.0, Float:fadeintime=0.1, Float:fadeouttime=0.2, channel=4 ) 
				//	print_hudmessage(id,0, "1위 Q(''Q) 사마 +point 2300") 
					
					give_item(id,"weapon_scout")
					sc[id-1] = true
					client_print(id,print_chat,"[Ontale*] 스카웃이 제공되었습니다. 랭킹등록 불가합니다. 반납후 가능합니다.")
				}
				else
				{
				//	set_hudmessage(255, 100, 200, -1.0, 0.55, 1, 0.1, 4.0, 0.1, 0.1, -1)
				//	ShowSyncHudMsg(id, msgSync, "행운을 빈다")
					if( user_has_weapon(id,CSW_SCOUT) )
						drop_item(id, "weapon_scout")
				
					sc[id-1] = false
					client_print(id,print_chat,"[Ontale*] 스카웃이 반납되었습니다. 랭킹 참여가 가능합니다.")					
				}
			}
		}
		case 9:
		{
			show_menu(id,0,"")
		}
	}
}


// sell_weapon 이라는 플러그인에서 참조
// 깔끔하다 ㅠ,ㅠ 
public drop_item(id, item[]) //drop's the weapon for id (Thanks to AMX Super)
{
	new float:origin[3] //Makes a new array called origin
	// x, y, z 0, 1, 2
	
	// 원래는 get_user_origin 이었는데 정밀도가 떨어져 화면이 약간 흔들리는 문제 있어 아래의 것으로 바꿈( 결과는 좋음 :D )
	// 아마 gambler에서쓰는 점프 플러그인과 kzredzds 1.0과의 (저장과이동)차이점이 아닌가 싶다.
	entity_get_vector(id,EV_VEC_origin,origin) //fills the array origin with the position from the player
	origin[2] -= 2000.0 //Sets the third array in origin to minus 2000 (origin - 2000)	
	entity_set_origin(id,origin) //Sets the new origin to the player
	//entity_set_vector(id,EV_VEC_velocity,Float:{0.0,0.0,0.0})

	engclient_cmd(id, "drop", item) //Executes the drop command via the HL engine	
	origin[2] += 2000.0 //Sets back the origin to it's old value (I dunno why it's five numbers higher the before)	
	entity_set_origin(id,origin) //Sets the new origin to the player
//	entity_set_vector(id,EV_VEC_velocity,Float:{0.0,0.0,0.0}) // 이건 아마 가속도 없애는 것
}

public print_hudmessage( id, msgType, msg[] )
{
	switch( msgType )
	{
	case MSG_RANK:{// 도착 순위 표시
		new userName[32] 
		get_user_name(id, userName, 31)
	
		if( equal( rankedlist[0], userName ) )
			set_hudmessage(251, 246, 121, -1.0, 0.3, 0, 0.1, 4.0, 0.4, 0.3, -1) //1위는 금색
		else
			set_hudmessage(255, 255, 255, -1.0, 0.3, 0, 0.1, 4.0, 0.4, 0.3, -1) 
		ShowSyncHudMsg(0, msgSync, msg) // 전체 보기
		}
	case 1:{// 경고
		set_hudmessage(255, 50, 50, -1.0, 0.55, 1, 0.1, 4.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(id, msgSync1, msg)
		}
	case 2:{// 배틀 모드 가이드
		set_hudmessage(255, 0, 0, -1.0, 0.3, 0, 0.1, 4.0, 0.4, 0.3, -1)
		ShowSyncHudMsg(id, msgSync2, msg)
		}
	}

}


// 빠찡꼬 머신 시스템
public bbazk( id )
{
	new fnum,snum,tnum 
	new resultNumber[32]
	new lot

	fnum = random_num(0,9)
	snum = random_num(0,9)
	tnum = random_num(0,9)

	format( resultNumber, 31, "%d%d%d", fnum,snum,tnum )
	lot = str_to_num(resultNumber)
	if( (fnum == snum)&&(snum == tnum)  )
	{
		client_print(id,print_chat,"[Ontale*] 잭팟!!!!!!잭팟!!!!!!잭팟!!!!!! 테스트...중 Orz젝팟인데..")						
	}
	cs_set_user_money ( id , lot, 0)
}

// You reached the end of file
// Modified by ontale, p4ddY

//========================================================================
//hook
public give_hook(id,level,cid) {
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
			
	new name[32]
	get_user_name(id,name,32)
		
	new szarg1[32], szarg2[8], bool:mode
	read_argv(1,szarg1,32)
	read_argv(2,szarg2,32)
	if(equal(szarg2,"on"))
		mode = true
		
	if(equal(szarg1,"@ALL")) {
		for(new i=1;i<=get_maxplayers();i++) {
			if(is_user_connected(i) && is_user_alive(i)) {
				canusehook[i-1] = mode
				if(mode) {
					client_print(i,print_chat,"[ProKreedz] Admin %s gave you ability to use hook",name)
					client_print(i,print_chat,"[ProKreedz] Just bind '+hook' on a key, you want")
				}
				else
					client_print(i,print_chat,"[ProKreedz] Admin %s removed your ability to use hook",name)
			}
		}
	}
	else {
		new pid = cmd_target(id,szarg1,2)
		if(pid > 0) {
			canusehook[pid-1] = mode
			if(mode) {
				client_print(pid,print_chat,"[ProKreedz] Admin %s gave you ability to use hook",name)
				client_print(pid,print_chat,"[ProKreedz] Just bind '+hook' on a key, you want")
			}
			else
				client_print(pid,print_chat,"[ProKreedz] Admin %s removed your ability to use hook",name)
		}
	}
	
	return PLUGIN_HANDLED
}

// =================================================================================

public hook_on(id,level,cid) 
{
	if(!canusehook[id-1] && !cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	get_user_origin(id,hookorigin[id-1],3)
	client_print(id,print_chat,"public hook_on(id,level,cid) ")
	if(callfunc_begin("detect_cheat","prokreedz.amxx") == 1) {
		callfunc_push_int(id)
		callfunc_push_str("Hook")
		callfunc_end()
	}
	
	ishooked[id-1] = true
	
	//emit_sound(id,CHAN_STATIC,"weapons/xbow_hit2.wav",1.0,ATTN_NORM,0,PITCH_NORM)
	set_task(0.1,"hook_task",id,"",0,"ab")
	hook_task(id)
	
	return PLUGIN_HANDLED
}

// =================================================================================

public is_hooked(id) {
	return ishooked[id-1]
}

// =================================================================================

public hook_off(id) {
	remove_hook(id)
	
	return PLUGIN_HANDLED
}

// =================================================================================

public hook_task(id) {
	if(!is_user_connected(id) || !is_user_alive(id))
		remove_hook(id)
	
	remove_beam(id)
	draw_hook(id)
	
	new origin[3], Float:velocity[3]
	get_user_origin(id,origin) 
	new distance = get_distance(hookorigin[id-1],origin)
	if(distance > 25)  { 
		velocity[0] = (hookorigin[id-1][0] - origin[0]) * (2.0 * 300 / distance)
		velocity[1] = (hookorigin[id-1][1] - origin[1]) * (2.0 * 300 / distance)
		velocity[2] = (hookorigin[id-1][2] - origin[2]) * (2.0 * 300 / distance)
		
		entity_set_vector(id,EV_VEC_velocity,velocity)
	} 
	else {
		entity_set_vector(id,EV_VEC_velocity,Float:{0.0,0.0,0.0})
		remove_hook(id)
	}
}

// ================================================================================

public draw_hook(id) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)				// TE_BEAMENTPOINT
	write_short(id)				// entid
	write_coord(hookorigin[id-1][0])	// origin
	write_coord(hookorigin[id-1][1])	// origin
	write_coord(hookorigin[id-1][2])	// origin
	write_short(Sbeam)			// sprite index
	write_byte(0)				// start frame
	write_byte(0)				// framerate
	write_byte(100)				// life
	write_byte(10)				// width
	write_byte(0)				// noise
	if(get_user_team(id) == 1) 
	{		// Terrorist
		write_byte(255)			// r
		write_byte(0)			// g
		write_byte(0)			// b
	}
	else 
	{					// Counter-Terrorist
		write_byte(251)			// r
		write_byte(246)			// g
		write_byte(121)			// b
	}

	write_byte(150)				// brightness
	write_byte(0)				// speed
	message_end()
}

public remove_hook(id) {
	if(task_exists(id))
		remove_task(id)
	remove_beam(id)
	ishooked[id-1] = false
}

public remove_beam(id) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(99) // TE_KILLBEAM
	write_short(id)
	message_end()
}

// You reached the end of file
// 200612