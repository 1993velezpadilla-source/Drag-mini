# My Forever Pet — standalone Android game
This replaces the previous emulator prototype as the Android app. No device key, ROM, native library, or network connection is needed. The previous Capybara research is retained in history but NOT compiled into this game. Independent implementation, original vector art, not Bandai's game or a complete replica.

References:
- https://tamagotchi-official.com/us/series/paradise/howto/ (four zoom levels, five stages, care actions, food-dependent growth, genetics concept)
- https://github.com/GMMan/tama-para-research/blob/master/formats/ghost_data.md (separate body/eyes/mouth, stage, field, palette)
- https://github.com/GMMan/tama-para-research/blob/master/gameplay/playdate.md (friendship and breeding conditions, not yet integrated)
- https://tools.bbamorachi.us/guide and https://tamavault.com/paradise/character-database/ (baby timing, cell count, care lapse)

Implemented: local playdate and generation reset with inherited eyes/color (partner is a prototype NPC; actual breeding inheritance algorithm is not verified), documented rank/fighting/friendship/breeding eligibility rules; egg, hatch, baby-to-kid after four matching field cells plus cell interaction, kid/young/adult growth, real-time care, food choices, waste, treatment, simple target-tapping minigame, local credits, 4 zoom levels, field selection, wallpaper with same persisted pet.
Approximate prototype parameters (not extracted code): initial meter values and caps, egg timing (manual hatch), later-stage decay, waste timing, illness threshold, visual shapes, coin rewards, minigame rules, food branch thresholds. No death, network breeding, official species/assets, shop, planet unlock progression, sleep or network. No claim of full parity. 
Build: Gradle 8.9, Java 17, SDK 35. Run javac -d /tmp/pet-test app/src/main/java/org/myforeverpet/paradise/PetState.java app/src/main/java/org/myforeverpet/paradise/PlaydateRules.java tests/PetStateTest.java && java -cp /tmp/pet-test org.myforeverpet.paradise.PetStateTest, then gradle :app:assembleDebug.
