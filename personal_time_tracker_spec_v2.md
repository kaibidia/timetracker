# Personal Time Tracker --- Product & Technical Specification

## 1. Product concept

Build a native iPhone personal time tracker designed around one core
principle:

**Capture first, classify later.**

The user taps one button whenever their activity changes. The app
records the boundary immediately without asking what the user is doing.
The periods created between boundaries can be classified later.

The product should make it realistic to track an entire day with minimal
interruption.

## 2. Core user loop

1.  User starts the day with an active/open period.
2.  Whenever their activity changes, they tap one large button.
3.  The app records the current timestamp immediately.
4.  The previous period ends and a new open period begins.
5.  No activity selection is required at capture time.
6.  Later, the user reviews the timeline and classifies periods.
7.  The user can choose from their standard activities or create a
    custom activity.
8.  Over time, a future version should learn the user's patterns and
    suggest likely classifications.

## 3. Product principles

-   Recording a boundary should take approximately one second.
-   Never force classification at capture time.
-   Local-first and private by default.
-   Corrections must be easy because users will forget or mistime taps.
-   Unclassified time is normal, not an error.
-   Calm, native iOS design; no productivity guilt.
-   No streaks or gamification.
-   Suggestions should eventually reduce classification effort, but
    should not silently override the user.

## 4. Platform and technology

Native iPhone application.

Preferred stack:

-   Swift
-   SwiftUI
-   SwiftData
-   Swift Charts for later statistics
-   Apple-native haptics
-   Git for source control

For the initial versions:

-   local storage only
-   no backend
-   no external database
-   no authentication
-   no accounts
-   no cloud service
-   no analytics SDK
-   no third-party dependencies unless explicitly approved
-   no AI API

The application should be installable and testable on a real iPhone
through Xcode during development.

## 5. Initial data model

### Activity

-   `id: UUID`
-   `name: String`
-   `icon: String?`
-   `createdAt: Date`
-   `isArchived: Bool`
-   `sortOrder: Int`

Initial suggested activities:

-   Work
-   Sleep
-   Commute
-   Food
-   Exercise
-   Social
-   Entertainment
-   Housework
-   Learning
-   Personal care
-   Pet care
-   Phone / Social media

Users can create custom activities such as Greek, Piano, Sewing,
Instagram, Dog walk, Shopping, etc.

### TimeBoundary

Represents the moment the user says: "my activity changed now."

-   `id: UUID`
-   `timestamp: Date`
-   `createdAt: Date`

### TimeIntervalEntry

Represents a period of time.

-   `id: UUID`
-   `startTime: Date`
-   `endTime: Date?`
-   `activity: Activity?`
-   `createdAt: Date`
-   `updatedAt: Date`

`endTime == nil` can represent the current open interval.

The exact persistence model may be adjusted during implementation if
there is a simpler robust way to preserve boundary continuity.

## 6. Primary tracking behavior

When the user taps the main tracking button:

1.  Capture `Date.now` immediately.
2.  Give haptic confirmation.
3.  Close the current open interval at that timestamp.
4.  Create a new open interval starting at the same timestamp.
5.  Do not ask for an activity.
6.  Keep the user on the main screen.

Stored duration must be based on timestamps, not on a continuously
running background timer.

If the app is closed for two hours, reopening it should correctly
calculate the current interval duration from its stored start timestamp.

## 7. Main product surfaces

### Today

Primary tracking surface.

Eventually contains:

-   date
-   current open period
-   elapsed duration
-   large activity-change button
-   recent periods from today

### Timeline

Chronological periods for a selected day.

Example:

-   08:02--08:43 --- Dog walk --- 41m
-   08:43--09:11 --- Personal care --- 28m
-   09:11--09:47 --- Unclassified --- 36m
-   09:47--12:31 --- Work --- 2h 44m

### Classification

An interval can be assigned an activity later.

The classification UI should provide:

1.  likely/recent activities
2.  the user's standard activity list
3.  `+ New activity`

A custom activity becomes part of the reusable activity list.

### Stats

Later MVP stage.

Basic views:

-   today
-   last 7 days
-   duration by activity
-   classified vs unclassified time
-   simple Swift Charts visualization

### Settings

Eventually includes activity management:

-   create
-   rename
-   reorder
-   archive
-   icon selection

Archived activities remain attached to historical data.

## 8. Correction behavior

Correction UX is a core requirement, not an optional administrative
feature.

Support later in MVP:

-   edit a boundary time
-   split an interval
-   undo accidental latest tap
-   delete an accidental boundary
-   optionally merge adjacent intervals

Adjacent intervals should remain continuous.

If:

-   A = 09:00--10:00
-   B = 10:00--11:00

and the shared boundary is changed to 10:15:

-   A = 09:00--10:15
-   B = 10:15--11:00

Do not accidentally create overlaps or negative-duration intervals.

## 9. Batch classification

After the basic classification flow works, add a fast "Complete your
day" flow.

The user should be able to classify consecutive unclassified intervals
quickly without repeatedly opening and closing detail screens.

Target experience: an ordinary tracked day should eventually be
classifiable in roughly 1--3 minutes.

## 10. Future learned suggestions

Do not implement in the first stages, but preserve the possibility in
the architecture.

The app should eventually learn likely activities from personal history
using signals such as:

-   weekday
-   time of day
-   duration
-   previous activity
-   next activity when known
-   historical activity frequency
-   common activity transitions

Example:

Weekday + approximately 08:00 + 30--60 minute duration may make
`Dog walk` highly likely for a particular user.

The first implementation does not need ML. A transparent local
scoring/probability model is preferable until there is evidence that
more sophisticated ML is useful.

Future classification UI:

-   `Suggested: Dog walk`
-   followed by other likely/common activities
-   always allow the full standard list
-   always allow custom activity creation

Corrections should become training/history data.

Track prediction quality when this feature is introduced:

-   Top-1 accuracy
-   Top-3 accuracy
-   clicks/taps required to classify

Prediction philosophy:

**Suggest, don't assume.**

Automatic classification, if ever implemented, should be opt-in and
reserved for very high-confidence patterns.

## 11. Privacy

Personal timelines can contain intimate behavioral information.

Default architecture should remain local-first.

No timeline data should leave the device unless a future feature
explicitly requires it and the user knowingly opts in.

## 12. MVP acceptance criteria

A useful MVP eventually allows the user to:

1.  install and run the app on their iPhone
2.  tap one button whenever their activity changes
3.  receive immediate haptic confirmation
4.  never classify at capture time
5.  review every recorded period later
6.  classify periods using reusable activities
7.  create custom activities
8.  correct forgotten/mistimed boundaries
9.  split intervals
10. undo accidental taps
11. retain history across app restarts
12. see basic daily/weekly statistics

## 13. Incremental development plan

Development must happen in small, testable stages.

Each stage must end with:

-   a buildable application
-   no known compiler errors
-   a concise summary of what changed
-   manual test cases
-   explicit instructions for how to run/test the build
-   no automatic continuation to the next stage

### Stage 0 --- Environment setup

Goal: prepare a reproducible local iOS development environment and
verify that a minimal app can run in the simulator and, where possible,
on the user's real iPhone.

No product functionality yet.

### Stage 1 --- Skeleton

Goal: produce a stable app shell.

Includes:

-   SwiftUI app
-   SwiftData configured
-   bottom navigation: Today / Timeline / Stats / Settings
-   simple placeholder/empty states
-   system light/dark mode
-   basic project structure

No tracking business logic yet.

### Stage 2 --- Core capture button

Implement the real boundary-capture loop and persistence.

This is the first stage to test for several hours in real life.

### Stage 3 --- Daily timeline

Make a full tracked day visible and navigable.

### Stage 4 --- Classification

Assign standard/custom activities to intervals.

### Stage 5 --- Fast day completion

Optimize retrospective classification.

### Stage 6 --- Corrections

Boundary editing, split, delete, undo.

### Stage 7 --- Activity library

Manage reusable personal activities.

### Stage 8 --- Statistics

Build analytics only after real tracking data exists.

### Stage 9 --- Simple learned suggestions

Local rule/probability-based ranking; no unnecessary ML.

### Stage 10 --- Improved personal learning

Only after evaluating suggestion quality on actual usage data.

## 14. Development rule for coding agents

Do not implement future stages proactively.

For every stage:

1.  inspect the existing code
2.  state a short implementation plan
3.  implement only the requested stage
4.  build and fix errors
5.  add appropriate tests
6.  report files changed
7.  provide manual test steps
8.  stop and wait for user feedback

Avoid speculative architecture for features that have not yet been
requested.

Do not introduce Firebase, Supabase, Realm, external servers, external
databases, analytics SDKs, dependency-injection frameworks, or other
third-party dependencies unless explicitly requested.


## 15. Multi-source personal timeline

The long-term product should combine several distinct sources of information while keeping their meanings separate.

### Actual activity
Primary source:
- manual boundary taps
- retrospective classification
- corrections

This remains the authoritative activity timeline.

### Planned activity
Calendar data represents what was scheduled or intended, not necessarily what actually happened.
Calendar events must never silently overwrite the activity timeline.

Calendar information can be used for:
- reminders
- activity suggestions
- retrospective reconstruction
- smart interval splitting
- future prediction features

### Body state
WHOOP or other health/wearable data represents physiological state.

Potential signals include:
- sleep
- recovery
- strain
- workouts
- HRV
- resting heart rate

This data should enrich analytics and pattern discovery, not replace activity classification.

Conceptually:
- **Calendar = planned**
- **Tracker = actual**
- **WHOOP / health data = physiological context**

## 16. Calendar integration

Calendar integration is an important future feature.

Use Apple-native calendar access where practical, preferably EventKit for iOS calendar data.

The app should request calendar permission explicitly and remain fully usable if the user declines.

Do not require a backend for basic calendar access.

### Calendar principles

Calendar events are suggestions/context, not ground truth.

Never assume that a scheduled event actually happened.

Never automatically classify time solely because a matching calendar event existed unless the user explicitly enables a future auto-classification feature.

### Upcoming event reminders

The user should be able to opt in to reminders related to upcoming calendar events.

Example:

`Greek class starts at 18:00`

Actions may include:
- `Start Greek`
- `Not now`

If the user accepts the reminder:
- create a boundary at the moment of acceptance
- assign the new open interval to the suggested activity when a mapping is known

Ignoring or dismissing the reminder makes no changes to the timeline.

### Event-to-activity mapping

The app should eventually learn/store mappings between recurring calendar event patterns and activity types.

Examples:
- `Greek` → `Greek`
- `Pilates` → `Exercise`
- `1:1` → `Work` or `Meeting`

Initially these mappings should require user confirmation.

Possible model:

### CalendarActivityMapping
- `id: UUID`
- `matchType`
- `matchValue`
- `activityId`
- `createdAt`
- `confirmationCount`

### Retrospective reconstruction

Calendar context should help when the user forgot to tap.

Example existing interval:

`17:52–19:14 — Unclassified`

Calendar:

`18:00–19:00 — Greek class`

Suggested reconstruction:

- 17:52–18:00 — Unclassified
- 18:00–19:00 — suggested Greek
- 19:00–19:14 — Unclassified

The user must confirm or edit this reconstruction.

## 17. Reminder and notification behavior

Use local notifications where possible.

Notifications must be opt-in.

Potential reminder types:
- upcoming calendar event
- unusually long open interval
- evening reminder to classify the day
- later, a likely upcoming activity transition

Keep notifications conservative and user-configurable.

## 18. WHOOP integration

WHOOP integration is a future feature and should not be implemented during the initial local MVP.

The purpose is to enrich the personal timeline with physiological context.

Potential imported data:
- sleep
- recovery
- strain
- workouts
- HRV
- resting heart rate

### Architecture principle

The tracker must remain fully useful without WHOOP.

WHOOP is an optional integration.

Do not make the core activity model depend on wearable data.

### Data separation

Store wearable observations separately from activity intervals.

Possible conceptual model:

### PhysiologicalDailySummary
- `date`
- `recoveryScore`
- `strain`
- `sleepDuration`
- `sleepPerformance`
- `hrv`
- `restingHeartRate`
- `source`

Potential workout-level records can be added separately later.

### Analytics examples

Future analysis may include:
- activity mix vs recovery
- sleep vs next-day behavior
- high-recovery vs low-recovery day composition
- exercise frequency vs strain
- evening phone/social activity vs next-day recovery
- work patterns vs sleep/recovery
- activity transitions around workouts

Avoid causal language unless supported by the data.

Prefer observational phrasing such as:

`On days after shorter sleep, evening phone time was higher.`

instead of:

`Short sleep causes more phone use.`

### Privacy

Wearable data is sensitive.

Keep storage local where practical.

If a backend is eventually required for OAuth/token exchange, store only the minimum necessary information and do not upload activity history by default.

## 19. Combined analytics vision

The long-term product should enable analysis across:
- actual time usage
- planned calendar time
- physiological state

Examples:

### Planned vs actual
- scheduled exercise vs actual tracked exercise
- calendar meeting time vs actual work/meeting time
- planned learning sessions vs completed sessions

### Behavior patterns
- typical weekday activity structure
- weekend vs weekday differences
- common activity transitions
- time-of-day distributions

### Body-context patterns
- activity mix on high vs low recovery days
- sleep duration vs next-day activity composition
- workout timing vs evening behavior

### Classification assistance

Calendar and historical patterns may both contribute to activity suggestions.

Example:

`18:00–19:00`
+
calendar event `Greek class`
+
historical Thursdays at this time frequently classified as Greek

→ high-confidence `Greek` suggestion

The user remains the final source of truth.

## 20. Revised future development stages

### Stage 0 — Environment setup
Prepare Xcode, simulator, physical iPhone testing, Git.

### Stage 1 — Skeleton
App shell, tabs, SwiftData, empty states.

### Stage 2 — Core capture
Boundary button, open interval, persistence, haptic.

### Stage 3 — Daily timeline
Day view and navigation.

### Stage 4 — Classification
Standard/custom activities.

### Stage 5 — Fast day completion
Batch retrospective classification.

### Stage 6 — Corrections
Edit boundaries, split, delete, undo.

### Stage 7 — Activity library
Manage reusable activities.

### Stage 8 — Basic statistics
Daily/weekly analytics.

### Stage 9 — Calendar read integration
Read authorized calendar events and show them as contextual information alongside the timeline. No automatic timeline changes.

### Stage 10 — Calendar reminders and start-from-notification flow
Allow the user to opt in to reminders for upcoming events and start an activity period from an accepted reminder.

### Stage 11 — Calendar-assisted reconstruction
Suggest splits/classifications from overlapping calendar events.

### Stage 12 — Learned activity suggestions
Use local historical patterns and calendar context to rank likely activities.

### Stage 13 — Suggestion quality analytics
Track Top-1, Top-3 and interaction cost locally.

### Stage 14 — WHOOP integration
Connect/import wearable data without changing the core tracking model.

### Stage 15 — Combined behavioral analytics
Analyze planned vs actual time and activity vs physiological context.

Do not skip directly to later integrations before the core capture/classification workflow has proven usable in real life.
