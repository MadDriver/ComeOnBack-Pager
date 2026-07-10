# Pager UI redesign — "ops console" restyle

A visual/structural restyle of the ComeOnBack Pager (SwiftUI, iPad, landscape,
kiosk, dark-first, deployment target iOS 16.2). No behavior changed: every action,
API call, state transition, and flow is identical. The goal was to answer the owner's
"ugly and crowded" complaint about the v3 additions (canned messages, training teams,
planned positions, rewritten paging screen) by giving the whole app one calm,
high-legibility ops-console language.

## Token system

All new shared code lives in `ComeOnBack Pager/Theme/`:

### `DesignTokens.swift`
- **`Spacing`** — the only gaps/paddings used anywhere: `xs 4 / sm 8 / md 12 / lg 16 / xl 24`.
- **`Radius`** — `chip 8` (tiles/chips) and `card 12` (cards/large buttons). Nothing else.
- **Semantic colors** (on `Color`):
  - `tileFill` = `Color.primary.opacity(0.08)` — the one neutral, unselected fill.
  - `ackGreen` = system green (acknowledged / delivered / success).
  - `pendingOrange` = system orange (pending / plan / unassigned / not-yet-acked).
  - **red** is used directly and only for genuine danger (destructive roles, errors).
  - **selection** is always `Color.accentColor` (scope cyan) + `.white` text.
- **`SectionHeader`** — the single section-label style: uppercased, `.subheadline.weight(.semibold)`, `.secondary`, `tracking 0.8`.

### `SelectableChip.swift`
One component `(label, icon?, selected, role?, minHeight)` replacing every ad-hoc
selectable tile. Neutral (`tileFill`) unselected; accent fill + white text selected;
optional `role` tint (e.g. orange) for a non-neutral unselected slot — never red for a
neutral choice. `.monospacedDigit()` isn't needed here (labels are initials/positions).

### `BoardColumns.swift`
- **`BoardColumns`** — shared AVAILABLE column widths so the three row types line up:
  `action 34 | controller(flex) | be-back 64 | pos 52 | plan 96 | ack 40`, `rowHeight 44`.
- **`BoardColumnHeader`** — the column-caption row shown once above the AVAILABLE list.
- **`TeamBadge`** — the small "TEAM" capsule tag (both board sides).
- **`PlanBadge`** — the orange "plan: XX" badge (controller + team rows).
- **`AckIcon`** — green `checkmark.circle.fill` (acked) / orange `clock.fill` (pending).

### Accent color
`Assets.xcassets/AccentColor.colorset` was **empty** (everything resolved to system
blue). Filled with scope cyan: light `#0891B2`, dark `#06B6D4`. Selected chips use
`.white` text on this fill per the shared brief (matches the web console for
cross-surface consistency).

## Before → after by problem

| # | Problem | Fix |
|---|---------|-----|
| **P1** | Control bar was a `ZStack` overlay on top of the header/board (could collide); 7 heterogeneous controls in one row. | `HomeScreen` is now `VStack { topBar; Divider; board }` — no overlay. `topBar`: board identity + clock leading; Messages/Teams/Plan as peer `.bordered` actions; Sign out `.bordered` + Sign in `.borderedProminent` + overflow `Menu` trailing. |
| **P2** | Three AVAILABLE row types used hand-rolled widths/spacing → ragged queue, no header. | All three (`AvailableCellView`, `TeamCellView`, `HoleCellView`) share `BoardColumns` widths + `BoardColumnHeader`; times `.monospacedDigit()`; consistent `rowHeight`; `lineLimit(1).minimumScaleFactor` throughout. |
| **P3** | No tokens; "selectable tile" re-implemented 5+ times with drifting fills/radii. | One `SelectableChip` + `tileFill`/`Radius` tokens across MessagesView, PairTeamView, PlanView, AssignPlanView, PagingView position grid + minute presets (and SignIn/SignOut tiles). |
| **P4** | Semantic red used for neutral unselected position tiles. | Position/minute/controller chips are neutral (`tileFill`) unselected, accent selected. Pending states (not-acked, unassigned) are orange, not red. Red now only marks danger. |
| **P5** | Hardcoded `.black`/`.white` broke dark default (PAGE, MOVE OFF, ThemeChanger). | PAGE/ASSIGN + MOVE OFF are `.borderedProminent .controlSize(.large)` (system-managed contrast). `ThemeChangerScreen` no longer forces black-on-white; respects the active scheme. |
| **P6** | Fixed point sizes (400/500pt blocks, 100×50 tiles, `height:250` grid overflow). | PagingView position grid is an adaptive `LazyVGrid` that grows/scrolls; clock + ASAP/SOON use `aspectRatio(1, .fit)` with `maxWidth` caps; buttons flex to `maxWidth: .infinity`. |
| **P7** | Inconsistent dismissal: fullScreenCover for small forms; PagingView floating x.circle; AssignPlanView had no close. | PagingView uses a standard toolbar **Close**; AssignPlanView gains an explicit toolbar **Cancel**; Messages/PairTeam/Plan keep their toolbar Close. |
| **P8** | SIGN IN + SIGN OUT both `.borderedProminent`; theme entry a bare SF Symbol. | Only **Sign in** is `.borderedProminent` (the primary act); Sign out and the three peer actions are `.bordered`; appearance moved into a proper overflow `Menu`. |
| **P9** | Section headers were ad-hoc `.fontWeight(.heavy)` all-caps strings. | Every one replaced by the shared `SectionHeader` style. |
| **P10** | Mixed icon vocabulary: 📞 emoji vs `phone`, cryptic `moonphase.last.quarter.inverse`. | SF Symbols everywhere: `phone.fill` for phone; `message`/`person.2`/`calendar.badge.clock` for the peer actions; `circle.lefthalf.filled` for appearance; `ellipsis.circle` for overflow. |
| **P11** | Theme sheet ("Choose a Style") also hosted the destructive "Sign out / re-enroll", light-only. | The destructive device re-enroll moved to the overflow `Menu` (`role: .destructive`). `ThemeChangerScreen` is appearance-only (Theme + Brightness) and theme-aware. |

## Deliberately left alone
- **`ClockView`** analog picker, **`TimeASAPPicker`** segmented control, **`displayTime()` / `BasicTime`** — kept as the consistent shared controls the brief called out; only sized relative to available space where they were fixed.
- **ASAP = red circle** — kept red because it is a genuine urgency signal, not a neutral tile (white text added for contrast). SOON = orange.
- **Modal presentation kind** — Messages/PairTeam/Plan remain `fullScreenCover` (they were already clean with a standard toolbar); only the *chrome* was standardized, not the presentation mechanism.
- **`SignInScreen` / `SignOutScreen`** — not in the enumerated v3 targets, but their red-selected initials tiles were converted to `SelectableChip` for cross-screen consistency (behavior untouched). Their overall layout was left as-is.
