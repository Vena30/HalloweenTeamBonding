# BLACKTHORN MANOR | HOST CHEAT SHEET

## Rules
- 3 predefined teams, 19 participants.
- You are the only one who can Start, Open Answers, Close, and move to Next Room.
- Every participant joins the same website using their name + private PIN; submissions are synchronized with the host.
- The first two **different teams** to submit the correct answer earn **5 points each**, except Room 10 (10 points each).
- Duplicate submissions from the same team do NOT take the second slot.
- If only one team answers correctly when time expires, no team scores that room. The host can close the room and continue.
- Only you advance rooms. The first two qualifying teams lock the answer window automatically.
- Host sees all answer attempts. Players see only their own response and current team scores.
- Team totals are calculated from rooms with two qualifying teams.

## Team rosters
Team 1: Ms Ivy, Ericka, Ms Joyce, Skylar, Fayne, Ms Nat
Team 2: Sir Lyndon, Gabe, Alliah, Yesenia, Rachel, Ms Jessel, Sir Joe
Team 3: Ms Carissa, Ms Cassandra, Melvin, Annalyn, Lyka, Amber

## 10 Room Solutions
1. The Haunted Library: **OPEN THE SECRET BOOK**. Shift each alphabet letter back by one.
2. Gallery of Ghosts: **THE GHOSTS GUARD THE KEY**. Sort portraits by oldest to youngest.
3. Witch's Laboratory: **MIDNIGHT MOONFLOWER ELIXIR**. Match the spell ingredients.
4. Cursed Clock Tower: **FOLLOW THE MIDNIGHT CLOCK CHIMES**. Arrange clock/time clues.
5. Moonlit Conservatory: **BEWARE THE SILENT SHADOWS**. Follow the hidden message instructions.
6. Phantom Banquet: **THE PHANTOMS ARRIVE AT MIDNIGHT**. Complete the invitation.
7. Whispering Staircase: **FOLLOW THE CANDLELIT STAIRCASE**. Follow the reversal clue.
8. Dark Observatory: **FIND THE HIDDEN SILVER STAR**. Sequence the star clues.
9. Keeper of Keys: **TAKE THE GOLDEN SKELETON KEY**. Order the keys.
10. Final Door: **OPEN THE BLACKTHORN MANOR GATES**. Combine the collected clues.

## Hosting checklist
1. Deploy the project with a Neon database and run the SQL schema and private PIN seed.
2. Privately distribute each person's unique PIN; never broadcast the full list.
3. Share the website link in Zoom/Meet, ask participants to sign in, and share your Game Master screen.
4. Play the introduction narration and click Begin Game.
5. For each room, show the puzzle, then click Open Answers. The clock starts on the server.
6. Track incoming submissions. After two correct responses from different teams, the window closes and both receive points.
7. Click Next Room when you are ready. Repeat through Room 10.
8. If the timer expires before two teams qualify, click Close this Room, and advance without points for that room.
9. Announce final scores; save a screenshot. Use Reset only after the event because it erases submissions and scores.

## Event note
Server-side arrival order is more objective than Zoom raised hands, but network latency may affect extremely close submissions. Test with two devices before the event.
