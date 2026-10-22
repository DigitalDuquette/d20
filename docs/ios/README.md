# Tap d20 for iPhone

Plan for a native SwiftUI version of the web app. The work is tracked as issues labeled `ios` (#1 to #31), grouped by the `iOS 1` to `iOS 8` milestones. These wireframes show what each screen should look like.

The app is a full SwiftUI rewrite, not a web-view wrapper (decided in #5).

## Project

- Xcode project: `ios/TapD20/TapD20.xcodeproj`.
- Minimum iOS version: iOS 17. iPhone only, portrait.
- Bundle ID: `com.digitalduquette.tapd20`.
- Source files go in `ios/TapD20/TapD20/`. Xcode picks up new files in that
  folder by itself.
- Unit tests go in `ios/TapD20/TapD20Tests/` and use Swift Testing. Run
  them with Cmd+U.
- The dice engine is `Dice.swift`. `Dice.resolve` turns die values into a
  result and has no randomness, so tests pass fixed values.
- The 3D die is `D20Geometry.swift` (face maths, tested) and
  `D20View.swift` (SceneKit scene and roll animation). Both port the web die
  in `index.html`. The engine picks the values first; the die only shows them.

## Look

- Colors in `Assets.xcassets` copy the tokens in `index.html`, light and
  dark. Change both together.
- Fonts in `TapD20/Fonts/` are TTF copies of the web `fonts/` files. They are
  listed under `UIAppFonts` in `ios/TapD20/Info.plist`. Use the PostScript
  names: `Cinzel-ExtraBold`, `FigtreeLight-Regular`, `FigtreeLight-SemiBold`.
- The app icon is the web d20 rendered at 1024px.

## Run on your iPhone (free Apple ID)

1. Open `ios/TapD20/TapD20.xcodeproj` in Xcode.
2. Select the TapD20 target. In Signing & Capabilities, set Team to your
   Personal Team.
3. Connect the iPhone and turn on Developer Mode
   (Settings > Privacy & Security).
4. Select the iPhone as the run destination and press Run.
5. On the iPhone, trust your profile in
   Settings > General > VPN & Device Management.

With a free Apple ID, the app stops opening after 7 days. Run it from Xcode
again to reinstall it.

| Roll | Advantage | Dice picker | Damage roll |
| --- | --- | --- | --- |
| ![Roll](wireframes/roll.png) | ![Advantage](wireframes/advantage.png) | ![Dice picker](wireframes/dice-picker.png) | ![Damage roll](wireframes/damage-roll.png) |

| Saved rolls | History | Settings |
| --- | --- | --- |
| ![Saved rolls](wireframes/saved-rolls.png) | ![History](wireframes/history.png) | ![Settings](wireframes/settings.png) |

## Phases

1. Setup: Mac and Xcode, developer account, project, icon and fonts.
2. Core roll: dice engine, 3D d20, roll animation, roll screen, haptics, accessibility.
3. Advantage and modifier.
4. More dice: d4 to d100, dice picker, multi-dice results, crit damage.
5. Saved rolls and history.
6. Settings, sound and shake to roll.
7. Home screen widget, Siri and Shortcuts.
8. TestFlight, App Store listing and review.
