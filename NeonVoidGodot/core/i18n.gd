class_name I18n
extends RefCounted
## Sistema central de internacionalização (PT/EN) do Neon Void.
## Suporta chaveamento em tempo de execução e persistência no SaveStore.

const LANG_PT := "pt"
const LANG_EN := "en"

static var current_lang: String = LANG_PT

static func set_language(lang: String) -> void:
	if lang == LANG_EN:
		current_lang = LANG_EN
	else:
		current_lang = LANG_PT

static func is_en() -> bool:
	return current_lang == LANG_EN

static func t(key: String, default_text: String = "") -> String:
	var dict: Dictionary = DICT_EN if current_lang == LANG_EN else DICT_PT
	if dict.has(key):
		return str(dict[key])
	return default_text if not default_text.is_empty() else key

# ---------------------------------------------------------------------------
# Dicionário Português
# ---------------------------------------------------------------------------
const DICT_PT := {
	# Header & HUD
	"hud.logo": "NEON VOID\nDEFESA INCREMENTAL",
	"hud.score": "PONTOS\n%s",
	"hud.points": "PONTOS",
	"hud.wave": "WAVE %d\n%d/%d",
	"hud.wave_anomaly": "WAVE %d\n[%s]",
	"hud.hp_shield": "%d  +%d ESC",
	"hud.sound": "SOM",
	"hud.sound_on": "Som: ON",
	"hud.sound_off": "Som: OFF",
	"hud.sound_short_on": "SOM: ON",
	"hud.sound_short_off": "SOM: OFF",
	"hud.lang_btn": "IDIOMA: PT",
	"hud.lang_btn_short": "PT",
	"hud.mini_stats": "%s abates   |   %s   |   %s dmg   |   %s/s",
	"hud.nova_ready": "NOVA!\nESPAÇO",
	"hud.nova_charging": "NOVA\n%d%%",
	"hud.shop_title": "↑  EVOLUÇÕES",
	"hud.shop_subtitle": "Gaste ouro por categoria.",
	"hud.shop_tab_attack": "ATAQUE",
	"hud.shop_tab_towers": "TORRES",
	"hud.shop_tab_defense": "DEFESA",
	"hud.note": "1–4  atalho rápido\nESPAÇO  Pulso Nova\nP / ESC  pausar",
	"hud.tip": "COMBOS = MAIS PODER\nCompre cada torre na aba TORRES\ne pesquise Escudos no Laboratório.",
	"hud.maxed": "MÁXIMO",
	"hud.slot_name": "SLOT %d • %s",
	"hud.slot_desc": "Nv.%d • %d DPS • %s",

	# Menu Principal
	"menu.tagline": "//  D E F E S A  I N C R E M E N T A L  //",
	"menu.subtitle": "Clique. Evolua. Sobreviva.",
	"menu.record": "♛  RECORDE: %d",
	"menu.play": "▶  JOGAR AGORA",
	"menu.modules": "⌖  MÓDULOS DA TORRE",
	"menu.slots_unlocked": "Slots liberados: %d/7",
	"menu.research": "LABORATÓRIO DE PESQUISAS",
	"menu.codex": "CODEX DOS INIMIGOS",
	"menu.achievements": "SALA DE CONQUISTAS",
	"menu.trophies": "Troféus: %d/%d",
	"menu.or_enter": "ou pressione ENTER",
	"menu.tip": "✧  Dica: Combos aumentam dano e ouro — não erre!",
	"menu.card1_title": "1 • DESTRUA",
	"menu.card1_desc": "Toque/clique nos inimigos antes que atinjam sua base. Combos dão mais dano e ouro.",
	"menu.card2_title": "2 • EVOLUA",
	"menu.card2_desc": "Gaste ouro em Clique, Torreta Auto, Crítico e Escudo. Custo sobe, poder explode.",
	"menu.card3_title": "3 • SOBREVIVA",
	"menu.card3_desc": "Segure as waves e o BOSS. Pulso Nova (ESPAÇO) limpa a tela em emergência.",
	"menu.controls_title": "CONTROLES",
	"menu.controls_desc": "Mouse / Touch     Toque nos inimigos para atirar\n1–4   Upgrades        ESPAÇO   Nova\nP / ESC   Pausa       R   Reiniciar",
	"menu.version": "v1.0 • Godot • recorde local",
	"menu.shake_opt": "TREMORES: ",
	"menu.effects_opt": "EFEITOS: ",
	"menu.numbers_opt": "DANO: ",
	"menu.on": "ON",
	"menu.off": "OFF",
	"menu.reduced": "REDUZIDOS",
	"menu.normal": "NORMAIS",
	"events.void_storm": "Tempestade de Vazio",
	"events.golden_wave": "Wave Dourada",
	"events.phantom_wave": "Wave Fantasma",
	"menu.ranking_title": "♛  RANKING LOCAL                         TOP 10",
	"menu.no_records": "Nenhum recorde ainda.\nSeja o primeiro a dominar o Void!",

	# Pausa & Game Over
	"pause.title": "PAUSADO",
	"pause.resume": "▶  CONTINUAR",
	"pause.restart": "REINICIAR",
	"pause.menu": "MENU",
	"pause.hint": "P / ESC para continuar • R reinicia",
	"gameover.title": "BASE DESTRUÍDA",
	"gameover.new_record": "♛  NOVO RECORDE!",
	"gameover.final_score": "P O N T U A Ç Ã O  F I N A L",
	"gameover.stats": "W%d     %d ABATES     %d OURO\nx%d COMBO     %s",
	"gameover.pieces": "PEÇAS COLETADAS   %s",
	"gameover.top10": "TOP 10 — REGISTRE SEU NOME",
	"gameover.name_placeholder": "SEU NOME",
	"gameover.save": "SALVAR",
	"gameover.save_failed": "Não foi possível salvar o recorde no disco.",
	"gameover.play_again": "JOGAR NOVAMENTE",
	"gameover.back_menu": "VOLTAR AO MENU",
	"gameover.saved_success": "✓ Pontuação salva no ranking!",
	"gameover.saved_fail_try": "Falha ao salvar. Tente novamente.",

	# Laboratório & Módulos
	"btn.back_menu": "VOLTAR AO MENU",
	"lab.title": "LABORATÓRIO DE PESQUISAS",
	"lab.intro": "Inimigos soltam fragmentos da própria estrutura geométrica.\nCada síntese requer processamento nos reatores do laboratório.",
	"lab.tab_lab": "    LABORATÓRIO",
	"lab.tab_attack": "    ATAQUE",
	"lab.tab_defense": "    DEFESA",
	"lab.tab_economy": "    ECONOMIA",
	"lab.tab_towers": "    TORRES",
	"lab.active_synthesis": "SÍNTESE EM ANDAMENTO: %s",
	"lab.remaining_time": "%.1fs restantes (%d%%)",
	"lab.hide_completed_on": "      OCULTAR PESQUISAS CONCLUÍDAS: ATIVO",
	"lab.hide_completed_off": "      OCULTAR PESQUISAS CONCLUÍDAS: INATIVO",
	"lab.completed": "✓ PESQUISA CONCLUÍDA",
	"lab.in_synthesis": "⚡ EM SÍNTESE  •  %.1fs restantes",
	"lab.busy": "LABORATÓRIO OCUPADO  •  Custo: %d ",
	"lab.cost": "Custo: %d ",
	"lab.time_have": "  •  Tempo: %ds  •  Você tem: %d ",
	"lab.all_unlocked": "✓ Todos os módulos de torre foram desbloqueados.",
	"lab.next_module_hint": "◇ Novo módulo de torre: alcance a wave %d para descobrir.",
	"lab.toast_completed": "PESQUISA CONCLUÍDA!",

	# Módulos / Hangar
	"modules.title": "MÓDULOS DA TORRE",
	"modules.intro": "Equipe módulos nos slots desbloqueados da torre.\nCada slot dispara sua própria arma de forma autônoma.\nNovos módulos são pesquisados e sintetizados no Laboratório.",
	"modules.new_section": "NOVOS MÓDULOS DE TORRE",
	"modules.new_desc": "A pesquisa e síntese de novos módulos de torre é realizada no Laboratório de Pesquisas.",
	"modules.go_to_lab": "IR AO LABORATÓRIO (ABA TORRES)",
	"modules.research_section": "PESQUISA DE MÓDULOS",
	"modules.all_researched": "✓ Todos os módulos descobertos já foram pesquisados.",
	"modules.status_researched": "✓ PESQUISADO • disponível em todos os slots",
	"modules.status_locked": "BLOQUEADO • Custo: %d %s • Tempo: %ds • Você tem: %d",
	"modules.btn_research_lab": "PESQUISAR NO LABORATÓRIO",
	"modules.btn_in_synthesis": "⚡ EM SÍNTESE • %.1fs",
	"modules.btn_lab_busy": "LABORATÓRIO OCUPADO",
	"modules.btn_no_pieces": "PESQUISAR • PEÇAS INSUFICIENTES",
	"modules.slot_header": "SLOT %d  •  %s",
	"modules.equipped_tooltip": "Equipado neste slot",
	"modules.equip_tooltip": "Equipar %s no slot %d",
	"modules.expansion_completed": "✓ EXPANSÃO CONCLUÍDA • 7/7 slots liberados",
	"modules.expansion_hint": "◇ Próximo slot: alcance a wave %d para descobrir.",
	"modules.expansion_title": "EXPANSÃO  •  SLOT %d",
	"modules.expansion_discovered": "DESCOBERTO  •  Custo: %d ",
	"modules.btn_research_slot": "PESQUISAR SLOT %d (%ds)",
	"modules.equipped_status": "✓ %s equipada no slot %d para a próxima partida.",
	"modules.synthesis_started": "✓ Síntese iniciada no Laboratório.",
	"modules.expansion_started": "✓ Expansão iniciada no Laboratório.",

	# Codex
	"codex.title": "CODEX DOS INIMIGOS",
	"codex.progress": "Descobertas registradas no Void: %d / %d",
	"codex.unknown": "◇  ???\nContinue avançando pelas waves para descobrir.",
	"codex.line1": "Abates: %d   •   Peças: %d   •   Maior wave: %d",
	"codex.line2": "Drop: %s   •   Fraqueza: %s",
	"codex.line3": "%s   •   Pesquisa: %s",
	"codex.none": "Nenhum espécime cadastrado nesta categoria.",
	"codex.tab_all": "TODOS",
	"codex.tab_common": "COMUNS",
	"codex.tab_shields": "ESCUDOS",
	"codex.tab_shooters": "ATIRADORES",
	"codex.tab_elites": "ELITES",
	"codex.tab_bosses": "BOSSES",

	# Conquistas
	"ach.title": "SALA DE CONQUISTAS DO VAZIO",
	"ach.progress": "Troféus Desbloqueados: %d / %d  •  %.0f%% Concluído",
	"ach.unlocked_badge": "✓ DESBLOQUEADA",
	"ach.locked_badge": "[BLOQUEADA]",
	"ach.reward_claimed": "Recompensa Resgatada: +%d ",
	"ach.reward_unclaimed": "Recompensa: +%d ",
	"ach.gold_reward": "  •  +%d Ouro",
	"ach.empty": "Nenhuma conquista nesta categoria ainda.",
	"ach.toast_title": "CONQUISTA DESBLOQUEADA",
	"ach.tab_all": "TODAS",
	"ach.tab_combat": "COMBATE",
	"ach.tab_progression": "PROGRESSO",
	"ach.tab_special": "DESAFIOS",
	"ach.tab_unlocked": "OBTIDAS",

	# In-game Arena
	"arena.tap_enemies": "TOQUE NOS INIMIGOS!",
	"arena.critical_base": "BASE CRÍTICA — PROTEJA O NÚCLEO",
	"arena.shield_label": "ESCUDO %d / %d",
	"arena.base_core": "BASE // NÚCLEO",
	"arena.combo_text": "x%d   •   x%.2f dano + ouro",
	"arena.minion": "LACAIO",
	"arena.boss_supreme": "BOSS SUPREMO",
	"arena.boss_overload": "OVERLOAD // FASE 2",
	"arena.boss_banner": "BOSS — %s",
	"arena.commander_banner": "COMANDANTE — %s",
	"arena.anomaly_banner": "ANOMALIA — %s",
	"arena.wave_banner": "WAVE %d"
}

# ---------------------------------------------------------------------------
# Dicionário Inglês
# ---------------------------------------------------------------------------
const DICT_EN := {
	# Header & HUD
	"hud.logo": "NEON VOID\nINCREMENTAL DEFENCE",
	"hud.score": "SCORE\n%s",
	"hud.points": "SCORE",
	"hud.wave": "WAVE %d\n%d/%d",
	"hud.wave_anomaly": "WAVE %d\n[%s]",
	"hud.hp_shield": "%d  +%d SHD",
	"hud.sound": "SOUND",
	"hud.sound_on": "Sound: ON",
	"hud.sound_off": "Sound: OFF",
	"hud.sound_short_on": "SOUND: ON",
	"hud.sound_short_off": "SOUND: OFF",
	"hud.lang_btn": "LANGUAGE: EN",
	"hud.lang_btn_short": "EN",
	"hud.mini_stats": "%s kills   |   %s   |   %s dmg   |   %s/s",
	"hud.nova_ready": "NOVA!\nSPACE",
	"hud.nova_charging": "NOVA\n%d%%",
	"hud.shop_title": "↑  UPGRADES",
	"hud.shop_subtitle": "Spend gold by category.",
	"hud.shop_tab_attack": "ATTACK",
	"hud.shop_tab_towers": "TOWERS",
	"hud.shop_tab_defense": "DEFENSE",
	"hud.note": "1–4  quick shortcut\nSPACE  Nova Pulse\nP / ESC  pause",
	"hud.tip": "COMBOS = MORE POWER\nBuy each tower under TOWERS tab\nand research Shields in the Lab.",
	"hud.maxed": "MAXED",
	"hud.slot_name": "SLOT %d • %s",
	"hud.slot_desc": "Lv.%d • %d DPS • %s",

	# Menu Principal
	"menu.tagline": "//  I N C R E M E N T A L  D E F E N C E  //",
	"menu.subtitle": "Click. Evolve. Survive.",
	"menu.record": "♛  RECORD: %d",
	"menu.play": "▶  PLAY NOW",
	"menu.modules": "⌖  TOWER MODULES",
	"menu.slots_unlocked": "Unlocked slots: %d/7",
	"menu.research": "RESEARCH LABORATORY",
	"menu.codex": "ENEMY CODEX",
	"menu.achievements": "HALL OF ACHIEVEMENTS",
	"menu.trophies": "Trophies: %d/%d",
	"menu.or_enter": "or press ENTER",
	"menu.tip": "✧  Tip: Combos boost damage and gold — don't miss!",
	"menu.card1_title": "1 • DESTROY",
	"menu.card1_desc": "Tap/click enemies before they hit your base. Combos grant more damage and gold.",
	"menu.card2_title": "2 • EVOLVE",
	"menu.card2_desc": "Spend gold on Click, Auto Turret, Critical and Shield. Cost rises, power spikes.",
	"menu.card3_title": "3 • SURVIVE",
	"menu.card3_desc": "Endure waves and the BOSS. Nova Pulse (SPACE) clears the screen in emergencies.",
	"menu.controls_title": "CONTROLS",
	"menu.controls_desc": "Mouse / Touch     Tap enemies to shoot\n1–4   Upgrades        SPACE   Nova\nP / ESC   Pause       R   Restart",
	"menu.version": "v1.0 • Godot • local highscore",
	"menu.shake_opt": "SHAKE: ",
	"menu.effects_opt": "EFFECTS: ",
	"menu.numbers_opt": "DAMAGE: ",
	"menu.on": "ON",
	"menu.off": "OFF",
	"menu.reduced": "REDUCED",
	"menu.normal": "NORMAL",
	"events.void_storm": "Void Storm",
	"events.golden_wave": "Golden Wave",
	"events.phantom_wave": "Phantom Wave",
	"menu.ranking_title": "♛  LOCAL RANKING                         TOP 10",
	"menu.no_records": "No records yet.\nBe the first to dominate the Void!",

	# Pausa & Game Over
	"pause.title": "PAUSED",
	"pause.resume": "▶  RESUME",
	"pause.restart": "RESTART",
	"pause.menu": "MENU",
	"pause.hint": "P / ESC to resume • R to restart",
	"gameover.title": "BASE DESTROYED",
	"gameover.new_record": "♛  NEW RECORD!",
	"gameover.final_score": "F I N A L   S C O R E",
	"gameover.stats": "W%d     %d KILLS     %d GOLD\nx%d COMBO     %s",
	"gameover.pieces": "PIECES COLLECTED   %s",
	"gameover.top10": "TOP 10 — ENTER YOUR NAME",
	"gameover.name_placeholder": "YOUR NAME",
	"gameover.save": "SAVE",
	"gameover.save_failed": "Could not save highscore to disk.",
	"gameover.play_again": "PLAY AGAIN",
	"gameover.back_menu": "RETURN TO MENU",
	"gameover.saved_success": "✓ Score saved to leaderboard!",
	"gameover.saved_fail_try": "Failed to save. Please try again.",

	# Laboratório & Módulos
	"btn.back_menu": "RETURN TO MENU",
	"lab.title": "RESEARCH LABORATORY",
	"lab.intro": "Enemies drop fragments of their geometric lattice.\nEach synthesis requires processing in laboratory reactors.",
	"lab.tab_lab": "    LABORATORY",
	"lab.tab_attack": "    ATTACK",
	"lab.tab_defense": "    DEFENSE",
	"lab.tab_economy": "    ECONOMY",
	"lab.tab_towers": "    TOWERS",
	"lab.active_synthesis": "SYNTHESIS IN PROGRESS: %s",
	"lab.remaining_time": "%.1fs remaining (%d%%)",
	"lab.hide_completed_on": "      HIDE COMPLETED RESEARCH: ACTIVE",
	"lab.hide_completed_off": "      HIDE COMPLETED RESEARCH: INACTIVE",
	"lab.completed": "✓ RESEARCH COMPLETED",
	"lab.in_synthesis": "⚡ IN SYNTHESIS  •  %.1fs remaining",
	"lab.busy": "LABORATORY BUSY  •  Cost: %d ",
	"lab.cost": "Cost: %d ",
	"lab.time_have": "  •  Time: %ds  •  You have: %d ",
	"lab.all_unlocked": "✓ All tower modules unlocked.",
	"lab.next_module_hint": "◇ New tower module: reach wave %d to discover.",
	"lab.toast_completed": "RESEARCH COMPLETED!",

	# Módulos / Hangar
	"modules.title": "TOWER MODULES",
	"modules.intro": "Equip modules in unlocked tower slots.\nEach slot fires its own autonomous weapon.\nNew modules are researched and synthesized in the Laboratory.",
	"modules.new_section": "NEW TOWER MODULES",
	"modules.new_desc": "Research and synthesis of new tower modules is done in the Research Laboratory.",
	"modules.go_to_lab": "GO TO LABORATORY (TOWERS TAB)",
	"modules.research_section": "MODULE RESEARCH",
	"modules.all_researched": "✓ All discovered modules have been researched.",
	"modules.status_researched": "✓ RESEARCHED • available in all slots",
	"modules.status_locked": "LOCKED • Cost: %d %s • Time: %ds • You have: %d",
	"modules.btn_research_lab": "RESEARCH IN LABORATORY",
	"modules.btn_in_synthesis": "⚡ IN SYNTHESIS • %.1fs",
	"modules.btn_lab_busy": "LABORATORY BUSY",
	"modules.btn_no_pieces": "RESEARCH • INSUFFICIENT PIECES",
	"modules.slot_header": "SLOT %d  •  %s",
	"modules.equipped_tooltip": "Equipped in this slot",
	"modules.equip_tooltip": "Equip %s in slot %d",
	"modules.expansion_completed": "✓ EXPANSION COMPLETED • 7/7 slots unlocked",
	"modules.expansion_hint": "◇ Next slot: reach wave %d to discover.",
	"modules.expansion_title": "EXPANSION  •  SLOT %d",
	"modules.expansion_discovered": "DISCOVERED  •  Cost: %d ",
	"modules.btn_research_slot": "RESEARCH SLOT %d (%ds)",
	"modules.equipped_status": "✓ %s equipped in slot %d for next run.",
	"modules.synthesis_started": "✓ Synthesis started in Laboratory.",
	"modules.expansion_started": "✓ Expansion started in Laboratory.",

	# Codex
	"codex.title": "ENEMY CODEX",
	"codex.progress": "Void discoveries recorded: %d / %d",
	"codex.unknown": "◇  ???\nContinue advancing through waves to discover.",
	"codex.line1": "Kills: %d   •   Pieces: %d   •   Highest wave: %d",
	"codex.line2": "Drop: %s   •   Weakness: %s",
	"codex.line3": "%s   •   Research: %s",
	"codex.none": "No specimens registered in this category.",
	"codex.tab_all": "ALL",
	"codex.tab_common": "COMMON",
	"codex.tab_shields": "SHIELDS",
	"codex.tab_shooters": "SHOOTERS",
	"codex.tab_elites": "ELITES",
	"codex.tab_bosses": "BOSSES",

	# Conquistas
	"ach.title": "HALL OF ACHIEVEMENTS",
	"ach.progress": "Trophies Unlocked: %d / %d  •  %.0f%% Completed",
	"ach.unlocked_badge": "✓ UNLOCKED",
	"ach.locked_badge": "[LOCKED]",
	"ach.reward_claimed": "Reward Claimed: +%d ",
	"ach.reward_unclaimed": "Reward: +%d ",
	"ach.gold_reward": "  •  +%d Gold",
	"ach.empty": "No achievements in this category yet.",
	"ach.toast_title": "ACHIEVEMENT UNLOCKED",
	"ach.tab_all": "ALL",
	"ach.tab_combat": "COMBAT",
	"ach.tab_progression": "PROGRESSION",
	"ach.tab_special": "CHALLENGES",
	"ach.tab_unlocked": "UNLOCKED",

	# In-game Arena
	"arena.tap_enemies": "TAP ENEMIES!",
	"arena.critical_base": "CRITICAL BASE — DEFEND THE CORE",
	"arena.shield_label": "SHIELD %d / %d",
	"arena.base_core": "BASE // CORE",
	"arena.combo_text": "x%d   •   x%.2f dmg + gold",
	"arena.minion": "MINION",
	"arena.boss_supreme": "SUPREME BOSS",
	"arena.boss_overload": "OVERLOAD // PHASE 2",
	"arena.boss_banner": "BOSS — %s",
	"arena.commander_banner": "COMMANDER — %s",
	"arena.anomaly_banner": "ANOMALY — %s",
	"arena.wave_banner": "WAVE %d"
}

# ---------------------------------------------------------------------------
# Traduções em Inglês de Módulos de Torre
# ---------------------------------------------------------------------------
const MODULE_INFO_EN := {
	"plasma": ["Plasma Tower", "100% damage • direct fire • Thermal Shock"],
	"cryo": ["Cryo Tower", "75% damage • slows 35% for 1.5s"],
	"arc": ["Arc Tower", "65% damage • chains up to 2 targets (4 in static)"],
	"pulse": ["Seismic Tower", "2.5s reload • radial pulse • vertical knockback"],
	"laser": ["Antimatter Laser", "Continuous beam • ramps up to 350% damage"],
	"vortex": ["Gravitational Vortex", "Pulls enemies within 160px • Shock implosion"],
	"railgun": ["Photonic Railgun", "Supersonic beam • pierces and ricochets"]
}

# ---------------------------------------------------------------------------
# Traduções em Inglês de Upgrades em Partida
# ---------------------------------------------------------------------------
const UPGRADE_INFO_EN := {
	"click_dmg": ["PLASMA CLICK", "+Damage per click (+25% every 5 lvls)"],
	"crit_chance": ["CRITICAL CORE", "+4% critical strike chance (max 75%)"],
	"crit_mult": ["LETHAL MULTIPLIER", "+0.25x critical damage multiplier"],
	"combo_drive": ["COMBO FRENZY", "+Damage bonus and combo duration"],
	"click_splash": ["IMPACT WAVE", "Clicks deal area splash damage (115px)"],
	"nova_overdrive": ["NOVA OVERDRIVE", "+20% recharge & +12% Nova Pulse damage"],
	"tower_haste": ["CADENCE ACCELERATOR", "+12% fire rate for all towers"],
	"tower_range": ["RANGE COILS", "+8% attack range for all towers"],
	"tower_pierce": ["TITAN-KILLER ROUNDS", "+18% damage vs Elites and Bosses"],
	"tower_synergy": ["BATTERY SYNERGY", "+6% damage per active tower"],
	"base_hull": ["BASE HULL", "+2 Max HP and +1 instant HP"],
	"hull_vitality": ["TITANIUM REINFORCEMENT", "+4 Max HP and +3 instant HP"],
	"nano_regen": ["CONTINUOUS NANOREPAIR", "Regenerates +1 HP periodically"],
	"reactive_plating": ["ABSORPTION PLATING", "+15% chance to block 1 damage"],
	"shield_cap": ["SHIELD CAPACITOR", "+35 Max Shield and instant recharge"],
	"shield_regen": ["SHIELD REACTOR", "+1.8 Shield/s passive regeneration"],
	"shield_pulse": ["REPULSION FIELD", "When shield breaks, pushes back & damages"]
}

# ---------------------------------------------------------------------------
# Traduções em Inglês de Pesquisas Permanentes (38)
# ---------------------------------------------------------------------------
const RESEARCH_NAMES_EN := [
	"Plasma Analysis", "Autonomous Routing", "Base Alloy", "Nova Reactor",
	"Critical Focus", "Combat Sync", "Quantum Extraction", "Nova Singularity",
	"Kinetic Pierce", "Fire Rate Accelerator", "Relentless Execution", "Titan Hunter",
	"Combo Stabilizer", "Reactive Armor", "Wave Nanorepair", "Quantum Vault",
	"Emergency Generator", "Fragment Magnetism",
	"Plasma Superheating", "Thermal Overload",
	"Absolute Zero", "Deep Hypothermia",
	"High-Voltage Conductors", "Conductive Arc Mesh",
	"Tectonic Resonance", "Seismic Shockwave",
	"Acceleration Focalizer", "Antimatter Lens",
	"Event Horizon", "Collapsing Vortex",
	"Hypersonic Capacitors", "Photonic Coils",
	"Quantum Shield Generator", "Harmonic Shield Recharge", "Plasma Reflective Barrier",
	"Loot Tuning", "Rare Matter Filter", "Extraction Overdrive"
]

const RESEARCH_DESCS_EN := [
	"+1 base damage per click", "+8% turret DPS", "+10 base max HP", "+0.3 charge/s for Nova",
	"+2% chance and +0.2x crit damage", "+0.8% damage/gold bonus per combo", "+8% gold gained per kill", "+25% destructive Nova Pulse damage",
	"+12% damage against armored enemies", "+5% fire rate for all turrets", "+10% damage against enemies below 40% HP", "+12% damage against Elites & Bosses",
	"+0.4s combo duration and reduces penalty on miss", "-1 base damage taken from leaks (min 1)", "+4 HP recovered at base upon completing wave", "+20 starting gold and -12% gold stolen by Thieves",
	"+10 starting Nova charge and +4 Shield heal", "+3% overall fragment drop chance per level",
	"[Plasma Tower] +12% direct damage per level",
	"[Plasma Tower] +15% Thermal Shock damage bonus",
	"[Cryo Tower] +10% damage per level",
	"[Cryo Tower] +0.25s slow duration",
	"[Arc Tower] +10% damage per level",
	"[Arc Tower] +18px electric arc jump range",
	"[Seismic Tower] +12% radial damage per level",
	"[Seismic Tower] +6px vertical knockback force",
	"[Antimatter Laser] +15% beam ramp speed",
	"[Antimatter Laser] +0.3x maximum damage multiplier",
	"[Gravitational Vortex] +12% implosion damage per level",
	"[Gravitational Vortex] +12px vortex pull radius",
	"[Photonic Railgun] +14% piercing & bounce damage",
	"[Photonic Railgun] 4% faster reload and discharge",
	"[Shield] Unlocks Energy Shield on base (+25 initial Max Shield/lvl)",
	"[Shield] +1.5/s shield regen and -0.3s recharge delay",
	"[Shield] Reduces damage taken to shield by 8%/lvl and reflects in area",
	"+3% drop chance from Squares and Triangles",
	"+5% drop chance from Hexagons and +10% from Elites",
	"Critical or Combo >= 10 kills have +4% drop and 25% double drop"
]

# ---------------------------------------------------------------------------
# Traduções em Inglês de Pesquisas de Laboratório (3)
# ---------------------------------------------------------------------------
const LAB_RESEARCH_NAMES_EN := [
	"Synthesis Accelerator",
	"Fragment Efficiency",
	"Resonance Matrix"
]

const LAB_RESEARCH_DESCS_EN := [
	"Reduces research time in lab by 18% per level",
	"Reduces fragment costs of all research by 10% per level",
	"Reduces 8% more time and refunds 1 bonus fragment upon completion"
]

# ---------------------------------------------------------------------------
# Traduções em Inglês do Codex de Inimigos
# ---------------------------------------------------------------------------
const ENEMY_INFO_EN := {
	"square": ["SQUARE", "6%", "Direct damage", "Armored & Duplicator", "Plasma Analysis"],
	"armored_square": ["ARMORED SQUARE", "6%", "Auto turret", "Reduces click to 35%", "Plasma Analysis"],
	"splitter": ["DUPLICATOR", "6%", "Explosive damage", "Spawns two living fragments", "Plasma Analysis"],
	"triangle": ["TRIANGLE", "5%", "Fast clicking", "Ghost & Thief", "Autonomous Routing"],
	"ghost_triangle": ["GHOST TRIANGLE", "5%", "Attack during solid phase", "Intangible 1s every 3s", "Autonomous Routing"],
	"thief": ["THIEF", "5%", "Eliminate before base", "Steals 15% gold", "Autonomous Routing"],
	"pentagon": ["PENTAGON", "6%", "Moderate damage", "Fast and aggressive", "Base Alloy"],
	"hexagon": ["HEXAGON", "8%", "Sustained damage", "Regenerating", "Base Alloy"],
	"regen_hexagon": ["REGEN HEXAGON", "8%", "Do not pause attacks", "Regenerates after 1.5s", "Base Alloy"],
	"heptagon": ["HEPTAGON", "8%", "Heavy armor", "Natural shielding", "Base Alloy"],
	"octagon": ["BASTION OCTAGON", "10%", "Antimatter Laser", "Heavy fortified barrier", "Base Alloy"],
	"nonagon": ["VORTEX NONAGON", "7%", "Cryo Tower", "Supersonic burst rush", "Autonomous Routing"],
	"decagon": ["COLOSSAL DECAGON", "12%", "Photonic Railgun", "High density cosmic mass", "Base Alloy"],
	"hendecagon": ["SHADOW HENDECAGON", "10%", "Gravitational Vortex", "Unstable asymmetric geometry", "Base Alloy"],
	"dodecagon": ["PRIMORDIAL DODECAGON", "15%", "Focused Nova", "Twelve armored faces", "Nova Reactor"],
	"star4": ["CRYSTAL DIAMOND", "6%", "Precise click", "Extreme stellar velocity", "Plasma Analysis"],
	"star5": ["SHOOTING STAR", "7%", "Arc Tower", "Whirl of sparkling shards", "Autonomous Routing"],
	"ring_prism": ["RING PRISM", "12%", "Seismic Pulse", "Resists frontal attacks", "Base Alloy"],
	"spiral_singularity": ["VOID SINGULARITY", "15%", "Thermal Shock + Railgun", "Attracts shots & warps space", "Nova Reactor"],
	"titan_tetrahedron": ["TITAN TETRAHEDRON", "18%", "Full overload", "Four massive structural axes", "Nova Reactor"],
	"void_shooter": ["VOID SHOOTER", "8%", "Click shots / Pulse", "Fires plasma towards base", "Reactive Armor"],
	"quantum_teleporter": ["QUANTUM TELEPORTER", "8%", "Cryo Tower / Arc", "Warps horizontally across arena", "Autonomous Routing"],
	"hive_summoner": ["HIVE SUMMONER", "10%", "Seismic Tower / Vortex", "Spawns pairs of fast minions", "Base Alloy"],
	"plasma_artillery": ["ANTIMATTER ARTILLERY", "10%", "Laser + Interception", "Fires double siege salvos", "Reactive Armor"],
	"rift_weaver": ["RIFT WEAVER", "15%", "Immediate focus + Nova", "Teleports leaving rift minions", "Titan Hunter"],
	"elite": ["ELITE COMMANDER", "Doubled chance", "Titan Hunter", "Leads assaults on waves 3, 8, 13...", "All lines"],
	"elite_vanguard": ["VANGUARD ELITE", "Doubled chance", "Auto Turret", "Heavy armor + Regeneration", "Kinetic Pierce"],
	"elite_phantom": ["SPECTRAL ELITE", "Doubled chance", "Attack in visible phase", "Intangible phase + Quantum Warp", "Titan Hunter"],
	"elite_artillery": ["ARTILLERY ELITE", "Doubled chance", "Intercept projectiles", "Plasma Cannon + Armor", "Reactive Armor"],
	"elite_overlord": ["OVERLORD ELITE", "Doubled chance", "AoE damage (Vortex/Pulse)", "Spawns swarms of minions + Regen", "Titan Hunter"],
	"elite_berserker": ["BERSERKER ELITE", "Doubled chance", "Cryo Tower + Execution", "Speeds up drastically at low HP", "Relentless Execution"],
	"elite_storm": ["STORM ELITE", "Doubled chance", "Railgun + Fast click", "Teleports firing at the core", "Titan Hunter"],
	"boss": ["BOSS — OCTAGONAL GUARDIAN", "100% • 2 cores", "Nova + Intercept shots", "Wave 5 • Fires triple barrage", "Titan Hunter"],
	"boss_colossus": ["BOSS — DECAGONAL COLOSSUS", "100% • 2 cores", "Laser + AoE damage", "Wave 10 • Spawns minions and regens", "Titan Hunter"],
	"boss_primordial": ["BOSS — PRIMORDIAL DODECAGON", "100% • 2 cores", "Fast focus after warp", "Wave 15 • Teleports & fires plasma", "Titan Hunter"],
	"boss_nexus": ["BOSS — COSMIC NEXUS", "100% • 2 cores", "Attack out of phase", "Wave 20 • Quantum phase, minions & fire", "Nova Singularity"],
	"boss_leviathan": ["BOSS — ABYSSAL LEVIATHAN", "100% • 2 cores", "Thermal Shock + Laser", "Wave 25 • Heavy artillery & regeneration", "Titan Hunter"],
	"boss_omega": ["BOSS — OMEGA ARCHITECT", "100% • 2 cores", "Total overload + Nova", "Wave 30+ • Teleport, swarm & barrage", "Nova Singularity"]
}

# ---------------------------------------------------------------------------
# Traduções em Inglês de Conquistas (Achievements)
# ---------------------------------------------------------------------------
const ACHIEVEMENTS_EN := {
	"first_kill": ["FIRST CONTACT", "Defeat your first Void invader"],
	"wave_5": ["SURVIVOR", "Reach Wave 5"],
	"wave_10": ["VOID VETERAN", "Reach Wave 10"],
	"first_boss": ["TITAN DESTROYER", "Defeat your first Boss"],
	"combo_15": ["HYPERCRITICAL FLOW", "Reach a x15 Combo"],
	"shield_active": ["DEFENSIVE BASTION", "Activate Energy Shield in the Lab"],
	"nova_blast": ["FULL PULSE", "Fire the Nova Super-Ability"],
	"slot_expanded": ["TACTICAL ENGINEER", "Unlock an extra tower slot"],
	"wave_20": ["ABYSS EXPLORER", "Reach Wave 20"],
	"wave_30": ["VOID MASTER", "Reach Wave 30"],
	"combo_30": ["HYPERCRITICAL STORM", "Reach a x30 Combo"],
	"boss_omega": ["ARCHITECT'S END", "Defeat the Omega Architect (Wave 30+)"],
	"all_towers": ["CYBERNETIC ARSENAL", "Unlock all 7 tower modules"],
	"all_slots": ["FULL BATTERY", "Unlock all 7 Hangar slots"],
	"codex_10": ["VOID ARCHIVIST", "Discover at least 10 enemies in Codex"],
	"million_points": ["CYBERNETIC SIGNATURE", "Reach 1,000,000 points in a single run"]
}

# ---------------------------------------------------------------------------
# Métodos Auxiliares Localizados para GameData
# ---------------------------------------------------------------------------
static func get_piece_name(index: int) -> String:
	const PIECES_EN := ["SQUARE FRAGMENT", "TRIANGULAR FRAGMENT", "HEXAGONAL ALLOY", "BOSS CORE"]
	if is_en() and index >= 0 and index < PIECES_EN.size():
		return PIECES_EN[index]
	if index >= 0 and index < GameData.PIECE_NAMES.size():
		return GameData.PIECE_NAMES[index]
	return "FRAGMENT"

static func get_upgrade_info(upg_id: String) -> Array:
	var base_info: Array = GameData.UPGRADE_INFO.get(upg_id, ["UPGRADE", "", Color.WHITE])
	if is_en() and UPGRADE_INFO_EN.has(upg_id):
		var en: Array = UPGRADE_INFO_EN[upg_id]
		return [en[0], en[1], base_info[2]]
	return base_info

static func get_module_info(module_id: String) -> Array:
	var base_info: Array = GameData.MODULE_INFO.get(module_id, ["Module", "", Color.WHITE])
	if is_en() and MODULE_INFO_EN.has(module_id):
		var en: Array = MODULE_INFO_EN[module_id]
		return [en[0], en[1], base_info[2]]
	return base_info

static func get_research_name(index: int) -> String:
	if is_en() and index >= 0 and index < RESEARCH_NAMES_EN.size():
		return RESEARCH_NAMES_EN[index]
	if index >= 0 and index < GameData.RESEARCH_NAMES.size():
		return GameData.RESEARCH_NAMES[index]
	return "Research"

static func get_research_desc(index: int) -> String:
	if is_en() and index >= 0 and index < RESEARCH_DESCS_EN.size():
		return RESEARCH_DESCS_EN[index]
	if index >= 0 and index < GameData.RESEARCH_DESCS.size():
		return GameData.RESEARCH_DESCS[index]
	return ""

static func get_lab_research_name(index: int) -> String:
	if is_en() and index >= 0 and index < LAB_RESEARCH_NAMES_EN.size():
		return LAB_RESEARCH_NAMES_EN[index]
	if index >= 0 and index < GameData.LAB_RESEARCH_NAMES.size():
		return GameData.LAB_RESEARCH_NAMES[index]
	return "Lab Research"

static func get_lab_research_desc(index: int) -> String:
	if is_en() and index >= 0 and index < LAB_RESEARCH_DESCS_EN.size():
		return LAB_RESEARCH_DESCS_EN[index]
	if index >= 0 and index < GameData.LAB_RESEARCH_DESCS.size():
		return GameData.LAB_RESEARCH_DESCS[index]
	return ""

static func get_enemy_info(enemy_id: String) -> Array:
	var base_info: Array = GameData.ENEMY_INFO.get(enemy_id, [enemy_id.to_upper(), "5%", "-", "-", "-"])
	if is_en() and ENEMY_INFO_EN.has(enemy_id):
		return ENEMY_INFO_EN[enemy_id]
	return base_info

static func get_achievement_title(ach_id: String, fallback: String = "") -> String:
	if is_en() and ACHIEVEMENTS_EN.has(ach_id):
		return ACHIEVEMENTS_EN[ach_id][0]
	return fallback if not fallback.is_empty() else ach_id.to_upper()

static func get_achievement_desc(ach_id: String, fallback: String = "") -> String:
	if is_en() and ACHIEVEMENTS_EN.has(ach_id):
		return ACHIEVEMENTS_EN[ach_id][1]
	return fallback

