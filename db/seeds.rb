# Seeds are idempotent — safe to run multiple times.
# Creates a GM + 3 players, one game, characters, scenes, and posts.

puts "Seeding..."

# --- Users ---

gm = User.find_or_create_by!(email: "gm@example.com")
gm.create_user_profile!(display_name: "Aldric (GM)") unless gm.user_profile

alice = User.find_or_create_by!(email: "alice@example.com")
alice.create_user_profile!(display_name: "Alice") unless alice.user_profile

bob = User.find_or_create_by!(email: "bob@example.com")
bob.create_user_profile!(display_name: "Bob") unless bob.user_profile

claire = User.find_or_create_by!(email: "claire@example.com")
claire.create_user_profile!(display_name: "Claire") unless claire.user_profile

puts "  Users: #{User.count}"

# --- Game ---

game = Game.find_or_create_by!(name: "The Shattered Realm") do |g|
  g.description = "A dark fantasy campaign set in a world fractured by an ancient cataclysm. Three factions vie for control of the shards of the old world."
end

# Memberships
GameMember.find_or_create_by!(game: game, user: gm)    { |m| m.role = "game_master"; m.status = "active" }
GameMember.find_or_create_by!(game: game, user: alice)  { |m| m.role = "player";      m.status = "active" }
GameMember.find_or_create_by!(game: game, user: bob)    { |m| m.role = "player";      m.status = "active" }
GameMember.find_or_create_by!(game: game, user: claire) { |m| m.role = "player";      m.status = "active" }

puts "  Game: #{game.name}"

# --- Characters ---

Current.user = gm

sable = Character.find_or_create_by!(game: game, user: alice, name: "Sable Nightwhisper") do |c|
  c.content = <<~TEXT
    Race: Half-Elf
    Class: Rogue (Arcane Trickster) 5
    Background: Charlatan

    STR 8 | DEX 18 | CON 12 | INT 14 | WIS 10 | CHA 16

    Skills: Stealth, Deception, Sleight of Hand, Arcana, Insight

    Equipment: Rapier, hand crossbow, thieves' tools, forged noble's signet ring

    Backstory:
    Born in the slums of Vareth, Sable learned early that survival meant taking
    what others wouldn't give. She stumbled into magic by accident—a stolen spellbook
    that turned out to be genuine. Now she uses her illusions to run cons for coin
    and, occasionally, for the thrill of it.
  TEXT
end

thornwall = Character.find_or_create_by!(game: game, user: bob, name: "Thornwall Ironback") do |c|
  c.content = <<~TEXT
    Race: Dwarf (Mountain)
    Class: Fighter (Battle Master) 5
    Background: Soldier

    STR 18 | DEX 10 | CON 16 | INT 10 | WIS 12 | CHA 8

    Skills: Athletics, Perception, Intimidation, History

    Equipment: Warhammer, shield, chain mail, military rank insignia

    Maneuvers: Trip Attack, Precision Attack, Parry

    Backstory:
    Twenty years in the king's army left Thornwall with a bad knee, a chest full of
    medals, and a healthy distrust of anyone who gives orders. He's still not sure
    why he joined this group—probably the pay. He pretends it isn't the company.
  TEXT
end

vesper = Character.find_or_create_by!(game: game, user: claire, name: "Vesper Ashcroft") do |c|
  c.content = <<~TEXT
    Race: Human (Variant)
    Class: Cleric (Twilight Domain) 5
    Background: Acolyte

    STR 10 | DEX 12 | CON 14 | INT 12 | WIS 18 | CHA 14

    Skills: Medicine, Religion, Persuasion, History

    Equipment: Mace, scale mail, holy symbol of the Dusk Court, healer's kit

    Backstory:
    Vesper serves a dying faith—the Dusk Court, once powerful, now reduced to a
    handful of scattered temples. She travels to find the Court's lost relics before
    a rival faith claims them and erases the old ways entirely. The darkness doesn't
    frighten her. She grew up in it.
  TEXT
end

puts "  Characters: #{game.characters.count}"

# --- Scenes ---

# Scene 1: Resolved — the inciting event
prologue = Scene.find_or_create_by!(game: game, title: "The Broken Bridge at Mirehollow") do |s|
  s.description = "A crumbling bridge over the Mire River. The party must cross before nightfall—something is moving in the fog below."
  s.resolved_at = 3.days.ago
  s.resolution = "The party crossed using Sable's rope and Thornwall's brute strength. They found a survivor clinging to the underside—a courier with a sealed letter addressed to someone named 'The Architect.' Vesper's divine sense detected undead in the water. They ran."
end

SceneParticipant.find_or_create_by!(scene: prologue, user: gm)    { |sp| sp.last_visited_at = 3.days.ago }
SceneParticipant.find_or_create_by!(scene: prologue, user: alice)  { |sp| sp.character = sable;     sp.last_visited_at = 3.days.ago }
SceneParticipant.find_or_create_by!(scene: prologue, user: bob)    { |sp| sp.character = thornwall; sp.last_visited_at = 3.days.ago }
SceneParticipant.find_or_create_by!(scene: prologue, user: claire) { |sp| sp.character = vesper;    sp.last_visited_at = 3.days.ago }

# Scene 2: Active — main scene
tavern = Scene.find_or_create_by!(game: game, title: "The Salt & Sorrow Tavern") do |s|
  s.description = "A low-ceilinged tavern in the port town of Ashfen. The party has a contact here—or did. The table where he was supposed to meet them is empty, and the barkeep is pretending not to notice."
end

SceneParticipant.find_or_create_by!(scene: tavern, user: gm)    { |sp| sp.last_visited_at = 1.hour.ago }
SceneParticipant.find_or_create_by!(scene: tavern, user: alice)  { |sp| sp.character = sable;     sp.last_visited_at = 1.hour.ago }
SceneParticipant.find_or_create_by!(scene: tavern, user: bob)    { |sp| sp.character = thornwall; sp.last_visited_at = 1.hour.ago }
SceneParticipant.find_or_create_by!(scene: tavern, user: claire) { |sp| sp.character = vesper;    sp.last_visited_at = 1.hour.ago }

# Scene 3: Active — private side scene (Sable only)
side_scene = Scene.find_or_create_by!(game: game, title: "A Quiet Word in the Alley") do |s|
  s.description = "While the others are distracted, someone slips Sable a note. The alley behind the tavern. Come alone."
  s.private = true
  s.parent_scene_id = tavern.id
end

SceneParticipant.find_or_create_by!(scene: side_scene, user: gm)   { |sp| sp.last_visited_at = 30.minutes.ago }
SceneParticipant.find_or_create_by!(scene: side_scene, user: alice) { |sp| sp.character = sable; sp.last_visited_at = 30.minutes.ago }

puts "  Scenes: #{game.scenes.count} (#{game.scenes.active.count} active, #{game.scenes.resolved.count} resolved)"

# --- Posts ---

Current.user = gm

def post!(scene, user, content, ooc: false, created_offset: 0)
  Current.user = user
  post = scene.posts.find_or_initialize_by(user: user, content: content)
  if post.new_record?
    post.is_ooc = ooc
    post.created_at = created_offset.seconds.ago
    post.updated_at = created_offset.seconds.ago
    post.save!
  end
  post
end

# Prologue posts
post!(prologue, gm, "The bridge groans under the weight of fog. You can smell the Mire before you see it—rot and black water, the kind of cold that seeps into bone. The rope bridge ahead sways gently, though there's no wind.", created_offset: 4 * 24 * 3600)

post!(prologue, bob, "Thornwall plants his boots and doesn't move. He stares at the bridge, jaw working. \"That thing won't hold all four of us at once.\" He looks back at the fog rolling in behind them. \"We go one at a time. I go last.\"", created_offset: 4 * 24 * 3600 - 300)

post!(prologue, alice, "Sable is already moving, hand trailing along the rope rail. She glances back over her shoulder. \"Or we could just go quickly.\" She doesn't wait for an answer.", created_offset: 4 * 24 * 3600 - 600)

post!(prologue, claire, "Vesper closes her hand around her holy symbol and murmurs something low. Her eyes go distant for a moment—the telltale sign of her divine sense reaching out. Then she goes pale.", created_offset: 4 * 24 * 3600 - 900)

post!(prologue, claire, "[OOC: divine sense result from DM roll — detected undead in the water below, count unknown. Vesper does NOT share this immediately, she's still processing it]", ooc: true, created_offset: 4 * 24 * 3600 - 950)

post!(prologue, gm, "Something shifts beneath the surface of the water. A pale hand reaches up and grabs the rope bridge from below—just for a moment—then lets go. The bridge shudders.", created_offset: 4 * 24 * 3600 - 1200)

post!(prologue, bob, "\"Go. NOW.\" Thornwall doesn't raise his voice. He doesn't have to.", created_offset: 4 * 24 * 3600 - 1500)

# Tavern posts
post!(tavern, gm, "The Salt & Sorrow smells like spilled ale and old grudges. A fire is going but it's not doing much. The barkeep—big, bald, scar along the jaw—polishes a glass without looking at anyone. Table seven, where Corvin was supposed to be waiting, has a half-drunk pint on it. Still cold.", created_offset: 2 * 3600)

post!(tavern, alice, "Sable drops into the chair across from the empty seat and wraps her hands around the pint like it's hers. She watches the barkeep over the rim and doesn't drink.", created_offset: 2 * 3600 - 600)

post!(tavern, bob, "Thornwall takes the seat with his back to the wall. He puts his warhammer on the table. Not as a threat. Just because his knee hurts and it's easier than wearing it.", created_offset: 2 * 3600 - 900)

post!(tavern, claire, "\"He was here recently.\" Vesper touches the rim of the glass, then the seat of the chair. \"The wood is still warm.\" She looks toward the back of the tavern. There's a door. \"Someone took him out that way.\"", created_offset: 2 * 3600 - 1200)

post!(tavern, gm, "The barkeep's polishing slows by about half a revolution. He still doesn't look over.", created_offset: 2 * 3600 - 1500)

post!(tavern, alice, "Sable sets the pint down and smiles at the barkeep. It's the smile she uses when she wants someone to think she's harmless. \"Lovely evening. We're looking for a friend.\"", created_offset: 1 * 3600)

# Side scene posts
post!(side_scene, alice, "The alley is narrow enough that Sable can touch both walls if she stretches. She leans against the brick and waits, watching the entrance.", created_offset: 45 * 60)

post!(side_scene, gm, "A figure steps out of the shadows at the far end. Hood up. They're short—almost child-sized—but they move like someone who has been in a lot of alleys. They hold up one hand: empty. \"You're one of Corvin's people.\" Not a question. \"He said to find you if he didn't show. He didn't show.\"", created_offset: 40 * 60)

puts "  Posts: #{Post.count}"

puts "Done."
puts ""
puts "Login as any of these users (magic link flow):"
puts "  gm@example.com     — Game Master 'Aldric'"
puts "  alice@example.com  — Player 'Alice' / Sable Nightwhisper"
puts "  bob@example.com    — Player 'Bob' / Thornwall Ironback"
puts "  claire@example.com — Player 'Claire' / Vesper Ashcroft"
