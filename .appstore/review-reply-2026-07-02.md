# CoachCard 1.0 — App Review Reply (Guideline 2.1 information request, 2026-06-18)

Rejection: **2.1.0 Performance: App Completeness** — information request, NOT a functionality rejection.
Submission ID `5b489207-5dfb-43ea-b2ff-3dddc7916533`. Reply via Resolution Center ("Reply to App Review"),
and ALSO paste items 2–7 into App Review Information → Notes for future submissions.

## Item 1 — Screen recording (BLOCKER: needs physical iPad)

Record on **ianPad (iPad Air 11-inch M3, physical)** — plug in + unlock, install build 11 (or current),
then record via QuickTime (File → New Movie Recording → ianPad as camera) or on-device screen record:
1. Launch app → card gallery appears (9 seed cards on first launch)
2. Tap a card → full-screen display mode (the core "silent coaching" flow)
3. Create a new card: styled text, live score, freehand drawing (PencilKit)
4. Show folders / organization
5. Show there is NO login, NO purchase, NO permission prompts (nothing to demonstrate — the flow itself shows it)
Keep it 60–120 seconds. No account/purchase/UGC/permission flows exist in the app, so none need to appear.

## Items 2–7 — Reply text (ready to paste)

---

**2. Devices and operating systems tested on:**
iPad Air 11-inch (M3), iPadOS 26 (physical device); iPad Pro 13-inch (M5) simulator, iPadOS 26. *(Update OS build numbers at recording time.)*

**3. Purpose and target audience:**
CoachCard is a silent visual-communication tool for coaches. In loud training environments (cheerleading gyms, gymnastics facilities, swim decks), athletes often cannot hear verbal instructions mid-routine. CoachCard lets a coach prepare and display full-screen cards — styled text cues, live scores, and freehand-drawn diagrams — and hold the iPad up so athletes across the gym can read the instruction instantly. Target audience: coaches and instructors in any sport where visual communication matters during practice or competition. It solves "shouting across the gym doesn't work" with a glanceable, high-contrast display.

**4. Setup and access instructions:**
No setup, account, or sample files are required. The app is fully functional on first launch: it opens to a card gallery seeded with example cards. Tap any card to display it full screen; tap Compose to create a new card (text, score, or whiteboard drawing); organize cards into folders. All features are available offline immediately. There are no login credentials because there are no accounts.

**5. External services, tools, or platforms:**
None. CoachCard is entirely self-contained: all data is stored locally on device using Apple's SwiftData framework. No network calls, no data providers, no authentication services, no payment processors, no analytics SDKs, and no AI services. The app functions with no internet connection.

**6. Regional differences:**
None. The app functions identically in all regions and requires no region-specific content, services, or configuration.

**7. Regulated industry / protected third-party material:**
Not applicable. CoachCard does not operate in a regulated industry and contains no third-party or protected material; all content displayed in the app is created by the user on-device.

---

## After replying
- Also PATCH these notes into the `appStoreReviewDetail.notes` via ASC API so every future submission carries them.
- Resubmit: Resolution Center → "Resubmit to App Review" (same build 11 is fine — the rejection asked for info, not a new binary).

## STATUS: SENT 2026-07-03 11:46 AM PT
Reply posted in Resolution Center with all 7 items + CoachCard-AppReview-Demo.mp4 (75s, verified home-screen launch → gallery → compose → drawing → full-screen finale). One attachment, no dupes. "Resubmit to App Review" stays disabled for 2.1 info requests — the reply IS the re-engagement. Waiting on Apple.
