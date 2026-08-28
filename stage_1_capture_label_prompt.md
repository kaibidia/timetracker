# Claude Code Prompt — Stage 1: Capture & Label

Read `personal_time_tracker_spec_v2.md` and inspect the existing repository before making changes.

Work on **Stage 1 only**.

Do not continue to later stages automatically. When Stage 1 is complete, build/test it, report the result, and **STOP**.

## Goal

Build the smallest version of the app that can be installed on a real iPhone and used for several days as a genuine personal time-tracking experiment.

The product hypothesis for this stage is:

> Can activity transitions be captured frequently enough, with low enough friction, that continuous personal time tracking is viable?

This stage should support:

- manually starting tracking
- recording activity transitions
- converting timestamps into continuous intervals
- labeling current and completed intervals
- custom activities
- editing timestamps manually
- undoing the latest transition
- persistence across app restarts

Do **not** add analytics, calendar integration, alarms, reminders, WHOOP, HealthKit, predictions, cloud sync, accounts, backend infrastructure, goals, productivity scoring, or other future functionality.

---

## 1. Product semantics

The core interaction means:

> **My activity changed now.**

Tracking is continuous after the user explicitly starts it.

Each confirmed transition creates a timestamp. Adjacent timestamps define intervals.

Example:

```text
09:12        10:43          11:08
  ●────────────●──────────────●──────→
       Work          Food       current
```

An interval may have an Activity assigned.

Do not expose implementation terminology such as `TimeBoundary` to the user. In the UI, use human concepts such as periods, activities, timeline, current activity, etc.

Preserve raw timestamps faithfully. Higher-level interpretations can be derived later.

---

## 2. Data model

Use SwiftData and Apple-native frameworks only.

Keep the model simple and robust.

### Activity

At minimum:

```text
id
name
icon
color
createdAt
isArchived
```

An Activity is fundamentally:

> **name + icon + color**

There is no required parent category or hierarchy.

Built-in activities and custom activities should use the same underlying model.

### Timeline data

Use a model that safely represents:

- transition timestamps
- intervals between timestamps
- current/open interval
- optional activity assignment
- manual timestamp editing

You may choose whether intervals are stored directly or derived from transition timestamps, but preserve these invariants:

1. Timeline intervals are continuous while tracking is active.
2. Moving a shared timestamp updates both adjacent intervals correctly.
3. Deleting a timestamp joins the adjacent periods without creating a gap.
4. Adding a timestamp splits an existing period.
5. No accidental overlaps or gaps should be created by normal editing.
6. Midnight is **not** stored as an artificial transition.

Prefer the simplest model that makes these invariants reliable.

Do not overengineer for future calendar/WHOOP/prediction functionality.

---

## 3. First start

Do not fabricate activity before tracking begins.

Before the first timestamp, show a calm empty state such as:

> **Ready when you are**  
> Start tracking to create your first point in time.

The user starts tracking manually.

Alarm-assisted starting is future scope.

---

## 4. Main capture control

The capture control is the central product interaction and should receive careful implementation.

It is **not** a normal tap button.

### Visual concept

Use a large circular control combining the ideas of:

- a soft filled/gradient disc
- a ripple circle

The interaction sequence is:

> **REST → PRESS → FILL → COMMIT → RIPPLE → REST**

### Interaction behavior

On touch-down:

1. Capture a candidate timestamp immediately.
2. Begin a short hold-to-confirm animation.
3. Slightly scale/press the control inward.
4. Fill should grow **from the center outward**.

Target hold duration for the first implementation:

> approximately **500 ms**

Keep the duration easy to tune after testing on a physical iPhone.

### Cancellation

If the finger is released or leaves the valid control area before the fill completes:

- cancel the transition
- collapse/reset the fill
- discard the candidate timestamp
- do not modify the timeline

### Commit

When the fill reaches completion:

1. Commit the transition using the **original touch-down timestamp**, not the completion timestamp.
2. Close the previous interval.
3. Create the new current/open interval.
4. Trigger one crisp haptic confirmation.
5. Emit a soft outward ripple.
6. Return the control to rest.

Do not use a checkmark.

The visual fill reaching completion + haptic + ripple is the confirmation.

The interaction should feel satisfying but extremely fast in repeated daily use.

---

## 5. Visual direction

Use a calm, native-feeling iOS interface with an **autumn-inspired** visual language.

The design should feel warm and slightly cute/cozy, but not literally seasonal or decorative.

Think:

- warm ivory / cream
- terracotta
- burnt orange
- muted amber
- chestnut
- warm charcoal for dark mode

The closest visual direction from our exploration is roughly **Maple Glow / Falling Leaf**, but without literal leaf or pumpkin decoration.

Use softness, subtle depth, color and motion to create the autumn feeling.

Avoid:

- literal seasonal illustrations
- excessive gradients
- glossy Web3-style orbs
- bright productivity-app colors
- gamification visuals
- streaks
- dashboard clutter
- excessive cards

The ripple may use slightly organic easing rather than perfectly mechanical motion.

Support both light and dark mode.

Use system typography unless there is a very strong reason not to.

---

## 6. Main screen

Stage 1 should primarily be **one screen**.

Do not add bottom navigation yet.

The visual hierarchy should be:

1. date / minimal context
2. current activity / current interval duration
3. main capture control
4. today's timeline

Conceptually:

```text
Friday, 28 August


             WORK

             1h 24m
          since 14:08


              ◯
              ·

         ACTIVITY CHANGED


TODAY

14:08                  NOW
●────────────────────────◉
          Work
          1h 24m

13:31                14:08
●──────────────────────●
        Dog walk
           37m

12:46                13:31
●──────────────────────●
          Food
           45m
```

This is a conceptual hierarchy, **not a pixel-perfect layout requirement**.

Use judgment to make it feel like a polished native iPhone app.

The timeline should visually communicate that periods exist **between points in time**.

---

## 7. Current interval

Show the current/open interval prominently.

At minimum show:

- activity name if classified
- otherwise a calm `Unclassified` state
- elapsed duration
- start time

Do not update unnecessarily every second. Minute-level duration updates are sufficient unless implementation simplicity strongly favors otherwise.

The current interval can be labeled or relabeled while it is still active.

---

## 8. Activity labeling

Both completed intervals and the current interval can be labeled.

Tapping an interval should open a lightweight activity picker.

The picker should support:

- recent/common activities prominently
- all available activities
- one-tap selection
- creation of a new custom activity

Do **not** automatically open the picker after every capture.

Capture must remain independently frictionless:

> open app → hold capture control → haptic → leave

Classification is available immediately if wanted, but never required at capture time.

---

## 9. Default activities

Provide a small sensible starter set.

For example:

- Work
- Food
- Dog / Pet
- Exercise
- Social
- Commute
- Personal Care
- Housework
- Learning
- Entertainment
- Phone / Social Media
- Sleep

Do not treat this taxonomy as special or authoritative.

The user must be able to create specific activities such as:

- Greek
- Instagram
- Piano
- Sewing
- Dog walk

Use **SF Symbols** for icons in Stage 1.

Each activity should have a color.

Keep the color palette coherent with the warm visual direction while still making activities distinguishable.

Do not build a custom icon system yet.

---

## 10. Editing

Manual correction is part of Stage 1 because this version will be used with real behavioral data.

### Undo latest transition

After a successful transition, make **Undo** easily available for a short period or through an obvious lightweight mechanism.

Undo should remove the latest transition and restore the previous open interval correctly.

### Move timestamp

The user can edit an existing transition time.

Example:

```text
10:43 → 10:55
```

Because the timestamp is shared, both adjacent periods must update correctly.

Prevent invalid ordering.

A timestamp must not move beyond its neighboring transitions.

### Add timestamp

The user can manually insert a transition inside an existing period.

Example:

```text
18:00 ─────────────────── 21:00

              ↓

18:00 ───── 19:20 ─────── 21:00
```

This is the Stage 1 solution for forgotten taps.

After splitting, the resulting periods can be labeled independently.

### Delete timestamp

The user can delete an existing transition.

This merges the adjacent periods.

If both periods have the same activity, preserve it automatically.

If their labels differ, do not silently choose one. Present a simple resolution choice, including leaving the merged interval unclassified if appropriate.

Do not implement automatic reconstruction or smart suggestions yet.

---

## 11. Midnight behavior

An interval crossing midnight remains a **single underlying interval**.

Example stored conceptually as:

```text
23:30 ───────────────── 00:45
```

Do not create a synthetic transition at 00:00.

For daily visualization and future daily aggregation, split it visually:

```text
FRIDAY
23:30 → 00:00   30m

SATURDAY
00:00 → 00:45   45m
```

The visualization split must not mutate the underlying timeline data.

---

## 12. Persistence

All timeline data and activities must persist locally across:

- app backgrounding
- app termination
- app relaunch
- device restart where normal local persistence permits

Duration must be calculated from timestamps.

Do not depend on a continuously running background timer.

---

## 13. Explicitly out of scope

Do not implement or scaffold unnecessary infrastructure for:

- calendar integration
- alarms
- reminders
- notifications
- WHOOP
- HealthKit
- statistics dashboards
- learned suggestions
- automatic classification
- ML / Core ML
- AI
- goals
- productivity scoring
- streaks
- activity hierarchy/categories
- accounts
- authentication
- cloud sync
- CloudKit
- backend services
- Firebase
- Supabase
- Realm
- analytics SDKs
- third-party Swift packages

Use Apple-native frameworks only.

Do not build abstractions solely because a future stage might theoretically need them.

---

## 14. Testing requirements

Before declaring Stage 1 complete:

### Build

- build successfully with no compiler errors
- fix meaningful warnings introduced by this work
- run in iOS Simulator
- verify physical-device build/signing if the repository/environment is already configured for it

### Functional tests

Test at minimum:

1. First manual start creates the first tracking point correctly.
2. Successful ~500 ms hold creates exactly one transition.
3. Quick release does not create a transition.
4. Dragging/leaving the control before completion cancels safely.
5. Rapid repeated interaction does not create duplicate transitions.
6. Touch-down timestamp is used rather than animation-completion timestamp.
7. Current interval duration survives app close/reopen.
8. Label completed interval.
9. Label current interval.
10. Relabel an interval.
11. Create custom activity with icon/color.
12. Undo latest transition.
13. Add historical timestamp.
14. Move timestamp.
15. Reject invalid timestamp ordering.
16. Delete timestamp.
17. Resolve deletion when neighboring activities differ.
18. Data survives relaunch.
19. Interval crossing midnight remains one underlying interval.
20. Daily visualization splits a midnight-crossing interval correctly without modifying stored data.

Add automated tests where they provide real value, especially around timeline invariants and editing behavior.

Do not create tests merely to inflate coverage.

---

## 15. Real-iPhone manual test plan

At the end, provide exact instructions for installing/running the app on the configured physical iPhone.

Also provide a short manual experiment checklist for 3–5 days of real usage.

We want to observe:

- how often transitions are remembered
- how often timestamps need retrospective insertion/editing
- whether ~500 ms hold feels too long, too short, or right
- whether accidental captures occur
- whether classification happens immediately, during an activity, or retrospectively
- which custom activities are actually created
- which editing actions are used most
- whether the timeline is useful during the day

Do not attempt to solve these questions in code yet.

The point of Stage 1 is to collect evidence.

---

## 16. Implementation workflow

Before coding:

1. Inspect the existing repository.
2. Read the current spec.
3. Briefly summarize the existing architecture/state.
4. State a short implementation plan for **Stage 1 only**.

Then implement.

After implementation:

1. Build the app.
2. Run relevant tests.
3. Fix errors.
4. Inspect the final Git diff.
5. Ensure no machine-specific or secret files were added.
6. Commit the completed stage.

Suggested commit message:

```text
stage 1: implement capture and labeling
```

Do not continue to Stage 2.

---

## 17. Final response format

When finished, report:

### Implemented
Concise summary of Stage 1 behavior.

### UX
Describe the final capture interaction, including actual hold duration and animation behavior implemented.

### Files changed
List important files and what each is responsible for.

### Data model
Briefly explain the chosen timestamp/interval representation and why.

### Tests
List automated and manual tests performed.

### Build status
State simulator and physical-device status separately. Do not claim physical-device success unless actually verified.

### Run on iPhone
Give exact steps.

### 3–5 day experiment
Give the short real-world observation checklist.

### Known limitations
Only genuine Stage 1 limitations; do not turn this into a roadmap.

### Git
Show final Git status and commit hash.

Then **STOP and wait for the next instruction.**
