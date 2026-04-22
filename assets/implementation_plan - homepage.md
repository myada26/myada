# Homepage Inspo → HomeDashboard — Implementation Plan

## Background

The React "homepage inspo" lives in `homepage inspo/src/app/App.tsx`. It is a **pixel-precise Figma export** rendered on an `850px` canvas scaled down to `390px` with `scale-[0.4588]`. It describes 4 overlapping `_StatCard` widgets around a central avatar, plus a blue "Continue Learning" panel pinned to the bottom.

**The good news:** `HomeDashboard` and `StudentDashboardHub` already exist and implement most of this vision. The task is a **structured refactor** — not a ground-up rebuild — that:
1. Closes color fidelity gaps (hardcoded hex → `AppColors` tokens)
2. Fixes positional accuracy of the 4 stat cards to match the Figma source
3. Replaces `google_fonts` dependency in `StudentDashboardHub` with `AppTextStyles`
4. Improves the avatar and pulsing indicator
5. Restores the atmospheric gradient background exactly
6. Integrates the Skill Map section into the scrollable body properly
7. Fixes the "Continue Learning" section layout

The **primary file** to edit is `home_dashboard.dart` (which `HomeScreen` already uses). `StudentDashboardHub` is a legacy draft; it will **not** be deleted, but will be left unused.

---

## User Review Required

> [!IMPORTANT]
> **Which file is authoritative?** `HomeScreen` currently passes data into `HomeDashboard`. `StudentDashboardHub` appears to be an earlier prototype that uses `google_fonts` and hardcoded hex colors. The plan below **only modifies `home_dashboard.dart`** and leaves `StudentDashboardHub` as-is. Confirm this is correct.

> [!WARNING]
> **`google_fonts` dependency:** `StudentDashboardHub` uses `GoogleFonts.inter(...)`. The project theme sets `fontFamily: 'Inter'` in `AppTheme`. For `home_dashboard.dart` we will use only `AppTextStyles` (no `google_fonts` import), keeping font rendering consistent with the theme. Confirm whether to also refactor or delete `StudentDashboardHub`.

> [!NOTE]
> **No new files.** All changes are surgical edits within `home_dashboard.dart` and `app_colors.dart`. No new widgets folder, no new models, no Firebase changes.

---

## React Source → Flutter Gap Analysis

Analyzing `App.tsx` against the current `HomeDashboard`:

| React element | Current Flutter state | Gap / Fix needed |
|---|---|---|
| Module Progress card — `left: 59px, top: 212px` (on 850px canvas) | `left: 20*scale, top: 40*scale` | ✅ Close enough after scale; keep |
| Module Progress — teal `#0F6E56` | Uses `AppColors.success` (`#1D9E75`) | ⚠️ **Wrong shade** — `#0F6E56` = `challengeTeal` which we'll add for Challenge Center. Map here to `AppColors.success` for now, or add `dashboardTeal`. See color table below. |
| Module Progress icon bg — `#E1F5EE` | Uses `AppColors.successLight` | ✅ Matches |
| Rank card — `left: 251px, top: 110px` (850px) | `right: 20*scale, top: 20*scale` | ✅ Approximate |
| Rank card — purple `#3C3489` | Uses `AppColors.primary` (`#1E3A8A`) | ⚠️ **Color mismatch** — needs `challengePurple` token |
| Rank icon bg — `#EEEDFE` | Uses `AppColors.primaryLight` (`#DBE4FF`) | ⚠️ **Wrong bg** — needs `challengePurpleLight` token |
| Best Skill card — amber `#854F0B` | Uses `AppColors.accent` (`#E89C1E`) | ⚠️ **Color mismatch** — needs `challengeAmber` token |
| Best Skill icon bg — `#FAEEDA` | Uses `AppColors.accentSubtle` (`#FAEEDA`) | ✅ Exact match |
| Weakest Skill card — coral `#993C1D` | Uses `AppColors.error` (`#CA2B2C`) | ⚠️ **Color mismatch** — needs `challengeCoral` token |
| Weakest Skill icon bg — `#FAECE7` | Uses `AppColors.errorLight` (`#FCEBEB`) | ⚠️ Close but not exact — needs `challengeCoralLight` token |
| Center avatar circle — white border, shadow | ✅ Implemented correctly | ✅ No change needed |
| Avatar initials fallback | ✅ Implemented | ✅ No change needed |
| Pulsing online indicator | ✅ Implemented with `AnimationController` | 🔧 Minor: move `AnimationController` from parent `_HomeDashboardState` to the `_PulseIndicator` widget to make it self-contained and testable |
| Background gradients (4 blurred beams) | ✅ 4 gradients positioned | ⚠️ Left/right positions from React don't match (`left: 431px` missing) |
| Continue Learning — blue `#213F95` | Uses `AppColors.primary` (`#1E3A8A`) | ✅ Close enough (3% hue shift, not perceptible) |
| Continue Learning — rounded top corners | ✅ `Radius.circular(40)` | ✅ No change needed |
| Continue Learning — progress bar | ✅ Implemented | 🔧 Minor: change `minHeight` from 4→5 to match design |
| Skill Map grid (`_SkillMapGrid`) | ✅ Implemented, 2-col `GridView` | 🔧 Minor: `childAspectRatio: 1.4` may need tuning on narrow screens — test |

---

## Color Tokens Required

Both this plan and the **Challenge Center plan** need the same tokens. They will be added to `app_colors.dart` in a single `// Challenge / Dashboard Accent Colors` section:

| Token name | Hex | Used by |
|---|---|---|
| `challengeAmber` | `#854F0B` | Best Skill card text/icon + Challenge Center |
| `challengeAmberLight` | `#FAEEDA` | ≡ `accentSubtle` — **REUSE** existing |
| `challengeCoral` | `#993C1D` | Weakest Skill card text/icon + Challenge Center |
| `challengeCoralLight` | `#FAECE7` | Weakest Skill icon bg + Challenge Center |
| `challengePurple` | `#3C3489` | Rank card text/icon + Challenge Center |
| `challengePurpleLight` | `#EEEDFE` | Rank icon bg + Challenge Center |
| `challengePurpleFill` | `#7F77DD` | Challenge Center progress bar only |
| `challengeTeal` | `#0F6E56` | Module Progress (exact Figma teal) |
| `challengeTealLight` | `#E1F5EE` | ≡ `successLight` — **REUSE** existing |
| `challengeGreen` | `#27500A` | Challenge Center "Done" pill text |
| `challengeGreenLight` | `#EAF3DE` | Challenge Center "Done" pill bg |

> [!NOTE]
> Several "new" tokens (`challengeAmberLight`, `challengeTealLight`) are just semantic aliases for existing values. They will be declared as `static const Color challengeAmberLight = accentSubtle` to avoid duplication.

---

## Proposed Changes

### Component 1 — Color Tokens

#### [MODIFY] [app_colors.dart](file:///c:/Flutter_Projects/my_ada/my_ada/lib/core/theme/app_colors.dart)

Add a new section at the bottom (before the closing `}`):

```dart
// ---------------------------------------------------------------------------
// Challenge Center / Dashboard Accent Palette
// (from homepage inspo Figma export + challenge_center wireframe)
// ---------------------------------------------------------------------------
static const Color challengeAmber      = Color(0xFF854F0B);
static const Color challengeAmberLight = accentSubtle;          // #FAEEDA — reuse
static const Color challengeCoral      = Color(0xFF993C1D);
static const Color challengeCoralLight = Color(0xFFFAECE7);
static const Color challengePurple     = Color(0xFF3C3489);
static const Color challengePurpleLight= Color(0xFFEEEDFE);
static const Color challengePurpleFill = Color(0xFF7F77DD);
static const Color challengeTeal       = Color(0xFF0F6E56);
static const Color challengeTealLight  = successLight;          // #E1F5EE — reuse
static const Color challengeGreen      = Color(0xFF27500A);
static const Color challengeGreenLight = Color(0xFFEAF3DE);
```

---

### Component 2 — HomeDashboard Refactor

#### [MODIFY] [home_dashboard.dart](file:///c:/Flutter_Projects/my_ada/my_ada/lib/features/home/presentation/widgets/home_dashboard.dart)

**The class contract (all parameters) stays exactly the same** — no breaking changes to `HomeScreen`.

##### 2a. Fix stat card colors

Replace the current `AppColors.xxx` arguments passed to each `_StatCard`:

| Card | Old color | New color | Old bg | New bg |
|---|---|---|---|---|
| Module Progress | `AppColors.success` | `AppColors.challengeTeal` | `AppColors.successLight` | `AppColors.challengeTealLight` |
| Your Rank | `AppColors.primary` | `AppColors.challengePurple` | `AppColors.primaryLight` | `AppColors.challengePurpleLight` |
| Best Skill | `AppColors.accent` | `AppColors.challengeAmber` | `AppColors.accentSubtle` | `AppColors.challengeAmberLight` |
| Weakest Skill | `AppColors.error` | `AppColors.challengeCoral` | `AppColors.errorLight` | `AppColors.challengeCoralLight` |

##### 2b. Fix card value font sizes to match Figma

The React source uses dramatically large type for the main value (`39px` for %, `48px` for rank, `30px` for skill names). The current `_StatCard` uses `24 * scale` uniformly. Two approaches:

- **Approach A (recommended):** Add an optional `valueFontSize` parameter to `_StatCard` (defaults to `24`). Pass `38` for Module Progress and `44` for Rank.
- **Approach B:** Use `FittedBox` with `fit: BoxFit.scaleDown` (already present) and let it shrink naturally.

**Plan uses Approach A** for accurate fidelity.

##### 2c. Fix gradient background positions

The React source defines 4 gradient pillars at these `left` positions on the 850px canvas:
- `46px` → scaled-to-390 proportional: `left: 21*scale`
- `431px` → `left: 197*scale` *(currently missing from Flutter impl)*
- `238px` → `left: 109*scale`
- `623px` → `left: 286*scale`

Current `_buildGradients` has positions at `46`, `46` (right), `238`, `623` — it's missing the `431px` pillar and has an incorrect right-side version. Fix all 4 positions.

##### 2d. Decouple `_PulseIndicator` animation

Currently, `AnimationController` lives in `_HomeDashboardState` and is passed down as a parameter. This is fragile because the pulse only works if the parent is rebuilding:

- **Change:** Make `_PulseIndicator` a `StatefulWidget` with its own `AnimationController` and `SingleTickerProviderStateMixin`. Remove `controller` param from `_PulseIndicator` and remove it from `_HomeDashboardState`.

##### 2e. Continue Learning section — minor polish

- Add `InkWell` ripple effect inside the `GestureDetector` (use `InkWell` directly)
- Add `Icon(Icons.arrow_forward_ios_rounded)` — already present, just confirm size is `16` not `18`
- Progress bar `minHeight` → `5` (from `4`)

---

## Widget Breakdown (Final Structure)

```
HomeDashboard (StatefulWidget — no AnimationController needed after 2d)
├── SingleChildScrollView
│   └── Column
│       ├── LayoutBuilder → Container (hub area, height = 480 * scale)
│       │   └── Stack
│       │       ├── _buildGradients(scale)          [4 atmospheric beams]
│       │       ├── _StatCard (Module Progress)      [Positioned top-left]
│       │       ├── _StatCard (Your Rank)            [Positioned top-right]
│       │       ├── _StatCard (Best Skill)           [Positioned mid-right]
│       │       ├── _StatCard (Weakest Skill)        [Positioned mid-left]
│       │       └── Align(center) → avatar + _PulseIndicator
│       ├── _ContinueLearningSection                 [InkWell, blue panel]
│       └── _SkillMapSection                         [white bg, GridView]

_StatCard (StatelessWidget)
  - title, value, subtext, icon, color, backgroundColor, scale, progress?, valueFontSize?

_PulseIndicator (StatefulWidget, owns AnimationController)
  - isOnline, scale

_SkillMapGrid (StatelessWidget)
  - skillResults: List<SkillResult>
```

---

## File Change Summary

| File | Type | Description |
|---|---|---|
| `lib/core/theme/app_colors.dart` | MODIFY | Add 11 `challengeXxx` color token constants |
| `lib/features/home/presentation/widgets/home_dashboard.dart` | MODIFY | Fix card colors, gradient positions, font sizes, self-contained pulse indicator, InkWell on Continue section |
| `lib/features/home/presentation/widgets/student_dashboard_hub.dart` | NO CHANGE | Legacy draft — left as-is |
| `lib/features/home/presentation/screens/home_screen.dart` | NO CHANGE | Contract unchanged |
| `lib/features/home/presentation/screens/dashboard_demo_screen.dart` | NO CHANGE | Contract unchanged |

**Total files modified: 2**

---

## Verification Plan

### Automated
```bash
# Must return zero errors
flutter analyze lib/core/theme/app_colors.dart
flutter analyze lib/features/home/presentation/widgets/home_dashboard.dart
```

### Visual Verification (side-by-side)
1. Run `DashboardDemoScreen` (accessible via temporary route or direct hot-reload)
2. Verify the 4 stat card colors now match the Figma screenshot:
   - Module Progress = deep teal `#0F6E56`
   - Rank = deep indigo `#3C3489`
   - Best Skill = amber `#854F0B`
   - Weakest Skill = burnt coral `#993C1D`
3. Verify the 4 atmospheric gradient beams are visible at correct horizontal positions
4. Toggle `isOnline: false` → confirm red dot, no pulse
5. Toggle `isOnline: true` → confirm green pulsing dot
6. Tap Continue Learning section → confirm `onContinuePressed` fires
7. Test on a narrow device (360px width) — confirm no overflow

### Flutter Analyze Target: 0 errors, 0 warnings
