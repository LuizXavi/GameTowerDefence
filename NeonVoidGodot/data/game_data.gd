class_name GameData
extends RefCounted
## Fonte única de dados de design do Neon Void.
##
## Todo valor de balanceamento, texto de interface ou definição de conteúdo
## (pesquisas, módulos, inimigos, upgrades) deve viver aqui. Os scripts de
## simulação (VoidState), persistência (SaveStore) e interface apenas consomem
## estas constantes — nunca as redeclaram.

# ---------------------------------------------------------------------------
# Paleta neon
# ---------------------------------------------------------------------------
const PINK := Color("ff2bd6")
const CYAN := Color("22e6ff")
const LIME := Color("b6ff2e")
const AMBER := Color("ffb02e")
const MUTED := Color("a49cb7")
const DISABLED := Color("756d83")
const BG_DEEP := Color("0b061c")
const BG_PANEL := Color("140933")

# ---------------------------------------------------------------------------
# Peças de pesquisa (drops)
# ---------------------------------------------------------------------------
const PIECE_NAMES := ["FRAGMENTO QUADRADO", "FRAGMENTO TRIANGULAR", "LIGA HEXAGONAL", "NÚCLEO DE BOSS"]
const PIECE_SHORT := ["■", "▲", "⬢", "✦"]
const PIECE_COLORS := [PINK, LIME, AMBER, CYAN]

# ---------------------------------------------------------------------------
# Upgrades legados da partida (atalhos 1–4 / VoidState.buy)
# ---------------------------------------------------------------------------
const LEGACY_UPGRADE_NAMES := ["Clique Plasma", "Torreta Auto", "Núcleo Crítico", "Escudo Base"]
const LEGACY_UPGRADE_DESCS := ["+3 dano por clique", "DPS automático", "+4,5% chance crítico", "+15 máx • cura 30"]

# ---------------------------------------------------------------------------
# Laboratório de pesquisas permanentes
# Índices 0–17: ataque/defesa • 18–24: especialização de torretas • 25–27: escudos
# ---------------------------------------------------------------------------
enum Research {
	PLASMA_ANALYSIS, AUTONOMOUS_ROUTING, BASE_ALLOY, NOVA_REACTOR,
	CRITICAL_FOCUS, COMBAT_SYNC, QUANTUM_EXTRACTION, NOVA_SINGULARITY,
	KINETIC_PIERCE, FIRE_RATE, RELENTLESS_EXECUTION, TITAN_HUNTER,
	COMBO_STABILIZER, REACTIVE_ARMOR, WAVE_NANOREPAIR, QUANTUM_VAULT,
	EMERGENCY_GENERATOR, FRAGMENT_MAGNETISM,
	TOWER_PLASMA, TOWER_CRYO, TOWER_ARC, TOWER_PULSE, TOWER_LASER, TOWER_VORTEX, TOWER_RAILGUN,
	SHIELD_GENERATOR, SHIELD_RECHARGE, SHIELD_REFLECT,
}
const RESEARCH_COUNT := 28
const RESEARCH_COMBAT_END := 18   # primeiro índice das especializações de torre
const RESEARCH_TOWER_END := 25    # primeiro índice das pesquisas de escudo

const RESEARCH_NAMES := [
	"Análise de Plasma", "Roteamento Autônomo", "Liga da Base", "Reator Nova",
	"Foco Crítico", "Sincronia de Combate", "Extração Quântica", "Singularidade Nova",
	"Perfuração Cinética", "Acelerador de Cadência", "Execução Implacável", "Caçador de Titãs",
	"Estabilizador de Combo", "Blindagem Reativa", "Nanorreparo de Onda", "Cofre Quântico",
	"Gerador de Emergência", "Magnetismo de Fragmentos",
	"Superaquecimento de Plasma", "Zero Absoluto", "Condutores de Alta Tensão",
	"Ressonância Tectônica", "Lente de Antimatéria", "Horizonte de Eventos", "Capacitores Hiperfônicos",
	"Gerador de Escudo Quântico", "Recarga Harmônica de Escudo", "Barreira Reflexiva de Plasma"
]
const RESEARCH_DESCS := [
	"+1 dano base por clique", "+8% DPS da torreta", "+10 vida máxima da base", "+0,3 carga/s da Nova",
	"+2% chance e +0,2x dano crítico", "+0,8% bônus de dano/ouro por combo", "+8% ouro ganho por abate", "+25% dano destrutivo do Pulso Nova",
	"+12% dano contra inimigos blindados", "+5% cadência de tiro de todas as torretas", "+10% dano contra inimigos abaixo de 40% HP", "+12% dano contra Elites e Bosses",
	"+0,4s duração do combo e reduz perda ao errar", "-1 dano recebido na base por vazamento (mín. 1)", "+4 vida recuperada na base ao concluir cada wave", "+20 ouro inicial e -12% roubo de Ladrões",
	"+10 carga inicial da Nova e +4 cura do Escudo", "+6% chance de drop de peças de inimigos",
	"[Torre Plasma] +12% dano direto e +15% bônus de Choque Térmico",
	"[Torre Criogênica] +10% dano e +0,25s duração de lentidão",
	"[Torre de Arco] +10% dano e +18px alcance dos saltos elétricos",
	"[Torre Sísmica] +12% dano radial e +6px força de empurrão",
	"[Laser Antimatéria] +15% velocidade de rampa e +0,3x dano máximo",
	"[Vórtice Gravitacional] +12% dano de implosão e +12px raio de atração",
	"[Railgun Fotônico] +14% dano perfurante e recarga 4% mais rápida",
	"[Escudo] Desbloqueia Escudo de Energia na base (+25 Escudo Máx inicial/nv)",
	"[Escudo] +1,5/s regeneração de escudo e -0,3s atraso de recarga",
	"[Escudo] Reduz dano recebido no escudo em 8%/nv e reflete dano em área"
]
const RESEARCH_MAX := [
	5, 5, 5, 3, 5, 5, 5, 3,
	5, 5, 5, 5, 5, 5, 5, 5, 5, 3,
	5, 5, 5, 5, 5, 5, 5,
	5, 5, 5
]
const RESEARCH_BASE_COSTS := [
	5, 5, 4, 2, 8, 8, 7, 3,
	6, 6, 7, 3, 5, 6, 5, 6, 6, 4,
	6, 6, 7, 7, 3, 8, 4,
	4, 5, 3
]
const RESEARCH_PIECE_INDEX := [
	0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 0, 3, 1, 2, 2, 1, 2, 3,
	0, 1, 0, 2, 3, 2, 3,
	2, 1, 3
]
## Ícone neon (ver NeonIcons) exibido em cada card de pesquisa não-torre.
const RESEARCH_ICONS := {
	0: "click_dmg", 8: "click_dmg",
	1: "tower_haste",
	2: "base_hull", 11: "base_hull",
	3: "combo_drive", 7: "combo_drive", 17: "combo_drive",
	4: "crit_chance",
	5: "crit_mult",
	6: "nova_overdrive", 16: "nova_overdrive",
	9: "tower_pierce",
	10: "tower_synergy",
	12: "nano_regen",
	13: "reactive_plating", 14: "reactive_plating",
	15: "hull_vitality",
	25: "shield_cap",
	26: "shield_regen",
	27: "shield_pulse",
}

# ---------------------------------------------------------------------------
# Pesquisas de melhoria do próprio Laboratório
# ---------------------------------------------------------------------------
const LAB_RESEARCH_COUNT := 3
const LAB_RESEARCH_NAMES := [
	"Acelerador de Síntese",
	"Eficiência de Fragmentos",
	"Matriz de Ressonância"
]
const LAB_RESEARCH_DESCS := [
	"Reduz o tempo de todas as pesquisas no laboratório em 18% por nível",
	"Reduz o custo de peças de todas as pesquisas no laboratório em 10% por nível",
	"Reduz mais 8% de tempo e reembolsa 1 peça bônus ao concluir pesquisas"
]
const LAB_RESEARCH_MAX := [5, 5, 4]
const LAB_RESEARCH_BASE_COSTS := [5, 6, 4]
const LAB_RESEARCH_PIECE_INDEX := [0, 1, 2] # 0: Quadrado, 1: Triângulo, 2: Hexágono
const LAB_RESEARCH_BASE_TIMES := [12.0, 15.0, 20.0]
const LAB_RESEARCH_ICONS := ["tower_haste", "combo_drive", "nova_overdrive"]

# ---------------------------------------------------------------------------
# Tempos base de pesquisa (em segundos)
# ---------------------------------------------------------------------------
const RESEARCH_BASE_TIMES := [
	8.0, 10.0, 10.0, 12.0,
	12.0, 14.0, 14.0, 16.0,
	14.0, 15.0, 16.0, 18.0,
	12.0, 14.0, 15.0, 16.0,
	18.0, 20.0,
	16.0, 18.0, 18.0,
	20.0, 22.0, 24.0, 26.0,
	20.0, 22.0, 25.0
]
const MODULE_BASE_TIMES := {
	"plasma": 0.0,
	"cryo": 18.0,
	"arc": 22.0,
	"pulse": 26.0,
	"laser": 30.0,
	"vortex": 35.0,
	"railgun": 40.0
}
const SLOT_BASE_TIMES := [0.0, 15.0, 20.0, 25.0, 30.0, 36.0, 45.0]

# ---------------------------------------------------------------------------
# Abas do Laboratório de Pesquisas
# ---------------------------------------------------------------------------
const RESEARCH_TABS := ["lab", "attack", "defense", "economy", "towers"]
const RESEARCH_TAB_LABELS := {
	"lab": "    LABORATÓRIO",
	"attack": "    ATAQUE",
	"defense": "    DEFESA",
	"economy": "    ECONOMIA",
	"towers": "    TORRES"
}
const RESEARCH_TAB_INDICES := {
	"attack": [0, 4, 8, 9, 10, 11, 18, 19, 20, 21, 22, 23, 24],
	"defense": [2, 13, 14, 25, 26, 27],
	"economy": [1, 3, 5, 6, 7, 12, 15, 16, 17]
}

# ---------------------------------------------------------------------------
# Módulos de torre
# ---------------------------------------------------------------------------
const MODULE_IDS := ["plasma", "cryo", "arc", "pulse", "laser", "vortex", "railgun"]
## id -> [nome, descrição, cor]
const MODULE_INFO := {
	"plasma": ["Torre Plasma", "100% dano • disparo direto • Choque Térmico", PINK],
	"cryo": ["Torre Criogênica", "75% dano • desacelera 35% por 1,5s", CYAN],
	"arc": ["Torre de Arco", "65% dano • salta até 2 alvos (4 em estática)", AMBER],
	"pulse": ["Torre Sísmica", "Recarga 2,5s • onda radial • knockback vertical", LIME],
	"laser": ["Laser Antimatéria", "Feixe contínuo • rampa até 350% de dano", Color("ff3355")],
	"vortex": ["Vórtice Gravitacional", "Atrai inimigos em 160px • Implosão com choque", Color("9933ff")],
	"railgun": ["Railgun Fotônico", "Feixe ultra-sônico • perfura e ricocheteia", Color("33ffcc")]
}
const MODULE_WAVES := {"plasma": 1, "cryo": 5, "arc": 10, "pulse": 15, "laser": 20, "vortex": 25, "railgun": 30}
const MODULE_COSTS := {
	"plasma": {"piece_index": -1, "amount": 0},
	"cryo": {"piece_index": 1, "amount": 8},
	"arc": {"piece_index": 0, "amount": 12},
	"pulse": {"piece_index": 2, "amount": 14},
	"laser": {"piece_index": 3, "amount": 4},
	"vortex": {"piece_index": 2, "amount": 20},
	"railgun": {"piece_index": 3, "amount": 6},
}

# ---------------------------------------------------------------------------
# Slots de torre (hangar)
# ---------------------------------------------------------------------------
const MAX_TOWER_SLOTS := 7
const SLOT_WAVES := [1, 3, 6, 10, 15, 22, 30]
const SLOT_COSTS := [
	{"piece_index": -1, "amount": 0},
	{"piece_index": 0, "amount": 6},
	{"piece_index": 1, "amount": 8},
	{"piece_index": 2, "amount": 10},
	{"piece_index": 3, "amount": 3},
	{"piece_index": 2, "amount": 18},
	{"piece_index": 3, "amount": 6},
]

# ---------------------------------------------------------------------------
# Upgrades da partida (comprados com ouro)
# ---------------------------------------------------------------------------
const UPGRADE_DEFS := {
	"click_dmg": {"base": 15, "scale": 1.58},
	"crit_chance": {"base": 90, "scale": 1.80},
	"crit_mult": {"base": 65, "scale": 1.70},
	"combo_drive": {"base": 55, "scale": 1.65},
	"click_splash": {"base": 80, "scale": 1.75},
	"nova_overdrive": {"base": 75, "scale": 1.72},
	"tower_haste": {"base": 60, "scale": 1.70},
	"tower_range": {"base": 70, "scale": 1.72},
	"tower_pierce": {"base": 85, "scale": 1.75},
	"tower_synergy": {"base": 95, "scale": 1.78},
	"base_hull": {"base": 70, "scale": 1.72},
	"hull_vitality": {"base": 60, "scale": 1.68},
	"nano_regen": {"base": 65, "scale": 1.70},
	"reactive_plating": {"base": 80, "scale": 1.75},
	"shield_cap": {"base": 75, "scale": 1.72, "requires_shield": true},
	"shield_regen": {"base": 85, "scale": 1.75, "requires_shield": true},
	"shield_pulse": {"base": 95, "scale": 1.80, "requires_shield": true}
}
const UPG_ATTACK_IDS := ["click_dmg", "crit_chance", "crit_mult", "combo_drive", "click_splash", "nova_overdrive"]
const UPG_TOWER_IDS := ["tower_haste", "tower_range", "tower_pierce", "tower_synergy"]
const UPG_DEFENSE_IDS := ["base_hull", "hull_vitality", "nano_regen", "reactive_plating", "shield_cap", "shield_regen", "shield_pulse"]
const SHIELD_UPGRADE_IDS := ["shield_cap", "shield_regen", "shield_pulse"]
## id -> [nome, descrição, cor]
const UPGRADE_INFO := {
	"click_dmg": ["CLIQUE PLASMA", "+Dano por clique (+25% a cada 5 nv)", Color("ff2bd6")],
	"crit_chance": ["NÚCLEO CRÍTICO", "+4% chance de acerto crítico (máx 75%)", Color("facc15")],
	"crit_mult": ["MULTIPLICADOR LETAL", "+0.25x multiplicador de dano crítico", Color("f97316")],
	"combo_drive": ["FRENESI DE COMBO", "+Bônus de dano e duração de combo", Color("ec4899")],
	"click_splash": ["ONDA DE IMPACTO", "Cliques causam dano em área (115px)", Color("a855f7")],
	"nova_overdrive": ["SOBRECARGA NOVA", "+20% recarga e +12% dano do Pulso Nova", Color("22d3ee")],
	"tower_haste": ["ACELERADOR DE CADÊNCIA", "+12% vel. de disparo das torres", Color("a3e635")],
	"tower_range": ["BOBINAS DE ALCANCE", "+8% alcance de todas as torres", Color("22d3ee")],
	"tower_pierce": ["MUNIÇÃO ANTI-TITÃ", "+18% dano em Elites e Bosses", Color("facc15")],
	"tower_synergy": ["SINCRONIA DE BATERIA", "+6% dano por cada torre ativa", Color("a855f7")],
	"base_hull": ["ESTRUTURA DA BASE", "+2 Vida máx e +1 Vida imediata", Color("22d3ee")],
	"hull_vitality": ["REFORÇO DE TITÂNIO", "+4 Vida máx e +3 Vida imediata", Color("a3e635")],
	"nano_regen": ["NANORREPARO CONTÍNUO", "Regenera +1 Vida periodicamente", Color("34d399")],
	"reactive_plating": ["BLINDAGEM DE ABSORÇÃO", "+15% chance de bloquear 1 dano", Color("facc15")],
	"shield_cap": ["CAPACITOR DE ESCUDO", "+35 Escudo máx e recarga imediata", Color("38bdf8")],
	"shield_regen": ["REATOR DE ESCUDO", "+1.8 Escudo/s de regeneração", Color("22d3ee")],
	"shield_pulse": ["CAMPO DE REPULSÃO", "Ao quebrar escudo, empurra e dá dano", Color("818cf8")]
}

# ---------------------------------------------------------------------------
# Inimigos
# ---------------------------------------------------------------------------
## Cor por família (índice = "kind" do spawn).
const ENEMY_COLORS := [
	Color("ff2bd6"), # 0: square (rosa)
	Color("22e6ff"), # 1: triangle (ciano)
	Color("b6ff2e"), # 2: hexagon (lima)
	Color("ffb02e"), # 3: boss (dourado/âmbar)
	Color("b43aff"), # 4: pentagon (roxo)
	Color("38ef7d"), # 5: heptagon (esmeralda)
	Color("ff3b30"), # 6: octagon (vermelho vivo)
	Color("ff9500"), # 7: nonagon (laranja solar)
	Color("00c7be"), # 8: decagon (turquesa)
	Color("5856d6"), # 9: hendecagon (índigo cósmico)
	Color("ff2d55"), # 10: dodecagon (carmesim estelar)
	Color("af52de"), # 11: star4 (diamante/estrela 4 pontas violeta)
	Color("ffd60a"), # 12: star5 (estrela cadente dourada)
	Color("30d158"), # 13: ring_prism (prisma anelar verde elétrico)
	Color("64d2ff"), # 14: spiral_singularity (singularidade ciano gelo)
	Color("bf5af2"), # 15: titan_tetrahedron (titã tetraédrico)
	Color("ff5e3a"), # 16: void_shooter (atirador do vazio laranja-fogo)
	Color("00f5d4"), # 17: quantum_teleporter (teleportador quântico água-marinha)
	Color("f72585"), # 18: hive_summoner (invocador da colmeia magenta neon)
	Color("ff1744"), # 19: plasma_artillery (artilheiro de antimatéria rubi)
	Color("9d4edd")  # 20: rift_weaver (tecelão de fendas violeta profundo)
]
const FAMILY_IDS := [
	"square", "triangle", "hexagon", "boss", "pentagon", "heptagon",
	"octagon", "nonagon", "decagon", "hendecagon", "dodecagon",
	"star4", "star5", "ring_prism", "spiral_singularity", "titan_tetrahedron",
	"void_shooter", "quantum_teleporter", "hive_summoner", "plasma_artillery", "rift_weaver"
]
const ELITE_MODIFIERS := ["armor", "haste", "regen", "phase", "shooter", "teleporter", "summoner", "berserk"]
const ELITE_TYPES := [
	{"id": "elite_vanguard", "name": "ELITE VANGUARDA", "mods": ["armor", "regen"], "color": Color("ffb02e"), "hp_mult": 2.4, "speed_mult": 0.92},
	{"id": "elite_phantom", "name": "ELITE ESPECTRAL", "mods": ["phase", "teleporter"], "color": Color("00f5d4"), "hp_mult": 1.85, "speed_mult": 1.25},
	{"id": "elite_artillery", "name": "ELITE ARTILHEIRO", "mods": ["shooter", "armor"], "color": Color("ff4d6d"), "hp_mult": 2.1, "speed_mult": 0.95},
	{"id": "elite_overlord", "name": "ELITE INVOCADOR", "mods": ["summoner", "regen"], "color": Color("e056fd"), "hp_mult": 2.25, "speed_mult": 0.88},
	{"id": "elite_berserker", "name": "ELITE FRENÉTICO", "mods": ["haste", "berserk"], "color": Color("ff7f50"), "hp_mult": 1.95, "speed_mult": 1.38},
	{"id": "elite_storm", "name": "ELITE TEMPESTADE", "mods": ["teleporter", "shooter"], "color": Color("fee440"), "hp_mult": 2.0, "speed_mult": 1.18}
]
const BOSS_TYPES := [
	{"id": "boss", "name": "GUARDIÃO OCTOGONAL", "sides": 8, "color": Color("ffb02e"), "hp_mult": 1.0, "speed_mult": 1.0, "ability": "shooter"},
	{"id": "boss_colossus", "name": "COLOSSO DECAGONAL", "sides": 10, "color": Color("ff3b30"), "hp_mult": 1.25, "speed_mult": 0.88, "ability": "summoner_regen"},
	{"id": "boss_primordial", "name": "DODECÁGONO PRIMORDIAL", "sides": 12, "color": Color("00f2fe"), "hp_mult": 1.35, "speed_mult": 1.05, "ability": "teleporter_shooter"},
	{"id": "boss_nexus", "name": "NEXUS CÓSMICO", "sides": 16, "color": Color("c471ed"), "hp_mult": 1.5, "speed_mult": 1.0, "ability": "nexus"},
	{"id": "boss_leviathan", "name": "LEVIATÃ ABISSAL", "sides": 16, "color": Color("00ff87"), "hp_mult": 1.75, "speed_mult": 0.82, "ability": "siege_regen"},
	{"id": "boss_omega", "name": "ARQUITETO ÔMEGA", "sides": 20, "color": Color("ff007f"), "hp_mult": 2.0, "speed_mult": 1.1, "ability": "omega"}
]
const CODEX_ORDER := [
	"square", "armored_square", "splitter", "triangle", "ghost_triangle", "thief",
	"pentagon", "hexagon", "regen_hexagon", "heptagon", "octagon", "nonagon",
	"decagon", "hendecagon", "dodecagon", "star4", "star5", "ring_prism",
	"spiral_singularity", "titan_tetrahedron",
	"void_shooter", "quantum_teleporter", "hive_summoner", "plasma_artillery", "rift_weaver",
	"elite", "elite_vanguard", "elite_phantom", "elite_artillery", "elite_overlord", "elite_berserker", "elite_storm",
	"boss", "boss_colossus", "boss_primordial", "boss_nexus", "boss_leviathan", "boss_omega"
]

const CODEX_TABS := ["all", "common", "shields", "shooters", "elites", "bosses"]
const CODEX_TAB_LABELS := {
	"all": "TODOS",
	"common": "COMUNS",
	"shields": "ESCUDOS",
	"shooters": "ATIRADORES",
	"elites": "ELITES",
	"bosses": "BOSSES"
}

const CODEX_COMMON_IDS := [
	"square", "splitter", "triangle", "ghost_triangle", "thief",
	"pentagon", "hexagon", "regen_hexagon", "nonagon", "decagon",
	"hendecagon", "star4", "star5", "spiral_singularity",
	"quantum_teleporter", "hive_summoner"
]

const CODEX_SHIELD_IDS := [
	"armored_square", "heptagon", "octagon", "dodecagon",
	"ring_prism", "titan_tetrahedron", "elite_vanguard"
]

const CODEX_SHOOTER_IDS := [
	"void_shooter", "plasma_artillery", "rift_weaver",
	"elite_artillery", "elite_storm"
]

const CODEX_ELITE_IDS := [
	"elite", "elite_vanguard", "elite_phantom", "elite_artillery",
	"elite_overlord", "elite_berserker", "elite_storm"
]

const CODEX_BOSS_IDS := [
	"boss", "boss_colossus", "boss_primordial", "boss_nexus",
	"boss_leviathan", "boss_omega"
]

const CODEX_TAB_LISTS := {
	"all": CODEX_ORDER,
	"common": CODEX_COMMON_IDS,
	"shields": CODEX_SHIELD_IDS,
	"shooters": CODEX_SHOOTER_IDS,
	"elites": CODEX_ELITE_IDS,
	"bosses": CODEX_BOSS_IDS
}

## id -> [nome, drop, fraqueza, comportamento, pesquisa recomendada]
const ENEMY_INFO := {
	"square": ["QUADRADO", "30%", "Dano direto", "Blindado e Duplicador", "Análise de Plasma"],
	"armored_square": ["QUADRADO BLINDADO", "30%", "Torreta automática", "Reduz clique a 35%", "Análise de Plasma"],
	"splitter": ["DUPLICADOR", "30%", "Dano explosivo", "Gera dois fragmentos vivos", "Análise de Plasma"],
	"triangle": ["TRIÂNGULO", "22%", "Clique rápido", "Fantasma e Ladrão", "Roteamento Autônomo"],
	"ghost_triangle": ["TRIÂNGULO FANTASMA", "22%", "Ataque durante a fase sólida", "Intangível 1s a cada 3s", "Roteamento Autônomo"],
	"thief": ["LADRÃO", "22%", "Eliminar antes da base", "Rouba 15% do ouro", "Roteamento Autônomo"],
	"pentagon": ["PENTÁGONO", "25%", "Dano moderado", "Rápido e agressivo", "Liga da Base"],
	"hexagon": ["HEXÁGONO", "40%", "Dano sustentado", "Regenerador", "Liga da Base"],
	"regen_hexagon": ["HEXÁGONO REGENERADOR", "40%", "Não interromper ataques", "Regenera após 1,5s", "Liga da Base"],
	"heptagon": ["HEPTÁGONO", "35%", "Blindagem pesada", "Escudo natural", "Liga da Base"],
	"octagon": ["OCTÓGONO BASTIÃO", "45%", "Laser Antimatéria", "Barreira fortificada pesada", "Liga da Base"],
	"nonagon": ["NONÁGONO VÓRTICE", "28%", "Torre Criogênica", "Avanço supersônico em rajada", "Roteamento Autônomo"],
	"decagon": ["DECÁGONO COLOSSAL", "50%", "Railgun Fotônico", "Massa cósmica de alta densidade", "Liga da Base"],
	"hendecagon": ["HENDECÁGONO SOMBRIO", "45%", "Vórtice Gravitacional", "Geometria assimétrica instável", "Liga da Base"],
	"dodecagon": ["DODECÁGONO PRIMORDIAL", "60%", "Nova concentrada", "Câmara de doze faces blindadas", "Reator Nova"],
	"star4": ["DIAMANTE DE CRISTAL", "25%", "Clique preciso", "Velocidade estelar extrema", "Análise de Plasma"],
	"star5": ["ESTRELA CADENTE", "30%", "Torre de Arco", "Vórtice de fragmentos cintilantes", "Roteamento Autônomo"],
	"ring_prism": ["PRISMA ANELAR", "55%", "Pulso Sísmico", "Resiste a ataques frontais", "Liga da Base"],
	"spiral_singularity": ["SINGULARIDADE DO VAZIO", "70%", "Choque Térmico + Railgun", "Atrai tiros e distorce espaço", "Reator Nova"],
	"titan_tetrahedron": ["TITÃ TETRAÉDRICO", "85%", "Sobrecarga total", "Construção de quatro eixos maciços", "Reator Nova"],
	"void_shooter": ["ATIRADOR DO VAZIO", "30%", "Clique nos tiros / Pulso", "Dispara plasma contra a base", "Blindagem Reativa"],
	"quantum_teleporter": ["TELEPORTADOR QUÂNTICO", "30%", "Torre Criogênica / Arco", "Salta horizontalmente pela arena", "Roteamento Autônomo"],
	"hive_summoner": ["INVOCADOR DA COLMEIA", "42%", "Torre Sísmica / Vórtice", "Invoca pares de lacaios velozes", "Liga da Base"],
	"plasma_artillery": ["ARTILHEIRO DE ANTIMATÉRIA", "42%", "Laser + Interceptação", "Dispara rajadas duplas de cerco", "Blindagem Reativa"],
	"rift_weaver": ["TECELÃO DE FENDAS", "65%", "Foco imediato + Nova", "Teleporta e deixa lacaios na fenda", "Caçador de Titãs"],
	"elite": ["COMANDANTE DE ELITE", "Chance dobrada", "Caçador de Titãs", "Lidera assaltos nas waves 3, 8, 13...", "Todas as linhas"],
	"elite_vanguard": ["ELITE VANGUARDA", "Chance dobrada", "Torreta Automática", "Blindagem pesada + Regeneração", "Perfuração Cinética"],
	"elite_phantom": ["ELITE ESPECTRAL", "Chance dobrada", "Ataque na fase visível", "Fase intangível + Teleporte Quântico", "Caçador de Titãs"],
	"elite_artillery": ["ELITE ARTILHEIRO", "Chance dobrada", "Interceptar projéteis", "Canhão de Plasma + Blindagem", "Blindagem Reativa"],
	"elite_overlord": ["ELITE INVOCADOR", "Chance dobrada", "Dano em área (Vórtice/Pulso)", "Invoca enxames de lacaios + Regen", "Caçador de Titãs"],
	"elite_berserker": ["ELITE FRENÉTICO", "Chance dobrada", "Torre Criogênica + Execução", "Acelera drasticamente com HP baixo", "Execução Implacável"],
	"elite_storm": ["ELITE TEMPESTADE", "Chance dobrada", "Railgun + Clique rápido", "Teleporta atirando contra o núcleo", "Caçador de Titãs"],
	"boss": ["BOSS — GUARDIÃO OCTOGONAL", "100% • 2 núcleos", "Nova + Interceptar tiros", "Wave 5 • Dispara barragem tripla", "Caçador de Titãs"],
	"boss_colossus": ["BOSS — COLOSSO DECAGONAL", "100% • 2 núcleos", "Laser + Dano em área", "Wave 10 • Invoca lacaios e regenera", "Caçador de Titãs"],
	"boss_primordial": ["BOSS — DODECÁGONO PRIMORDIAL", "100% • 2 núcleos", "Foco rápido pós-salto", "Wave 15 • Teleporta e dispara plasma", "Caçador de Titãs"],
	"boss_nexus": ["BOSS — NEXUS CÓSMICO", "100% • 2 núcleos", "Atacar fora da fase", "Wave 20 • Fase quântica, lacaios e tiros", "Singularidade Nova"],
	"boss_leviathan": ["BOSS — LEVIATÃ ABISSAL", "100% • 2 núcleos", "Choque Térmico + Laser", "Wave 25 • Artilharia pesada e regeneração", "Caçador de Titãs"],
	"boss_omega": ["BOSS — ARQUITETO ÔMEGA", "100% • 2 núcleos", "Sobrecarga total + Nova", "Wave 30+ • Teleporte, enxame e barragem", "Singularidade Nova"]
}

## Array de zeros com uma entrada por pesquisa (estado inicial).
static func empty_research() -> Array[int]:
	var out: Array[int] = []
	out.resize(RESEARCH_COUNT)
	out.fill(0)
	return out

static func research_icon(index: int) -> String:
	return RESEARCH_ICONS.get(index, "attack")

# ---------------------------------------------------------------------------
# Anomalias Climáticas do Void
# ---------------------------------------------------------------------------
const ANOMALIES := {
	"emp": {
		"id": "emp",
		"name": "TEMPESTADE EMP",
		"desc": "Torretas -30% cadência • Cliques +50% dano",
		"color": Color("22e6ff"),
		"turret_cadence": 1.3,
		"click_dmg": 1.5,
		"drop_mult": 1.0,
		"gold_mult": 1.0,
		"enemy_speed": 1.0,
		"score_mult": 1.0
	},
	"supernova": {
		"id": "supernova",
		"name": "CHUVA SUPERNOVA",
		"desc": "Fragmentos x3 • Ouro x2",
		"color": Color("ffb02e"),
		"turret_cadence": 1.0,
		"click_dmg": 1.0,
		"drop_mult": 3.0,
		"gold_mult": 2.0,
		"enemy_speed": 1.0,
		"score_mult": 1.0
	},
	"warp": {
		"id": "warp",
		"name": "DILATAÇÃO TEMPORAL",
		"desc": "Inimigos -25% velocidade • Trajetórias instáveis",
		"color": Color("b6ff2e"),
		"turret_cadence": 1.0,
		"click_dmg": 1.0,
		"drop_mult": 1.0,
		"gold_mult": 1.0,
		"enemy_speed": 0.75,
		"score_mult": 1.0
	},
	"eclipse": {
		"id": "eclipse",
		"name": "ECLIPSE DO VAZIO",
		"desc": "Inimigos +25% dano • Pontuação x2",
		"color": Color("ff2bd6"),
		"turret_cadence": 1.0,
		"click_dmg": 1.0,
		"drop_mult": 1.0,
		"gold_mult": 1.0,
		"enemy_speed": 1.0,
		"score_mult": 2.0
	}
}
const ANOMALY_KEYS := ["emp", "supernova", "warp", "eclipse"]

# ---------------------------------------------------------------------------
# Conquistas Cyberpunk (Achievements)
# ---------------------------------------------------------------------------
const ACHIEVEMENTS := [
	{"id": "first_kill", "title": "PRIMEIRO CONTATO", "desc": "Abata seu primeiro invasor do Vazio", "reward_pieces": 2, "reward_gold": 25},
	{"id": "wave_5", "title": "SOBREVIVENTE", "desc": "Alcance a Wave 5", "reward_pieces": 4, "reward_gold": 50},
	{"id": "wave_10", "title": "VETERANO DO VOID", "desc": "Alcance a Wave 10", "reward_pieces": 8, "reward_gold": 150},
	{"id": "first_boss", "title": "DESTRUIDOR DE TITÃS", "desc": "Derrote seu primeiro Boss", "reward_pieces": 6, "reward_gold": 100},
	{"id": "combo_15", "title": "FLUXO HIPERCRÍTICO", "desc": "Atinja um Combo de x15", "reward_pieces": 5, "reward_gold": 60},
	{"id": "shield_active", "title": "BASTIÃO DEFENSIVO", "desc": "Ative o Escudo Energético no Laboratório", "reward_pieces": 6, "reward_gold": 80},
	{"id": "nova_blast", "title": "PULSO TOTAL", "desc": "Dispare a Super-Habilidade Nova", "reward_pieces": 4, "reward_gold": 40},
	{"id": "slot_expanded", "title": "ENGENHEIRO TÁTICO", "desc": "Desbloqueie um slot extra de torre", "reward_pieces": 5, "reward_gold": 75}
]

