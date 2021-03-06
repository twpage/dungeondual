// Generated by CoffeeScript 1.7.1
(function() {
  var flagDesc;

  window.Brew.panels = {
    full: {
      x: 0,
      y: 0,
      width: 96,
      height: 34
    },
    messages: {
      x: 0,
      y: 0,
      width: 64,
      height: 3
    },
    game: {
      x: 0,
      y: 3,
      width: 64,
      height: 30
    },
    footer: {
      x: 0,
      y: 33,
      width: 64,
      height: 1
    },
    playerinfo: {
      x: 64,
      y: 0,
      width: 16,
      height: 34
    },
    viewinfo: {
      x: 80,
      y: 0,
      width: 16,
      height: 34
    }
  };

  window.Brew.config = {
    level_tiles_width: Brew.panels.game.width,
    level_tiles_height: Brew.panels.game.height,
    mighty_damage_mult: 2,
    defended_block: 2,
    monsters_per_level: 20,
    items_per_level: 5,
    chance_life_flask: 0.5,
    chance_vigor_flask: 0.5,
    fireball_damage_div: 4,
    forcebolt_damage_div: 6,
    damage_fix: 1,
    include_monsters_depth_lag: 2,
    include_items_depth_lag: 2,
    animation_speed: 25,
    max_depth: 9,
    sync: {
      space: 0.4,
      time: 0.6,
      limit: 20
    },
    wait_to_heal: 2,
    stun_chance: 0.33
  };

  window.Brew.colors = {
    white: [255, 255, 255],
    black: [20, 20, 20],
    normal: [192, 192, 192],
    half_white: [128, 128, 128],
    dim_screen: [50, 50, 50],
    memory_bg: [20, 20, 20],
    memory: [104, 120, 120],
    pair_shade: [0, 51, 102],
    grey: [144, 144, 144],
    mid_grey: [104, 104, 104],
    dark_grey: [60, 60, 60],
    darker_grey: [40, 40, 40],
    red: [255, 0, 0],
    green: [0, 255, 0],
    blue: [0, 0, 255],
    orange: [255, 165, 0],
    hf_orange: [255, 126, 0],
    brown: [153, 102, 0],
    purple: [51, 0, 153],
    light_blue: [51, 153, 255],
    yellow: [200, 200, 0],
    steel_blue: [153, 204, 255],
    blood: [165, 0, 0],
    dark_green: [37, 65, 23],
    pink: [255, 62, 150],
    cyan: [0, 205, 205],
    eggplant: [97, 64, 81],
    torch: [150, 75, 30],
    water: [51, 153, 255],
    violet: [247, 142, 246],
    inventorymenu: {
      title: ROT.Color.fromString("#476BD6"),
      border: ROT.Color.fromString("#476BD6"),
      text: ROT.Color.fromString("#6D87D6"),
      option: ROT.Color.fromString("#6D87D6"),
      hotkey: ROT.Color.fromString("white")
    },
    itemmenu: {
      title: ROT.Color.fromString("#476BD6"),
      border: ROT.Color.fromString("#476BD6"),
      text: ROT.Color.fromString("#6D87D6"),
      option: ROT.Color.fromString("#6D87D6"),
      hotkey: ROT.Color.fromString("white")
    }
  };

  window.Brew.unicode = {
    heart: "\u2665",
    delta: "\u0394",
    horizontal_line: "\u2500",
    corner_topleft: "\u250C",
    corner_topright: "\u2510",
    corner_bottomleft: "\u2514",
    corner_bottomright: "\u2518",
    block_full: "\u2588",
    block_fade3: "\u2593",
    block_fade2: "\u2593",
    block_fade1: "\u2591",
    arrow_n: "\u2191",
    arrow_s: "\u2193",
    arrow_e: "\u2192",
    arrow_w: "\u2190",
    arrow_se: "\u2198",
    arrow_ne: "\u2197",
    arrow_sw: "\u2199",
    arrow_nw: "\u2196",
    currency_sign: "\u00A4",
    filled_circle: "\u25cf",
    middle_dot: "\u00b7",
    not_sign: "\u00ac",
    rev_not_sign: "\u2310",
    degree: "\u00b0",
    omega: "\u03a9"
  };

  window.Brew.flags = {
    keeps_distance: "keeps distance",
    see_all: "debug FOV",
    invisible: "is invisible",
    flees_when_wounded: "flees at low health",
    summons_zombies: "summons zombies",
    weapon_pierce: "pierces multiple enemies",
    weapon_smash: "hits surrounding enemies",
    weapon_stun: "always stuns target",
    weapon_stun_chance: "chance stuns target",
    weapon_burning: "burnination",
    weapon_poison: "poison attack",
    stunned: "stunned",
    is_scared: "scared",
    is_flying: "flying",
    is_mighty: "really strong",
    on_fire: "burning",
    defended: "defended",
    poisoned: "poisoned"
  };

  window.Brew.paths = {
    to_player: "pathmap to player",
    from_player: "safety pathmap from player"
  };

  window.Brew.equip_slot = {
    melee: "melee weapon in hand",
    head: "hat head",
    body: "body armor"
  };

  window.Brew.groups = {
    WEAPON: "weapon_",
    ARMOR: "armor_",
    HAT: "hat_",
    FLASK: "flask_",
    TIMEORB: "timeorb_",
    INFO: "info_",
    CORPSE: "corpse_"
  };

  window.Brew.group = {
    "corpse_": {
      code: '%',
      canApply: false
    },
    "info_": {
      code: '?',
      canApply: false
    },
    "weapon_": {
      code: Brew.unicode.arrow_n,
      canApply: false,
      canEquip: true,
      equip_slot: Brew.equip_slot.melee,
      equip_verb: "weilding"
    },
    "armor_": {
      code: '[',
      canApply: false,
      canEquip: true,
      equip_slot: Brew.equip_slot.body,
      equip_verb: "wearing"
    },
    "hat_": {
      code: '[',
      canApply: false,
      canEquip: true,
      equip_slot: Brew.equip_slot.head,
      equip_verb: "wearing"
    },
    "timeorb_": {
      code: '~',
      canEquip: false,
      canApply: true,
      canDrop: false
    },
    "flask_": {
      code: '!',
      canEquip: false,
      canApply: true
    }
  };

  window.Brew.monster_status = {
    HUNT: "hunt player",
    ESCAPE: "flee from player",
    WANDER: "wandering around",
    SLEEP: "sleeping"
  };

  window.Brew.errors = {
    ATTACK_NOT_KNOWN: "target not known",
    ATTACK_NOT_VISIBLE: "target not visible",
    ATTACK_OUT_OF_RANGE: "target is out of range",
    ATTACK_BLOCKED_TERRAIN: "target is blocked by terrain",
    ATTACK_BLOCKED_MONSTER: "target is blocked by a monster"
  };

  window.Brew.stat = {
    health: "hitpoints",
    level: "xp level",
    power: "power",
    stamina: "stamina"
  };

  window.Brew.animationType = {
    tile: "single tile flash",
    projectile: "traveling projectile",
    circle: "expanding circle"
  };

  window.Brew.flaskNames = ["Bubbly", "Steaming", "Golden", "Frosty", "Blood-red", "Glowing", "Ice-cold", "Smoldering"];

  window.Brew.flaskTypes = {
    fire: "fire_",
    health: "health_",
    weakness: "weakness_",
    might: "might_",
    vigor: "vigor_",
    invisible: "invisible_"
  };

  window.Brew.flaskType = {
    "invisible_": {
      unidentified_name: " ",
      real_name: "Flask of Invisibility",
      description: "Will temporarily make you undetectable."
    },
    "fire_": {
      unidentified_name: " ",
      real_name: "Flask of Burning",
      description: "Tastes like burning! It's bad. And I didn't even implement throwing."
    },
    "health_": {
      unidentified_name: " ",
      real_name: "Flask of Life",
      description: "The contents of this flask will heal your wounds. If you are in perfect health, it will augment your lifeforce."
    },
    "weakness_": {
      unidentified_name: " ",
      real_name: "Flask of Weakness",
      description: "This stuff looks disgusting. It's contents will cause you to lose all stamina."
    },
    "might_": {
      unidentified_name: " ",
      real_name: "Flask of Might",
      description: "Temporarily doubles your damage in battle."
    },
    "vigor_": {
      unidentified_name: " ",
      real_name: "Flask of Vigor",
      description: "Instantly restores all stamina."
    }
  };

  window.Brew.abilities = {
    fireball: "fireball_",
    forcebolt: "forcebolt_",
    entangle: "entangle_",
    banish: "banish_",
    charge: "charge_",
    warcry: "warcry_",
    defend: "defend_"
  };

  window.Brew.ability = {
    "fireball_": {
      name: "Fireball",
      range: 7,
      pathing: true,
      needs_target: false,
      pair: true,
      cost: 4,
      description: "Engulfs a 3x3 square of enemies in flame"
    },
    "forcebolt_": {
      name: "Force Bolt",
      range: 7,
      pathing: true,
      needs_target: true,
      pair: false,
      cost: 2,
      description: "Zaps a single enemy"
    },
    "entangle_": {
      name: "Entangle",
      range: 7,
      pathing: false,
      needs_target: false,
      pair: true,
      cost: 3,
      description: "Stuns a 3x3 square of enemies"
    },
    "banish_": {
      name: "Banish",
      range: 7,
      pathing: false,
      needs_target: true,
      pair: false,
      cost: 1,
      description: "Banishes enemy to your ally's realm"
    },
    "charge_": {
      name: "Charge",
      range: 7,
      pathing: true,
      needs_target: true,
      pair: false,
      cost: 1,
      description: "Crash into and attack an enemy"
    },
    "warcry_": {
      name: "Warcry",
      range: 0,
      pathing: false,
      needs_target: false,
      pair: true,
      cost: 1,
      description: "Scares all nearby enemies"
    },
    "defend_": {
      name: "Defend!",
      range: 0,
      pathing: false,
      needs_target: false,
      pair: true,
      cost: 2,
      description: "Temporarily provides extra defense"
    }
  };

  window.Brew.hero_types = {
    wizard: "wizard_",
    warrior: "warrior_"
  };

  window.Brew.hero_type = {
    "wizard_": {
      name: "Apprentice",
      start_abilities: [Brew.abilities.fireball, Brew.abilities.banish, Brew.abilities.forcebolt, Brew.abilities.entangle],
      hp: 3,
      stamina: 20
    },
    "warrior_": {
      name: "Squire",
      start_abilities: [Brew.abilities.charge, Brew.abilities.warcry, Brew.abilities.defend],
      hp: 5,
      stamina: 16
    }
  };

  window.Brew.helptext = "Move                NUMPAD, Arrow Keys, vi keys\nRest/Pickup         Space, NUMPAD 5\nApply (items/doors) a\nInventory           i\nUse Ability         1234...\nView Abilities      z\n\n\n[Co-op Mode]\nTalk                t\nSend Ability        (mouse/click) on\n%c{black_hex}____________________%c{}partner screen\n\nMouse will turn green when and where you \n can use your current ability/spell \n\nLong-Click on a monster for pop-up info\n including powers and statuses";

  flagDesc = {};

  flagDesc[Brew.flags.keeps_distance] = ["Attacks from a distance", ""];

  flagDesc[Brew.flags.invisible] = ["Is invisible", "Invisible"];

  flagDesc[Brew.flags.flees_when_wounded] = ["Flees when wounded", ""];

  flagDesc[Brew.flags.summons_zombies] = ["Can summon zombies", ""];

  flagDesc[Brew.flags.weapon_pierce] = ["Attacks pierce through targets, up to 1 space behind", "Attacks pierce through targets, up to 1 space behind"];

  flagDesc[Brew.flags.weapon_smash] = ["Attacks hits all surrounding targets", "Attacks hits all surrounding targets"];

  flagDesc[Brew.flags.weapon_stun] = ["Successful attacks will always stun", "Successful attacks will always stun"];

  flagDesc[Brew.flags.weapon_stun_chance] = ["Successfull attacks will stun one-third of the time", "Successfull attacks will stun one-third of the time"];

  flagDesc[Brew.flags.weapon_burning] = ["Attack sets targets on fire", "Successfull attacks will set enemies on fire"];

  flagDesc[Brew.flags.weapon_poison] = ["Attack poisons targets", "Successfull attacks will poison enemies"];

  flagDesc[Brew.flags.stunned] = ["Is stunned and can't move", "Stunned"];

  flagDesc[Brew.flags.is_scared] = ["Is currently scared of you", ""];

  flagDesc[Brew.flags.is_flying] = ["Flies", "Flying"];

  flagDesc[Brew.flags.is_mighty] = ["Is supernaturally strong", "Mighty"];

  flagDesc[Brew.flags.on_fire] = ["Is on fire", "On Fire"];

  flagDesc[Brew.flags.defended] = ["Is well-defended", "Defend+"];

  flagDesc[Brew.flags.poisoned] = ["Is poisoned", "Poisoned"];

  window.Brew.flagDesc = flagDesc;

  window.Brew.tutorial_texts = ["Stamina is used when you activate abilities, but also acts as a buffer when you take damage. Try to find a safe spot to rest after each battle to restore your stamina back to full.", "Stamina can be restored with rest. Once health is lost, it cannot be regained except through flasks of healing.", "Some monsters attack from far away. Long-click on a monster to pop up info about it.", "Closing doors can sometimes give you a safe space to rest. Monsters can open doors once they spot you but are less likely to open one at random.", "Some flasks have harmlful effects, be careful when using unknown flasks for the first time.", "Press ? at any time for the help screen", "Smart Kobolds will shoot at you from far away. As the Squire, use the CHARGE ability to close to melee range quickly. The Apprentice can use forcebolt or fireball to dispatch them quickly.", "Pay attention to weapon descriptions in your inventory. Some have special effects like piercing and stunning."];

}).call(this);

//# sourceMappingURL=config.map
