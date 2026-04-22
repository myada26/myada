# Concept C — Home Screen Refactor — Implementation Plan

## Overview

**Goal:** Replace `home_screen.dart`'s current delegation pattern (which renders `HomeDashboard` — a Stack-based, scaled hub layout) with a clean, scrollable "Concept C" four-section layout: **Header → 2×2 Metric Grid → Skill Rings → Module Progress List**.

**Strategy:** The entire implementation lives inside `home_screen.dart` only. No new files. No new data services. Everything binds to existing already-wired controllers.

---

## Current State vs Target State

| Aspect | Current | Target (Concept C) |
|---|---|---|
| Layout engine | `Stack` + `Positioned` (hub) | `CustomScrollView` with `SliverList` |
| Main widget | `HomeDashboard` (separate file) | All private widgets in `home_screen.dart` |
| Data binding | Passes args to `HomeDashboard` | State vars at top of `_HomeScreenState` |
| Skill display | 2 cards (best/weakest) | 4 circular `_SkillRing` widgets in a row |
| Module display | None | Full `_ModuleProgressList` |
| `HomeDashboard` | **Stays untouched** | `HomeDashboard` import removed from this file |

> [!NOTE]
> `HomeDashboard`, `StudentDashboardHub`, and `DashboardDemoScreen` are **not touched**. They remain in place for future use or the HomeDashboard plan.

---

## Data Wiring Map

All state variables are already obtainable from existing services. No new network calls or models needed.

| UI Element | State Variable | Source | Already in file? |
|---|---|---|---|
| `"Hi, Eden"` greeting | `_firstName` (String) | `AuthController.currentUser?.firstName` | ✅ partially |
| Accent card: module name | `_currentModuleName` (String) | `LearningPathController.result?.startHereModule?.name` | ✅ |
| Accent card: completion % | `_moduleProgress` (double 0–1) | Average of `SkillResult.barFraction` across all skills | ✅ |
| Streak metric | `_streak` (int) | `RankedStudent.currentStreak` (from `LeaderboardService`) | ✅ (loaded via `_loadRankData`) |
| Rank metric | `_studentRank` (int) | `RankedStudent.rank` | ✅ |
| Points metric | `_totalPoints` (int) | `RankedStudent.totalPoints` | ⚠️ **ADD** — currently only `_studentRank` and `_pointsBehind` are stored |
| Skill rings (×4) | `_skillResults` (List\<SkillResult\>) | `LearningPathController.result?.skillResults` | ✅ |
| Module list | `_modules` (List\<LearningModule\>) | `LearningPathController.result?.learningPath` | ✅ (via `pathCtrl`) |

### State Variables to Add/Change

**Add** to `_HomeScreenState`:
```dart
// New state variables for Concept C
String _firstName = '';
int _totalPoints = 0;
int _streak = 0;
```

**Remove** (no longer used by Concept C):
```dart
// int _pointsBehind = 0;  // Not displayed in Concept C — remove or keep for future
```
→ Keep `_pointsBehind` but mark it unused — **do not delete** — it may be needed later.

**Update** `_loadRankData()`:
```dart
Future<void> _loadRankData() async {
  final all = await LeaderboardService.instance.getRankedStudents();
  if (!mounted) return;
  final me = all.where((s) => s.isCurrentUser).firstOrNull;
  setState(() {
    _studentRank  = me?.rank          ?? 0;
    _pointsBehind = me != null ? me.gapToAbove(all) : 0;
    _totalPoints  = me?.totalPoints   ?? 0;   // NEW
    _streak       = me?.currentStreak ?? 0;   // NEW
  });
}
```

---

## Four-Section Layout Architecture

```
Scaffold
└── SafeArea
    └── CustomScrollView
        ├── SliverToBoxAdapter → _HeaderSection
        ├── SliverPadding
        │   └── SliverToBoxAdapter → _MetricGrid (2×2)
        ├── SliverPadding
        │   └── SliverToBoxAdapter → _SkillRingsRow
        └── SliverPadding
            └── SliverList → _ModuleProgressList items
```

---

## Section 1 — `_HeaderSection`

**Data:** `firstName` (String)

**Layout:**
```
Row (horizontal padding: AppSpacing.screenPadding)
├── Column
│   ├── Text("Hi, $firstName 👋", style: AppTextStyles.h2)
│   └── Text("Here's your progress", style: AppTextStyles.bodyMuted)
└── Spacer
    └── [Avatar initials circle — small, 36px]
```

**AppColors:** `AppColors.foreground` for name, `AppColors.mutedForeground` for subtitle.

---

## Section 2 — `_MetricGrid` + `_MetricCard`

A 2×2 grid using `GridView.count` (or two `Row`s — see note below).

> [!IMPORTANT]
> **Use two `Row`s inside a `Column`, NOT a `GridView`** — this avoids the `shrinkWrap + CustomScrollView` nesting issues that cause layout exceptions. Each row gets two `Expanded` children.

### Grid Cells

| Position | Widget | Data | Accent Color | Background |
|---|---|---|---|---|
| Top-left | **Accent Card** | `_currentModuleName`, `_moduleProgress` | `AppColors.primaryForeground` (text) | `AppColors.primary` |
| Top-right | "Streak" metric | `_streak` days | `AppColors.accent` | `AppColors.surface` |
| Bottom-left | "Rank" metric | `#$_studentRank` | `AppColors.challengePurple` | `AppColors.surface` |
| Bottom-right | "Points" metric | `$_totalPoints` | `AppColors.challengeTeal` | `AppColors.surface` |

### `_MetricCard` parameters
```dart
class _MetricCard extends StatelessWidget {
  final String label;       // e.g. "STREAK"
  final String value;       // e.g. "12"
  final String? subtitle;   // e.g. "days" or "Module 3 · Functions"
  final Color valueColor;
  final Color backgroundColor;
  final bool isAccent;      // true = primary card with progress bar
  final double? progress;   // 0.0–1.0, only for accent card
  ...
}
```

### Accent Card internal layout
```
Container (bg: AppColors.primary, radius: AppRadius.xl)
└── Column (crossAxisAlignment: start, padding: AppSpacing.cardPadding)
    ├── Text("MODULE",  style: caption, color: primaryForeground/60%)
    ├── SizedBox(height: AppSpacing.xs)
    ├── Text(_currentModuleName, style: h4, color: primaryForeground, maxLines: 2)
    ├── Spacer
    ├── Text("${(_moduleProgress*100).round()}%", style: h2, color: primaryForeground)
    └── [thin white LinearProgressIndicator, value: _moduleProgress]
```

### Surface Metric Card internal layout
```
Container (bg: AppColors.surface, border: AppColors.border, radius: AppRadius.xl)
└── Column (padding: AppSpacing.cardPadding)
    ├── Text(label, style: AppTextStyles.caption + color: mutedForeground, letterSpacing: 0.5)
    ├── Spacer
    ├── Text(value, style: AppTextStyles.h1, color: valueColor)
    └── Text(subtitle, style: AppTextStyles.bodySm, color: mutedForeground)
```

---

## Section 3 — `_SkillRingsRow` + `_SkillRing`

**Data:** `List<SkillResult> skillResults`

A single `Row` with 4 `Expanded` children, each containing a `_SkillRing`.

### Skill display order (fixed — matches diagnostic order):
1. Sequencing → label "Sequencing", short label "Seq."
2. Logic Flow → short label "Logic"
3. Debugging → short label "Debug"
4. Syntax → short label "Syntax"
5. Comp. Thinking → short label "Think." *(shown only if space — show 4 primary)*

> [!NOTE]
> Show exactly **4 rings** (the 4 most educationally prominent skills). Use indices 0–3: Sequencing, Logic Flow, Debugging, Syntax. Computational Thinking is excluded from the ring row to avoid cramping on 360px screens.

### `_SkillRing` widget:
```dart
// Uses Stack: CircularProgressIndicator behind a centered Text
Stack(alignment: Alignment.center,
  children: [
    SizedBox(72×72,
      child: CircularProgressIndicator(
        value: barFraction,
        strokeWidth: 6,
        backgroundColor: AppColors.surfaceVariant,
        valueColor: AlwaysStoppedAnimation(_ringColor(level)),
      )
    ),
    Text("${(barFraction * 100).round()}%", style: AppTextStyles.label),
  ]
)
Text(shortLabel, style: AppTextStyles.bodySm)  // below ring
```

### Ring color mapping:
| SkillLevel | Color |
|---|---|
| `confident` | `AppColors.success` (`#1D9E75`) |
| `building` | `AppColors.primary` |
| `developing` | `AppColors.warning` |
| (empty / zero) | `AppColors.surfaceVariant` |

---

## Section 4 — `_ModuleProgressList` + `_ModuleRow`

**Data:** `List<LearningModule> modules` from `LearningPathController.result?.learningPath ?? []`

Rendered as a `SliverList.separated` inside the `CustomScrollView`.

### `_ModuleRow` layout per module:
```
Column
├── Row
│   ├── Expanded → Column
│   │   ├── Text("M${n}. ${module.name}", style: AppTextStyles.labelSm, color: fgColor)
│   │   └── Text(statusLabel, style: AppTextStyles.bodySm, color: mutedColor)
│   └── Text(percentText, style: AppTextStyles.label, color: accentColor)
└── SizedBox(height: 6)
└── ClipRRect(radius: AppRadius.full)
    └── LinearProgressIndicator(value: progressValue, ...)
```

### Module status → display mapping:
| `ModuleStatus` | Progress value | Text label | Bar color | Text color |
|---|---|---|---|---|
| `mastered` | `1.0` | "Mastered ✓" | `AppColors.success` | `AppColors.success` |
| `completed` | `1.0` | "Completed" | `AppColors.success` | `AppColors.success` |
| `inProgress` | `0.0–1.0` (TODO: wire ProgressService later) | "In Progress" | `AppColors.primary` | `AppColors.primary` |
| `required` (startHere) | `0.0` | "Start here →" | `AppColors.primary` | `AppColors.primary` |
| `required` | `0.0` | "Required" | `AppColors.border` | `AppColors.mutedForeground` |
| `recommended` | `0.0` | "Recommended" | `AppColors.border` | `AppColors.accent` |
| `locked` | `0.0` | "Locked" | `AppColors.border` | `AppColors.mutedForeground` |

---

## Imports — Changes to `home_screen.dart`

**Remove:**
```dart
import '../widgets/home_dashboard.dart';  // No longer used
```

**Keep all others** (Provider, AuthController, LearningPathController, AppColors, LeaderboardService, LearningPathModel, AppRoutes from main.dart).

**Add:**
```dart
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
```

---

## File Change Summary

| File | Change type | Description |
|---|---|---|
| `lib/features/home/presentation/screens/home_screen.dart` | **REPLACE** | Full rewrite — new Concept C layout, all private widgets inside the file |
| No other files | — | Zero changes to theme, nav shell, or other screens |

---

## Quality Checklist

- [ ] No raw hex colors — all colors via `AppColors`
- [ ] No raw font sizes — all typography via `AppTextStyles`
- [ ] No raw spacing numbers — all via `AppSpacing` / `AppRadius`
- [ ] No hardcoded module/skill text buried in build methods
- [ ] `HomeDashboard` import removed; `HomeDashboard` class itself untouched
- [ ] `_pointsBehind` kept but marked with `// TODO: wire to "rank gap" display`
- [ ] `SafeArea` wraps the entire scaffold body
- [ ] `CustomScrollView` with Slivers — no `shrinkWrap` anti-patterns
- [ ] `_moduleRow` uses `isStartHere` flag to show "Start here →" label
- [ ] All null states have sensible defaults (`''`, `0`, `[]`)
- [ ] Zero `flutter analyze` warnings

## Verification Plan

### Automated
```bash
flutter analyze lib/features/home/presentation/screens/home_screen.dart
```

### Manual (hot-reload)
1. Launch → Home tab shows Concept C layout (not hub/dial design)  
2. Header shows first name from `AuthController`  
3. Streak, Rank, Points cards show real data (or 0 for fresh user)  
4. 4 skill rings render with correct colors per skill level  
5. Module list shows all 12 modules with correct status labels  
6. No overflow on 360px width device  
7. `_onContinue` still fires on the "start here" module row tap (optional CTA)
