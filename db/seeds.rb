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
    # Sable Nightwhisper

    ## Character Details
    - **Race:** Half-Elf
    - **Class:** Rogue (Arcane Trickster) 5
    - **Background:** Charlatan

    ## Ability Scores
    | STR | DEX | CON | INT | WIS | CHA |
    |:---:|:---:|:---:|:---:|:---:|:---:|
    | 8   | 18  | 12  | 14  | 10  | 16  |

    ## Skills
    Stealth, Deception, Sleight of Hand, Arcana, Insight

    ## Equipment
    - Rapier
    - Hand crossbow
    - Thieves' tools
    - Forged noble's signet ring

    ## Backstory
    Born in the slums of Vareth, Sable learned early that survival meant taking what others wouldn't give. She stumbled into magic by accident—a stolen spellbook that turned out to be genuine. Now she uses her illusions to run cons for coin and, occasionally, for the thrill of it.
  TEXT
end

thornwall = Character.find_or_create_by!(game: game, user: bob, name: "Thornwall Ironback") do |c|
  c.content = <<~TEXT
    # Thornwall Ironback

    ## Character Details
    - **Race:** Dwarf (Mountain)
    - **Class:** Fighter (Battle Master) 5
    - **Background:** Soldier

    ## Ability Scores
    | STR | DEX | CON | INT | WIS | CHA |
    |:---:|:---:|:---:|:---:|:---:|:---:|
    | 18  | 10  | 16  | 10  | 12  | 8   |

    ## Skills
    Athletics, Perception, Intimidation, History

    ## Equipment
    - Warhammer
    - Shield
    - Chain mail
    - Military rank insignia

    ## Battle Master Maneuvers
    - Trip Attack
    - Precision Attack
    - Parry

    ## Backstory
    Twenty years in the king's army left Thornwall with a bad knee, a chest full of medals, and a healthy distrust of anyone who gives orders. He's still not sure why he joined this group—probably the pay. He pretends it isn't the company.
  TEXT
end

vesper = Character.find_or_create_by!(game: game, user: claire, name: "Vesper Ashcroft") do |c|
  c.content = <<~TEXT
    # Vesper Ashcroft

    ## Character Details
    - **Race:** Human (Variant)
    - **Class:** Cleric (Twilight Domain) 5
    - **Background:** Acolyte

    ## Ability Scores
    | STR | DEX | CON | INT | WIS | CHA |
    |:---:|:---:|:---:|:---:|:---:|:---:|
    | 10  | 12  | 14  | 12  | 18  | 14  |

    ## Skills
    Medicine, Religion, Persuasion, History

    ## Equipment
    - Mace
    - Scale mail
    - Holy symbol of the Dusk Court
    - Healer's kit

    ## Backstory
    Vesper serves a dying faith—the Dusk Court, once powerful, now reduced to a handful of scattered temples. She travels to find the Court's lost relics before a rival faith claims them and erases the old ways entirely. The darkness doesn't frighten her. She grew up in it.
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

def post!(scene, user, content, ooc: false, at: Time.current)
  Current.user = user
  post = scene.posts.find_or_initialize_by(user: user, content: content)
  if post.new_record?
    post.is_ooc = ooc
    post.created_at = at
    post.updated_at = at
    post.save!
  end
  post
end

# Prologue posts
post!(prologue, gm,    "The bridge groans under the weight of fog. You can smell the Mire before you see it—*rot and black water*, the kind of cold that seeps into bone. The rope bridge ahead sways gently, though there's no wind.", at: 4.days.ago)
post!(prologue, bob,   "Thornwall plants his boots and doesn't move. He stares at the bridge, jaw working. *\"That thing won't hold all four of us at once.\"* He looks back at the fog rolling in behind them. *\"We go one at a time. I go last.\"*", at: 4.days.ago + 5.minutes)
post!(prologue, alice, "Sable is already moving, hand trailing along the rope rail. She glances back over her shoulder. *\"Or we could just go quickly.\"* She doesn't wait for an answer.", at: 4.days.ago + 10.minutes)
post!(prologue, claire, "Vesper closes her hand around her holy symbol and murmurs something low. Her eyes go distant for a moment—the telltale sign of her divine sense reaching out. Then she goes **pale**.", at: 4.days.ago + 15.minutes)
post!(prologue, claire, "[OOC: divine sense result from DM roll — detected undead in the water below, count unknown. Vesper does NOT share this immediately, she's still processing it]", ooc: true, at: 4.days.ago + 16.minutes)
post!(prologue, gm,    "Something shifts beneath the surface of the water. **A pale hand reaches up** and grabs the rope bridge from below—just for a moment—then lets go. The bridge shudders.", at: 4.days.ago + 20.minutes)
post!(prologue, bob,   "*\"Go. NOW.\"* Thornwall doesn't raise his voice. He doesn't have to.", at: 4.days.ago + 25.minutes)
post!(prologue, alice, "Sable sprints across the bridge. The planks groan and shift beneath her boots. *Twenty feet. Thirty.* The rope rail is slick under her palm but she doesn't slow.", at: 4.days.ago + 30.minutes)
post!(prologue, claire, "Vesper moves next, her mail coat clanking. She's muttering prayers—not for protection, for **clarity**. She needs to know what's in that water, and she needs to know *fast*.", at: 4.days.ago + 35.minutes)
post!(prologue, gm,    "Another hand reaches up. Then another. **The water boils with pale fingers** clawing at the bridge from beneath. The fog is thick enough now that you can barely see ten feet in either direction. But you can *hear* the splashing. You can hear the *reaching*.", at: 4.days.ago + 40.minutes)
post!(prologue, bob,   "Thornwall breaks into a run—a bad idea with his knee, but **the bridge is moving** now, the whole thing swaying like a pendulum. He doesn't trust it. He doesn't trust anything that groans like that.", at: 4.days.ago + 45.minutes)
post!(prologue, claire, "*\"VESPER—\"* Sable yells from the other side. She's at the far end, one hand out, ready to catch her.", at: 4.days.ago + 50.minutes)
post!(prologue, gm,    "Vesper is at the halfway point when the rope on the left side **snaps**. Not slowly. *All at once.* The bridge lurches downward and she loses her footing, catching herself on the remaining rail. Behind her, Thornwall is close enough that he could reach her if he stretched.", at: 4.days.ago + 55.minutes)
post!(prologue, bob,   "He grabs her arm—a firefighter's grip, all muscle memory from the king's army. *\"Don't look down. Just move.\"*", at: 4.days.ago + 60.minutes)
post!(prologue, claire, "Vesper doesn't need to be told twice. She drives forward and Thornwall pulls, **half-dragging her the last few feet**. They collapse on solid ground next to Sable, gasping.", at: 4.days.ago + 65.minutes)
post!(prologue, gm,    "Behind you, the bridge twists in the wind. The pale hands have stopped reaching. Or perhaps they've retreated. **The fog is closing in**, and you have maybe *two minutes* before it swallows the path behind Thornwall entirely.", at: 4.days.ago + 70.minutes)

# Tavern posts
post!(tavern, gm,    "The Salt & Sorrow smells like *spilled ale and old grudges*. A fire is going but it's not doing much. The barkeep—big, bald, scar along the jaw—polishes a glass without looking at anyone. **Table seven**, where Corvin was supposed to be waiting, has a half-drunk pint on it. *Still cold.*", at: 2.hours.ago)
post!(tavern, alice, "Sable drops into the chair across from the empty seat and wraps her hands around the pint like it's hers. She **watches the barkeep** over the rim and doesn't drink.", at: 2.hours.ago + 10.minutes)
post!(tavern, bob,   "Thornwall takes the seat with his back to the wall. He puts his warhammer on the table. Not as a threat. Just because his knee hurts and it's easier than wearing it.", at: 2.hours.ago + 15.minutes)
post!(tavern, claire, "*\"He was here recently.\"* Vesper touches the rim of the glass, then the seat of the chair. *\"The wood is still warm.\"* She looks toward the back of the tavern. There's a door. *\"Someone took him out that way.\"*", at: 2.hours.ago + 20.minutes)
post!(tavern, gm,    "The barkeep's polishing **slows**. He still doesn't look over.", at: 2.hours.ago + 25.minutes)
post!(tavern, alice, "Sable sets the pint down and smiles at the barkeep. It's the smile she uses when she wants someone to think she's **harmless**. *\"Lovely evening. We're looking for a friend.\"*", at: 90.minutes.ago)
post!(tavern, gm,    "The barkeep's shoulders tense. But he keeps polishing. One more rotation of the glass. Then: *\"Corvin?\"* His voice is gravel. *\"Corvin left about an hour ago. Man in a grey coat came in the back, they talked for five minutes, then they left together.\"*", at: 85.minutes.ago)
post!(tavern, bob,   "*\"Which way?\"* Thornwall's hand is still on his warhammer, but he hasn't moved. The question is **quiet. Dangerous.**", at: 80.minutes.ago)
post!(tavern, gm,    "The barkeep finally looks up. He's older than he seemed—there's a **weariness** in his eyes that speaks to too many nights watching things he shouldn't in this tavern. *\"Out the back. Through the kitchen. There's an alley that leads to the docks.\"*", at: 75.minutes.ago)
post!(tavern, claire, "*\"The grey coat,\"* Vesper says quietly. She's been still this whole time, watching. *\"Did he have a scar? Left eye?\"*", at: 70.minutes.ago)
post!(tavern, gm,    "The barkeep's grip tightens on the glass. It *creaks*. *\"You lot looking to help Corvin, or trouble him?\"*", at: 65.minutes.ago)
post!(tavern, alice, "Sable leans back in the chair and crosses her arms. *\"Depends on who we're dealing with. The grey coat—is he someone we should be afraid of?\"*", at: 60.minutes.ago)
post!(tavern, gm,    "The barkeep sets the glass down carefully. He considers this. Then: *\"Afraid? Maybe. But the smart play is to let this one go.\"* **Whoever's looking for Corvin, they've got reach. And they've got patience.** He nods toward the back door. *\"But you've got legs, and you've got time. Your choice.\"*", at: 55.minutes.ago)
post!(tavern, bob,   "Thornwall stands. His warhammer goes back on his shoulder. *\"We're going after him.\"* He doesn't phrase it like a question.", at: 50.minutes.ago)

# Side scene posts
post!(side_scene, alice, "The alley is narrow enough that Sable can touch both walls if she stretches. She leans against the brick and waits, watching the entrance.", at: 45.minutes.ago)
post!(side_scene, gm,    "A figure steps out of the shadows at the far end. Hood up. They're short—almost child-sized—but they move like someone who has been in a lot of alleys. They hold up one hand: empty. \"You're one of Corvin's people.\" Not a question. \"He said to find you if he didn't show. He didn't show.\"", at: 40.minutes.ago)
post!(side_scene, alice, "Sable's hand finds the hilt of her rapier, but she doesn't draw it. Not yet. Her voice is **low, controlled**—the voice of someone used to dangerous conversations. *\"Who are you?\"*", at: 35.minutes.ago)
post!(side_scene, gm,    "The figure lowers their hood just enough. It's a girl—can't be more than fourteen—with **sharp eyes** and a tattoo that runs from her neck down under her collar. Some kind of sigil. Gang mark, maybe. *\"Name's Pip. I work for the Architect now, but I used to work for Corvin. He kept good people around him.\"* She reaches into her coat slowly, hands visible. *\"I've got a message for you. That's all.\"*", at: 30.minutes.ago)
post!(side_scene, alice, "Sable relaxes, but just barely. *\"I'm listening.\"*", at: 25.minutes.ago)
post!(side_scene, gm,    "Pip pulls out a leather journal—no, not a journal. **A ledger.** *\"Corvin kept records. Shipments, contacts, debts owed, who owes what. He said if anything happened to him, this gets to his people. The ones he trusted.\"* She holds it out. *\"You know what happened at the bridge?\"*", at: 20.minutes.ago)
post!(side_scene, alice, "[OOC: Sable takes the ledger, obviously. What's in it?]", ooc: true, at: 15.minutes.ago)
post!(side_scene, gm,    "The ledger is filled with careful handwriting. Names, amounts, locations. Near the back, there's a section marked **'THE ARCHITECT—INCOMING'** with dates, payments, deliveries. And at the very last entry, written hastily: *'If you're reading this, I'm dead. The Architect wants the Shards. All of them. He has three. We have two. Guard them. Trust no one from the Guild—they're already paid.'*", at: 10.minutes.ago)
post!(side_scene, alice, "Sable's jaw **tightens** as she reads. She looks back up at Pip. *\"The Architect took him?\"*", at: 5.minutes.ago)
post!(side_scene, gm,    "Pip nods. *\"Grey coat, scar on his left eye. He came through here with two mercenaries about an hour ago. Took Corvin to the docks, I think. After that, I don't know.\"* She pulls her hood back up. *\"I've told you what I was paid to tell you. Whatever's in that ledger—that's between you and your conscience.\"* She starts to **back away into the shadows**. *\"Oh. One more thing. The grey coat knows you exist. He knows you're in the city. So maybe don't stay out in the open too long.\"*", at: 1.minute.ago)

puts "  Posts: #{Post.count}"

puts "Done."
puts ""
puts "Login as any of these users (magic link flow):"
puts "  gm@example.com     — Game Master 'Aldric'"
puts "  alice@example.com  — Player 'Alice' / Sable Nightwhisper"
puts "  bob@example.com    — Player 'Bob' / Thornwall Ironback"
puts "  claire@example.com — Player 'Claire' / Vesper Ashcroft"
