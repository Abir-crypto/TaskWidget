# Tempo — Change Spec 1.1 (pre-launch)

> **Working title.** "Tempo" is still a placeholder (T-52).

| | |
|---|---|
| Version | 1.1 |
| Date | 2026-10-12 |
| Status | Approved by the owner on 2026-10-12, with the review fixes in §8. Being built. |
| Base | `docs/SPEC.md` 1.0 (2026-10-06), `docs/DECISIONS.md` up to D-102 |
| v1 platforms | iPhone and iPad |

---

## 0. How this file works

- **This is a work order.** It takes SPEC 1.0 to SPEC 1.1. `docs/SPEC.md` stays the source of truth. Each change here is copied into SPEC before it's built, following the process in `CLAUDE.md`.
- **Changes** (`C-01`, `C-02`, …) in §2 say why, which decision records it, what to edit in SPEC, and the new behavior with its edge cases. **Data model changes** are collected in §3. **Tasks** (`T-35` onward) in §4 are the build steps, in order, with acceptance criteria. **iOS notes** for `docs/platform/ios.md` are in §5.
- **IDs continue from SPEC.** Features from F-29, rules from §5.11, tasks from T-35, decisions from D-103. Nothing is renumbered.
- **Like SPEC, the behavior text is platform-neutral.** iOS details live only in §5.
- **Every new decision has Source: Proposed** until the owner confirms it. The owner confirmed D-104, D-107, D-108 and D-118 on 2026-10-12, so those are recorded as Discussed. To change one, follow the rule in `DECISIONS.md`: add a superseding entry, never edit or delete.
- **Details the review added** (§8) are recorded as Agent decisions, with the next free `D-` numbers, when their task is built.

**Once, before T-35:** add Phase H (T-35–T-53) to SPEC §8 and to `docs/PROGRESS.md`, with a CHANGELOG entry, so the workflow in `CLAUDE.md` picks the tasks up in order.

**For each task, in this order** (the same order as "Changing the app: spec first" in `CLAUDE.md`):
1. Add its decision to `DECISIONS.md`. Mark the entries it supersedes ("Superseded by D-1xx", or "Partly superseded by D-1xx" where §2 says so).
2. Edit `docs/SPEC.md` as the change describes, and add the iOS notes from §5 to `docs/platform/ios.md` under the task's ID.
3. Add a dated entry to `docs/CHANGELOG.md` for those edits.
4. Build it until every acceptance item passes.
5. Update `docs/DOCUMENTATION.md` and `docs/PROGRESS.md`.

When every task is done, SPEC's version becomes 1.1 and this file moves to `docs/changes/`.

---

## 1. Summary

| ID | Change | Kind | SPEC sections | Decision | Task |
|---|---|---|---|---|---|
| C-01 | Spec catches up with the build | Docs | F-06, F-20, F-21, F-22 | D-103 | T-35 |
| C-02 | Minimum system version iOS 18 | Platform | ios.md only | D-104 | T-36 |
| C-03 | Notes on tasks | Behavior | F-01, F-04, F-10, F-11, F-13, F-15, §4.1, §7 | D-105 | T-38 |
| C-04 | "Afternoon" on screen | Behavior | F-02 and all user-facing text | D-106 | T-39 |
| C-05 | Missed style: Gentle or Strict | New feature | F-30, F-07, F-08, F-09, F-10, F-13, F-14, F-16, F-19, F-21, F-24, F-27, §4.5, §7 | D-107 | T-40 |
| C-06 | Correction window for yesterday | Behavior | §1.2, F-04, F-05, F-06, F-08, F-10, F-12, F-13, §5.4, §5.11, §7, T-05, T-06 | D-108 | T-41 |
| C-07 | Part summaries per part, Morning only by default | Behavior | F-07, F-16, §4.5, §5.9 | D-109 | T-42 |
| C-08 | Snooze reminders | Behavior | F-07, §2.2, §4.6, §5.9 | D-110 | T-43 |
| C-09 | Same timer controls everywhere | Behavior | F-06, F-17, F-18, F-21 | D-111 | T-44 |
| C-10 | Timer Live Activity | New feature | F-31, §2 | D-112 | T-45 |
| C-11 | Timer control in Control Center | New feature | F-32, §2 | D-113 | T-46 |
| C-12 | Shortcuts actions | New feature | F-33, §2 | D-114 | T-47 |
| C-13 | Export and import | New feature | F-29, F-16, F-26 | D-115 | T-48 |
| C-14 | Start again opens the editor | Behavior | F-03, F-12 | D-116 | T-49 |
| C-15 | Shorter guide and an "Add a widget" card | Behavior | F-10, F-16, F-23, §4.6 | D-117 | T-50 |
| C-16 | Tempo Pro | New feature | F-34, F-13, F-14, F-16, F-17, F-27, §4.6 | D-118 | T-51 |
| — | Data model and migration | Data | §4 | — | T-37 |
| — | Device verification | Test | — | — | T-53 |
| — | Final name | Blocked | Header, ios.md §2 | — | T-52 |

**SPEC §2 Scope.** Add to §2.1: notes, a missed style, a correction window for yesterday, snoozing, a timer Live Activity, a timer control, Shortcuts actions, export and import, and Tempo Pro. In §2.2, remove "Live Activities", "Control Center controls", "Siri or Shortcuts actions", "Snoozing notifications" and "Notes". Keep "Apple Watch, Mac", subtasks, tags, lists, priorities, attachments, sharing, and the rest.

**SPEC §1.3 Glossary.** Add:

| Term | Meaning |
|---|---|
| Missed style | How missed tasks are shown: Gentle or Strict (F-30). It never changes statuses or stats. |
| Correction window | From midnight until today's Afternoon start, during which yesterday can still be corrected (§5.11). |
| Tempo Pro | A one-time purchase that unlocks theme colors and longer stats ranges (F-34). |

In the existing "Part of the day" row, change the display names to Morning, Afternoon, Evening or Night (C-04).

---

## 2. Changes

### C-01 · Spec catches up with the build

**Why.** Four agent decisions changed behavior without updating SPEC. CLAUDE.md says SPEC changes first.

**Decision D-103.** SPEC is updated to match D-084, D-090, D-091 and D-092. From now on, an Agent decision that changes or adds behavior described in SPEC updates SPEC and CHANGELOG in the same change. DECISIONS says why; SPEC says what.

**SPEC edits**
- **F-06, task picker.** Replace "It lists the duration habits that exist today, meaning today falls between their start and last day." with:
  - It lists the duration habits that are live on the timer's day: today, or the previous day if the timer ran past midnight.
  - It can't be dismissed by swiping. Time is thrown away only with **Discard**.
  - **Add a duration task** keeps the finished time, and the picker reopens when the editor closes.
  - For **Change task**, it leaves out the entry's current habit and offers **Cancel** instead of Discard.
- **F-20.** Replace the last paragraph with: "When nothing is left, it shows 'You're free today', plus 'All N tasks done' only if every one of today's tasks is done. 'Then:' shows only the next item's title. Tapping opens the app at that task, or on Today."
- **F-21.** In List mode › Tasks, add: "At most 8 rows appear below the header."
- **F-22.** Make these edits:
  - Duration row: rectangular "Evening · 10 of 30 min" or "12:30 · 10 of 30 min" / "Read"; inline follows its timing, "Evening: Read" or "Next: Read at 12:30".
  - Nothing-left row: "All N tasks done" appears only when every one of today's tasks is done.
  - Add: "With Hide task names on, the inline widget hides its whole line while the device is locked."
  - Add: "The widget gallery calls them Next task."

**CLAUDE.md edit.** Add the rule from D-103 to the process section.

---

### C-02 · Minimum system version iOS 18

**Why.** The app is never run on iOS 17, and iOS 18 also allows the timer control (C-11).

**Decision D-104. Supersedes D-052.** The deployment target is iOS 18.0. APIs introduced after iOS 18 (iOS 26 and later) are banned unless they're behind an availability check with a fallback. Tests still run on the latest installed simulator. A full-day check on physical devices is part of the final verification (T-53).

**SPEC edits.** None. SPEC never names a platform version. The change lives in `CLAUDE.md` and `docs/platform/ios.md` (§5).

---

### C-03 · Notes on tasks

**Why.** A to-do app without a notes field draws predictable complaints.

**Decision D-105.** Every task can have optional notes, up to 1,000 characters. Notes aren't part of a habit's schedule history: like the title, an edit applies everywhere. Notes never appear in widgets, on the Lock Screen or in notifications.

**Review detail (Agent).** Notes can be edited wherever the title can: an ended habit's notes can change (D-071 lets its title change), and a past one-time task's notes are read-only, like the rest of it. "Trimming" removes spaces and line breaks at both ends.

**SPEC edits**
- **F-01.** Add: "Every task can have notes (0–1,000 characters after trimming spaces; empty means none)."
- **F-15, Fields.** Add "**Notes**: optional, several lines" after Title.
- **F-13, Header.** Add: "the notes, when there are any."
- **F-10 and F-11, Rows.** Add: "A small notes icon shows when a task has notes."
- **F-04.** In Move to tomorrow, change "a copy with the same title and timing" to "a copy with the same title, notes and timing".
- **§4.1.** Add the column `notes` (§3).
- **§7.** Add "Notes: 0–1,000 characters".

---

### C-04 · "Afternoon" on screen

**Why.** Noon is a moment, not a five-hour block.

**Decision D-106.** Everywhere the user can see it, the part that starts at `noon_start` is called **Afternoon**. Stored values stay as they are: `noon` in §4.2, `noon_start` in §4.5, and notification ids such as `part-start.<day>.noon`. §0 of SPEC says enum values never change once shipped.

**SPEC edits**
- **F-02.** "Parts of the day: Morning, Afternoon, Evening, Night." Defaults read "Morning 06:00, Afternoon 12:00, Evening 17:00, Night 21:00". Remove the line "'Before night' in everyday speech means Evening."
- **Every user-facing example in SPEC** that says Noon changes to Afternoon. Examples: "Afternoon · 3 tasks", "AFTERNOON · until 17:00", "Afternoon · until 17:00" / "Call the bank", "Tue 29 Sep · Afternoon".
- **Empty parts (D-074).** Today: "Nothing this afternoon". Other days: "Nothing in the afternoon".
- **Rule pseudocode, identifiers and data stay as they are.**

---

### C-05 · Missed style: Gentle or Strict (new F-30)

**Why.** Red labels, red dots, a badge, a popup and the recap all point at failure. That suits the owner more than it suits strangers.

**Decision D-107. Supersedes D-021.** A new setting, **Missed tasks: Gentle or Strict**, defaults to Gentle. It changes only how missed tasks are shown, never their status, the Missed queries or the stats. "Honest records" (§1.2) still holds. Strict is exactly the 1.0 behavior. In Strict, the missed popup works as D-021 describes: it appears on Today with "Review missed tasks", shows each task once, and is skipped when the app opens from a widget or a notification. In Gentle there's no popup.

**New feature F-30 · Missed style**

| Where | Strict (1.0 behavior) | Gentle (default) |
|---|---|---|
| Status on rows | "Missed", red | "Not done", secondary grey |
| Ended-part line on Today | "Morning · 2 done · 1 missed" | "Morning · 2 done · 1 not done" |
| Day widget mark | ✗ | – |
| Habit detail week dots and calendar | Missed mark, red | – mark, grey |
| Day strip | Red dot on days with Missed or Short | The usual dot, no extra marker |
| Tab title | Missed | Not done |
| Tab badge | Today's Missed and Short count | None |
| Missed popup (F-08) | Shown | Never shown |
| Earlier count | "14 missed" | "14 not done" |
| Now widget footer | "2 missed today ›" | "2 not done today ›" |
| End-of-day recap title | "Today: 2 missed, 1 still open" | "Today: 1 still open, 2 not done" |
| Stats, Parts of the day | "Most missed: Evening" | "Most often not done: Evening" |
| Habit detail list | "Recent missed days" | "Recent days not done" |
| Empty state, Missed › Today | "You haven't missed a task today" | "Nothing left undone today" |
| Empty state, Missed › Earlier | "Nothing missed before today" | "Nothing undone before today" |
| Empty state, filters | "No missed tasks match these filters" | "No tasks match these filters" |

- **Short** looks the same in both styles: orange ◐ with "20 of 30 min".
- The style applies at once, in the app, the widgets and the notifications planned from then on.
- The popup never runs in Gentle, so nothing is added to its seen list (§4.6) there. **Review detail (Agent):** switching from Gentle to Strict adds today's tasks that are missed at that moment to the seen list, so the popup only shows tasks missed after the switch.
- **Review detail (Agent):** in Gentle, the Now widget footer and the Missed tab rows use secondary grey instead of red, and VoiceOver says "not done" wherever it said "missed" (for example the day strip's "Has tasks not done"). The Stats charts color a rate, not a status, so they're the same in both styles.
- The status colors in F-27 ("done green, missed red, short orange") become: done green, missed red in Strict or grey in Gentle, short orange.

**SPEC edits**
- **F-30.** Add as above.
- **F-16.** Add a **Missed tasks** row with Gentle and Strict, placed under Parts of the day. Footer text: "Gentle shows tasks you didn't get to as Not done, without a badge or a popup. Strict marks them Missed in red."
- **F-07, F-08, F-09, F-10, F-13, F-14, F-19, F-21, F-24.** Where they quote one of the strings in the table, add "(Strict; Gentle in F-30)". F-09's tab list says "**Missed** (called Not done in the Gentle style, F-30), with a badge in the Strict style".
- **F-08, Missed popup.** Add as the first line: "Only in the Strict style (F-30)."
- **§4.5.** Add `missed_style` (§3).
- **§7.** Add "Missed style: Gentle (or Strict)".

**Edge cases**
- A stored style the app can't read is treated as Gentle.
- Switching from Gentle to Strict in the middle of the day doesn't show the popup for tasks already missed at the switch. Tasks missed later show at the next normal open.

---

### C-06 · Correction window for yesterday (new §5.11)

**Why.** If someone forgets to tick something at 23:50, it's recorded as a permanent miss, and nothing done after midnight can count for the day before. The strict cutoff punishes forgetting to log, not failing to act.

**Decision D-108. Supersedes D-011. Partly supersedes D-079 (its Mark not done rule), D-077 (no swipe actions on past days) and D-020 (Earlier holds every day before today).** A task is still missed when its part of the day ends. Today can be changed until midnight. Yesterday can still be corrected until today's Afternoon start: complete, undo, log time, and delete time entries. Days before yesterday, and yesterday after the window, are final. In History, Mark not done follows §5.11 instead of D-079's "completed today" rule. The window applies in both missed styles.

**New rule §5.11 · Editable days**

```
editable(d, now):
  today = dayKey(now)
  if d > today: return FUTURE           // F-04's Future days row
  if d == today: return TODAY           // F-04's Today row
  if d == today - 1 and minuteOfDay(now) < noon_start:
      return CORRECTION                 // complete, undo, log time, delete time entries
  return NONE
```

- `today - 1` uses calendar arithmetic (§5.1).
- The window ends at today's `noon_start`, read when the check runs. Changing the start time moves the end of the window at once.
- CORRECTION doesn't allow moving, editing, deleting, or ending a habit. The timer exception in F-06 is unchanged.

**SPEC edits**
- **§1.2, principle 3.** "A task not done within its part of the day is missed. Today can be corrected until midnight, and yesterday until the afternoon starts. Earlier days are final."
- **F-04, "What can change, and when".** Insert a row between Today and Past days:

| Day | Allowed |
|---|---|
| Yesterday, before today's Afternoon starts | Complete and undo (one-time and progress), Log time, and deleting time entries. Nothing else. |

  Rename the Past days row to "Earlier days, and yesterday after the window".
- **F-05.** "Log time works for today, and for yesterday during the correction window (§5.11). Today's entries, and yesterday's during the window, can be deleted in Habit detail."
- **F-08, Missed tab.** The first section holds today's Missed and Short occurrences and, during the window, yesterday's under a "Yesterday" subheading. Its label stays "You can still change these". Yesterday's rows offer **Mark done** and **Log time**, never Move. During the window, Earlier leaves out yesterday. The tab badge (Strict) still counts today only.
- **F-10, Other days.** When yesterday is selected during the window, a line under the header reads "You can still change yesterday until 12:00", using Afternoon's start. Rows accept complete, undo and Log time. Swipe actions show only those.
- **F-10, Log time sheet.** Opened from one of yesterday's rows, it saves to yesterday, and its title says "Yesterday".
- **F-12.** "Mark not done is offered when the task's date is editable (§5.11): today, a future date, or yesterday during the window."
- **F-13.** "Today's time entries" becomes "Today's time entries, and yesterday's during the window".
- **F-06, "Which day the time counts for".** Replace "This is the only way to add anything to a past day." with "Apart from the correction window (§5.11), this is the only way to add anything to a past day."
- **§5.4.** Replace "Whether an occurrence can be changed follows the table in F-04." with "Whether an occurrence can be changed follows the table in F-04 and §5.11."
- **T-05 acceptance.** "Editing: today allows everything; past days allow nothing" becomes "Editing: today allows everything; yesterday during the window allows only what §5.11 allows; earlier days allow nothing".
- **T-06 acceptance.** "Entries can't be added to future days, or to past days" becomes "Entries can't be added to future days, or to past days other than yesterday during the window".
- **§7.** Add "Correction window: until today's Afternoon start".

**Edge cases**

| Case | Behavior |
|---|---|
| At 00:00 Tuesday | Monday enters the window. Sunday becomes final. |
| At Afternoon's start | Yesterday becomes final. Open screens update at that moment, as they do at part boundaries. |
| A habit whose last day was yesterday | Yesterday is still correctable during the window. |
| Correcting yesterday changes a streak or a weekly total | Stats are computed, so they update at once (§5.7). |
| A yesterday row is open in Missed when the window closes | It moves to Earlier and becomes read-only. |

---

### C-07 · Part summaries per part, Morning only by default

**Why.** With every reminder on, an active day can bring up to ten notifications. That's how people end up turning all of them off.

**Decision D-109. Supersedes D-016.** The notification kinds stay the same: a summary when a part starts, an ending-soon reminder, a reminder 10 minutes before fixed-time tasks, and an end-of-day recap. The part-start summary now has a switch for each part. Only the Morning summary is on by default. Every other reminder is on by default. D-019 still applies: open Anytime tasks are listed in the Morning summary.

**SPEC edits**
- **F-16, Reminders.** Replace "Part starts: on or off." with "When a part starts: Morning, Afternoon, Evening and Night, each on or off (Morning on, the others off)."
- **F-16.** Replace "Every reminder is on by default." with "Every reminder is on by default, except the Afternoon, Evening and Night summaries."
- **F-07.** Under the table, add "Each part's summary has its own switch (F-16)."
- **§5.9.** Change the `part-start` row's condition to "The part's switch is on, and the part has candidates. For Morning, Anytime candidates count too."
- **§4.5.** Replace `notify_part_start` with four columns (§3).
- **§7.** Add "Part-start summaries: Morning on, others off".

---

### C-08 · Snooze reminders

**Why.** A reminder that arrives at the wrong moment is simply lost.

**Decision D-110.** Fixed-time and ending-soon notifications offer **Snooze 15 min** and **Snooze 1 hour**. An option is offered only if it lands at least 5 minutes before the part ends, judged from the reminder's planned fire time. Part summaries, the recap and the timer alert can't be snoozed.

**Behavior**
- A snoozed reminder fires at the moment the user tapped Snooze plus the chosen time. **Review detail (Agent):** the options are chosen when the reminder is planned, so a late tap can reach past the limit. A snooze never fires later than 5 minutes before its part ends; if that moment has already passed when Snooze is tapped, nothing is scheduled.
- Its text is built from current data when it's planned:
  - Fixed time: the title as before. The body reads "In N min" before the task's time, or "Started N min ago" after it.
  - Ending soon: "Evening ends in N min" with the current list.
- It fires only if its condition still holds when the plan is rebuilt. For a fixed-time task: the task isn't done. For ending soon: the part still has candidates.
- Snoozing a snoozed reminder replaces it. There's at most one snooze per original reminder.
- Snoozes are device-only state (§4.6). They're cleared when they fire, when their condition stops holding, and when the day changes.
- Tapping Snooze never opens the app.

**SPEC edits**
- **F-07.** Add the behavior above under the table.
- **§2.2.** Remove "Snoozing notifications."
- **§4.6.** Add "Snoozes" (§3).
- **§5.9.** Add a row:

| Id | Fires at | Included when (judged on current data) |
|---|---|---|
| `snooze.fixed.<task_id>.<day>` / `snooze.ending-soon.<day>.<part>` | The snoozed time | The original reminder's condition still holds |

  Add: "Fixed-time and ending-soon items carry the snooze options that land at least 5 minutes before their part ends."
- **§7.** Add "Snooze: 15 min or 1 hour".

**Edge cases**

| Case | Behavior |
|---|---|
| Ending soon for Evening fires at 20:30, and Night starts at 21:00 | Only Snooze 15 min is offered: 20:45 is at least 5 min before 21:00, while 21:30 isn't. |
| The task is completed before the snoozed reminder fires | The next rebuild drops the snooze. |
| A snooze arrives at the platform's notification limit | Snoozes are planned like every other item, so the earliest are kept (§5.9). |
| Evening's ending soon fires at 20:30 and Snooze 15 min is tapped at 20:50 | It fires at 20:55, 5 minutes before Night starts. Tapped at 20:56, nothing is scheduled. |

---

### C-09 · Same timer controls everywhere

**Why.** A widget showing a running clock with no Pause button looks broken.

**Decision D-111. Supersedes D-022.** There's still one timer at a time, shared by the app and the widgets. Every place that shows the timer offers Pause and Resume. Done differs by kind: a habit timer's Done saves without opening the app, and a generic timer's Done opens the task picker (D-024 still applies). Discard stays in the Now widget's timer mode, the app's timer screen and the task picker, because it can't be undone. The last action wins, and every surface refreshes after any change (F-17).

**SPEC edits**
- **F-06, "Who controls the timer".** Replace the table:

| Place | Generic timer | Habit timer |
|---|---|---|
| Timer widget (small) | Pause/Resume, Done (opens the task picker) | Pause/Resume, Done (saves without opening the app) |
| Now widget (large) | The line "Timer · 05:12" with Pause/Resume and Done (opens the task picker) | Timer mode with Pause/Resume, Done and Discard |
| Live Activity (F-31) | Pause/Resume, Done (opens the task picker) | Pause/Resume, Done (saves without opening the app) |
| Timer control (F-32) | Pause/Resume | Pause/Resume |
| App (timer bar and timer screen) | Full control | Full control |

  Change the sentence above the table to: "Every place that shows the timer can pause and resume it. Done and Discard are offered where the table says."
- **F-06, Done.** Add: "Habit timer, Done in the Timer widget or the Live Activity: as in the Now widget, the time is saved without opening the app. Under 1 minute, nothing is saved and the widget returns to Idle without a message."
- **F-17.** Replace "A widget never shows controls for a timer it doesn't control (F-06)." with "Every widget that shows the timer offers Pause/Resume. Done and Discard follow F-06."
- **F-18.** Replace the table:

| State | Shows | Buttons |
|---|---|---|
| Idle | "Timer" and a Start button | Start begins a generic timer |
| Generic timer, running | The clock counting up | Pause, Done |
| Generic timer, paused | The time so far and "Paused" | Resume, Done |
| Habit timer, running | The habit name and the clock | Pause, Done |
| Habit timer, paused | The habit name, the time so far and "Paused" | Resume, Done |

  Change "Done opens the app (F-06)." to "Done follows F-06: a generic timer opens the task picker, and a habit timer saves without opening the app."
- **F-21, List mode.** Replace the generic-timer line with: "While a generic timer exists, a line appears at the top, 'Timer · 05:12', with Pause/Resume and Done. Done opens the task picker. The ▶ buttons are hidden."

---

### C-10 · Timer Live Activity (new F-31)

**Why.** People now expect a running timer on the Lock Screen and in the Dynamic Island. This also closes the gap when no Timer widget is on the Home Screen.

**Decision D-112.** A timer shows as a Live Activity while it exists, wherever it was started. It offers Pause/Resume and Done (F-06), but not Discard. It follows Hide task names (D-030).

**New feature F-31 · Timer Live Activity**
- It starts when a timer starts, from anywhere: the app, a widget, the control (F-32) or a Shortcut (F-33). It ends when the timer is finished or discarded.
- **Lock Screen:** the habit name (or "Timer"), the clock counting up (or the time so far with "Paused"), and, for a habit timer, a progress bar with "22 of 30 min today". It has Pause/Resume and Done.
- **Dynamic Island:** compact shows the app's icon and the clock; minimal shows the icon. Expanded shows the name, the clock, the progress and the buttons.
- **Tapping** outside the buttons opens the app's timer screen.
- **Hide task names:** while the device is locked, the habit name is hidden, the same way as the Lock Screen widgets' titles (F-22). **Review detail (Agent):** this replaces "the habit name shows as 'Timer'", which the platform's privacy redaction can't promise.
- **Colors:** buttons and progress use the theme color (F-27, subject to F-34).
- If the user has turned Live Activities off, or the device doesn't show them (iPad), nothing else changes.
- If the system ends the activity, for example at its time limit, the timer keeps running. The activity comes back at the next timer action (pause or resume).

**SPEC edits.** Add F-31. In §2, move Live Activities from 2.2 to 2.1.

---

### C-11 · Timer control in Control Center (new F-32)

**Why.** It's cheap once the timer actions exist. It also works from the Lock Screen and the Action button.

**Decision D-113.** One control, **Tempo timer**. With no timer, it starts a generic timer. With a timer, it pauses or resumes it. It never finishes a timer, because a generic timer needs the picker. It doesn't open the app.

**New feature F-32 · Timer control**

| Timer state | Label | Tapping |
|---|---|---|
| Idle | "Start timer" | Starts a generic timer |
| Running | "Running" | Pauses |
| Paused | "Paused" | Resumes |

- It can be placed wherever the platform offers controls: Control Center, the Lock Screen, and the Action button on iPhone.
- After a tap, every widget and the Live Activity refresh (F-17).

**SPEC edits.** Add F-32. In §2, move Control Center controls from 2.2 to 2.1.

---

### C-12 · Shortcuts actions (new F-33)

**Why.** The widget actions already exist, and exposing them makes the app work with Siri and automations.

**Decision D-114.** Five actions: Add task, Complete task, Start timer, Pause or resume timer, and Log time. They follow the same rules as the app (F-04, F-05, F-06, F-15). Creating habits stays in the app.

**New feature F-33 · Shortcuts actions**

| Action | Parameters | Result | Refused when |
|---|---|---|---|
| Add task | Title (required); date (today by default); timing: Anytime (default), a part, or a fixed time | Creates a one-time task | The title is empty or over 100 characters; the date is in the past; the timing is already over today: "That part of the day is already over." |
| Complete task | One of today's one-time tasks or progress habits that isn't done (Upcoming, Open, Missed) | Marks it done | Nothing is left: "Nothing left to complete today." |
| Start timer | A duration habit live today (optional) | Starts a habit timer, or a generic timer without one | A timer exists, running or paused: "There's already a timer. Finish it first." |
| Pause or resume timer | — | Pauses or resumes | No timer exists: "No timer is running." |
| Log time | A duration habit live today; minutes, 1–480 | Adds a manual entry for today | Minutes out of range |

- Each action changes data the same way the app does. Widgets, the Live Activity and notifications are refreshed or rebuilt (F-07, F-17).
- Suggested phrases: "Add a task in Tempo", "Start a Tempo timer", "Log time in Tempo".
- Unlike the Log time sheet's 5-minute steps, Shortcuts accept any whole number of minutes from 1 to 480, for automations.
- **Review detail (Agent):** Add task's fixed time is rounded down to a 5-minute step (F-02) before it's checked.

**SPEC edits.** Add F-33. In §2, move Siri or Shortcuts actions from 2.2 to 2.1. In §7, add "Shortcuts Log time: 1–480 min".

---

### C-13 · Export and import (new F-29)

**Why.** Years of habit history currently depend on a full device backup. Until sync exists, export and import is also the way to move to a new device.

**Decision D-115.** **Settings › Data** offers Export, which writes one platform-neutral JSON file, and Import, which replaces all data after confirmation. Device-only state (§4.6) is never exported. Sync is still not in v1 (D-040 and D-041 unchanged).

**New feature F-29 · Export and import**
- **Export:** a file named "Tempo Backup 2026-10-12.json", saved or shared wherever the platform allows.
- **Format:**

```json
{
  "format": "tempo-backup",
  "version": 1,
  "exported_at": "2026-10-12T09:30:00Z",
  "app_version": "1.1",
  "tables": {
    "tasks": [], "schedules": [], "completions": [], "time_entries": [], "settings": []
  }
}
```

  - Rows use the §4 column names. Day keys and minutes are integers, timestamps are ISO 8601 UTC, and enum values are the §4 strings.
  - Soft-deleted rows aren't exported, so "Delete with history" stays deleted.
- **Import:**
  1. Choose a file.
  2. The file is checked: the format and version, required columns, enum values, every `task_id` pointing to a task, unique ids, day keys and minutes within range, titles and notes within their limits, and the settings row's values (part times as F-02 requires, lead times and alert times from their lists, the recap within its range). Unknown columns are ignored, and missing optional columns take their defaults (§3).
  3. A summary appears: "12 tasks, 340 check-offs, 96 time entries, exported 12 Oct 2026."
  4. **Replace all data** asks for confirmation. If a timer exists, the confirmation adds "Your running timer will be discarded."
  5. Import replaces every synced table in one step. It either fully succeeds or changes nothing.
  6. Afterwards, the missed popup's seen list, snoozes and any pending open action are cleared, the timer is discarded, and notifications and widgets are rebuilt.
- **Messages:**
  - A file that isn't a valid backup: "This file isn't a Tempo backup."
  - A newer version: "This backup was made by a newer version of Tempo. Update the app first."
  - Neither changes anything.
- The imported settings row replaces the current one. A tint color that needs Pro is kept, but shown as Blue without Pro (F-34).

**SPEC edits**
- **F-29.** Add as above.
- **F-16.** Add a **Data** section with Export and Import, placed above About.
- **F-26.** Add: "Export and import (F-29) use the same tables and column names, so a future sync or Android version can read the same files."

**Edge cases**

| Case | Behavior |
|---|---|
| Import while today has completions | They're replaced. The summary and the confirmation say all data will be replaced. |
| A backup with a future-dated task | Imported as it is. The editing rules apply from then on. |
| A backup without optional columns, such as `notes` or a newer settings column | Missing columns take their defaults (§3). |

---

### C-14 · Start again opens the editor

**Why.** D-070 left an open question: a habit started again after its part of the day has ended is missed on the spot.

**Decision D-116. Supersedes D-070.** **Start again** opens the editor for a new habit, filled in from the ended habit: type, title, notes, timing, weekdays, target and length. The type is shown read-only, as when editing. **Starts** defaults to today, or to tomorrow when today's timing is already over (D-035, D-069). Save creates the habit, and Cancel creates nothing. The ended habit isn't changed.

**SPEC edits**
- **F-03, Ending a habit.** Replace the Start again bullet with the decision's text.
- **F-12.** "Each shows its result and a **Start again** button, which opens the editor (F-03)."
- **T-14, acceptance.** Replace "Start again creates a new habit starting today, and the old one stays." with "Start again opens the editor filled in from the ended habit, starting today or tomorrow as F-03 says. Saving creates a new habit, and the old one stays."

---

### C-15 · Shorter guide and an "Add a widget" card

**Why.** Widgets are the main way to use the app (§1.2), but the guide only describes them, and many people never add a widget. Seven pages is also long.

**Decision D-117. Partly supersedes D-093 (its page numbers).** The guide has six pages, with a visual widget page. The setup pages can't be skipped (D-037). Today shows an "Add a widget" card until a Tempo widget is installed or the card is dismissed.

**F-23, new page list**
1. **Welcome:** plan your day by parts of the day.
2. **Tasks and reminders:** the three kinds of tasks, part summaries, ending-soon reminders.
3. **Widgets:** the steps to add a widget, shown in pictures (touch and hold the Home Screen, tap Edit, then Add Widget, then choose Tempo), and what each widget does.
4. **Not done, missed and Stats:** follows the current missed style (F-30).
5. **Your parts of the day:** the start-time pickers.
6. **Notifications:** Allow or Not now.

- Pages 1–4 have **Skip**, which jumps to page 5. **How to use** in Settings shows pages 1–4, with Done.
- The rest of D-093 still applies, with its page numbers moved: Next on every page before the last, page 5 saving at once, page 6 closing the guide, and links waiting for the guide.

**F-10, Add a widget card**
- It sits at the top of Today: "Tempo works best from your Home Screen", with **Show me how** (opens guide page 3) and a close button.
- It shows until any Tempo widget is installed (Home Screen or Lock Screen), or until it's closed. Closing it is kept on the device (§4.6).
- It's checked whenever the app becomes active.
- On iPad, the steps are the same.

**SPEC edits.** Replace F-23's list and its first two bullets. Add the card to F-10's layout, above the day strip. Add "Add a widget card closed" to §4.6. Update F-16's "How to use, which opens pages 1–5" to "pages 1–4".

---

### C-16 · Tempo Pro (new F-34)

**Why.** v1 has no business model. With no server, there's no running cost, so a one-time purchase fits better than a subscription.

**Decision D-118.** One non-consumable purchase, **Tempo Pro**, unlocks two things:
- theme colors other than Blue (F-27), both the presets and Custom;
- the Month and Year ranges, in Stats (F-14) and in Habit detail's stats (F-13).

Everything else stays free and is never limited: tasks, habits, every widget, reminders, the timer, Missed, History, the month calendar, streaks, Appearance (F-28), and export and import. The price is set in the store, not in the app. The purchase can be shared with family, where the store allows it.

**New feature F-34 · Tempo Pro**
- **Locked options stay visible** with a small "Pro" tag:
  - In Settings › Theme, every swatch except Blue.
  - In Stats, the Month and Year segments.
  - In Habit detail, the this-month and this-year stats.
  - Tapping one opens the Pro sheet, and the current choice doesn't change.
- **Pro sheet:** what Pro includes, the price, **Unlock Pro**, **Restore purchases** and Close. It never appears on its own: not at first launch, not in the guide, and not as a prompt.
- **Settings:** a **Tempo Pro** row at the top shows "Unlocked", or "Unlock Pro" with Restore purchases.
- **Entitlement:**
  - It's checked with the store at launch and when the app becomes active, then cached on the device (§4.6), so it works offline and the widgets can read it.
  - It's never stored in the synced settings row. On a new device, it's restored from the store.
- **Without Pro**, a stored non-Blue `tint_color` is kept but shown as Blue, in the app and the widgets. If Pro returns, the color comes back. Stats falls back to Week.
- **After a purchase**, the locked options unlock at once and the sheet closes.
- **Store errors**, for example "Purchases aren't available right now." or "Nothing to restore.", show in the sheet and change nothing.

**SPEC edits**
- **F-34.** Add as above.
- **F-27.** Add: "Colors other than Blue need Tempo Pro (F-34)."
- **F-14.** Add: "Month and Year need Tempo Pro (F-34)."
- **F-13.** Add: "This month and this year need Tempo Pro (F-34)."
- **F-16.** Add the Tempo Pro row as the first section.
- **F-17.** Add: "Without Pro, widgets use Blue for their accents."
- **§1.2, principle 4.** "On the device, no account. v1 has no sign-up and no sync. Tempo Pro is restored from the store, not from an account."

---

## 3. Data model changes

These all land in one migration (T-37). Nothing has shipped, so test installs simply take the new defaults. No custom migration step is needed.

**§4.1 `tasks`**

| Column | Type | Notes |
|---|---|---|
| notes | text? | 0–1,000 characters after trimming; empty is stored as no value (C-03) |

**§4.5 `settings`**

| Change | Column | Type | Default |
|---|---|---|---|
| Remove | notify_part_start | bool | — |
| Add | notify_part_start_morning | bool | true |
| Add | notify_part_start_noon | bool | false |
| Add | notify_part_start_evening | bool | false |
| Add | notify_part_start_night | bool | false |
| Add | missed_style | text | "gentle" |

`missed_style` is `gentle` or `strict` (F-30). An unreadable value is treated as `gentle`.

**§4.6 State kept on the device only**

| Item | Contents |
|---|---|
| Snoozes | A list of {original id, kind, fire time, day}. Cleared when the day changes (C-08). |
| Add a widget card closed | bool (C-15) |
| Pro entitlement | Whether Pro is unlocked, and when the store last confirmed it (C-16) |

**F-26.** Add Snoozes, the card flag and the Pro entitlement to the list of data that never syncs.

---

## 4. Build plan

### Phase H · Pre-launch changes

Build the tasks in order, one at a time, as in SPEC §8. Tests use the default part times, a fixed time zone, and dates in October 2026, with Tuesday 6 Oct 2026 as "today", unless a task says otherwise.

#### T-35 · Spec catches up with the build
Implements: C-01 · Depends on: T-34

Acceptance
- [ ] F-06, F-20, F-21 and F-22 in SPEC match D-084, D-090, D-091 and D-092, and DOCUMENTATION.md agrees.
- [ ] CLAUDE.md has the D-103 rule.
- [ ] CHANGELOG records the edits.

#### T-36 · Minimum system version
Implements: C-02 · Depends on: T-35

Acceptance
- [ ] Every target and the `Core` package target iOS 18.0, and the project builds without warnings about it.
- [ ] CLAUDE.md and ios.md state the new API rule (§5).
- [ ] The full test suite passes.

#### T-37 · Data model changes
Implements: §3 of this file · Depends on: T-36

Acceptance
- [ ] An existing store opens with its data intact, and the new columns take the §3 defaults.
- [ ] `notes` is trimmed, empty notes are stored as no value, and notes over 1,000 characters are rejected.
- [ ] An unreadable `missed_style` reads as `gentle`.
- [ ] The new device-only items survive a restart, and Snoozes clear when the day changes.
- [ ] The widget extension reads the new settings columns.

#### T-38 · Notes
Implements: C-03 · Depends on: T-37

Acceptance
- [ ] Notes can be added, changed and cleared in the editor for every task type.
- [ ] Habit detail shows notes. Rows in Today and Tasks show the notes icon only when there are notes.
- [ ] No widget, Lock Screen widget or notification shows notes.
- [ ] Move to tomorrow on a missed task copies its notes.
- [ ] Editing a habit's notes doesn't create a schedule row.

#### T-39 · "Afternoon" on screen
Implements: C-04 · Depends on: T-35

Acceptance
- [ ] No user-facing text says "Noon": app, widgets, Lock Screen widgets, notifications, guide or empty states. This is checked in both string catalogs.
- [ ] Stored values, `noon_start` and notification ids are unchanged, and existing data loads.
- [ ] Empty parts read "Nothing this afternoon" today and "Nothing in the afternoon" on other days.
- [ ] The longer name fits: the Day widget's columns, the Focus widget's top line and both Lock Screen widgets, at the default and largest text sizes they allow.

#### T-40 · Missed style
Implements: C-05 · Depends on: T-37, T-39

Acceptance
- [ ] Settings shows Missed tasks with Gentle and Strict, set to Gentle on a new install.
- [ ] Every row of the F-30 table shows the right text, color and mark in each style, in the app and in the widgets.
- [ ] In Gentle, the tab has no badge and the popup never appears. In Strict, both behave as in 1.0 (T-16, T-17).
- [ ] Statuses, Missed queries and every Stats number are identical in both styles for the same data.
- [ ] Switching style updates the app and widgets at once, and the next notification rebuild uses the new copy.
- [ ] Every status still has an icon or text as well as a color (F-17).

#### T-41 · Correction window
Implements: C-06 · Depends on: T-40

Acceptance
- [ ] `editable` follows §5.11. Examples:
  - Wed 7 Oct at 11:59, Tue 6 Oct is CORRECTION.
  - At 12:00 it's NONE.
  - Mon 5 Oct is NONE all day Wednesday.
  - With Afternoon's start at 13:00, Tuesday stays CORRECTION until 12:59.
- [ ] During the window, yesterday's one-time and progress tasks can be completed and undone, and Log time saves to yesterday from yesterday's rows and from Missed.
- [ ] During the window, yesterday's time entries can be deleted in Habit detail. After it, they can't.
- [ ] During the window, Move, Edit, Delete and End habit aren't offered for yesterday.
- [ ] Missed shows yesterday under "Yesterday" during the window, and Earlier leaves it out. At the end of the window, those rows move to Earlier while the screen is open.
- [ ] Today shows "You can still change yesterday until 12:00" when yesterday is selected during the window.
- [ ] History's Mark not done follows §5.11.
- [ ] Correcting yesterday updates streaks, weekly totals and stats at once.

#### T-42 · Part summaries per part
Implements: C-07 · Depends on: T-37, T-39

Acceptance
- [ ] Settings shows four part-start switches. On a new install, only Morning is on.
- [ ] With the defaults, only the Morning summary is planned, and it still lists open Anytime tasks.
- [ ] Turning on any part's switch plans that part's summaries at once.
- [ ] Ending-soon, fixed-time and recap notifications are unchanged.

#### T-43 · Snooze
Implements: C-08 · Depends on: T-42

Acceptance
- [ ] Fixed-time and ending-soon notifications offer only the snooze options that land at least 5 minutes before their part ends. For example, Evening's ending soon at 20:30 offers only 15 min.
- [ ] Snoozing schedules one reminder at the tap time plus the option, without opening the app. Snoozing again replaces it.
- [ ] A snoozed fixed-time reminder after its time reads "Started N min ago".
- [ ] Completing the task, or the part running out of candidates, cancels the snooze at the next rebuild.
- [ ] Snoozes are cleared at midnight. (That they aren't exported is checked in T-48.)
- [ ] A late tap fires no later than 5 minutes before the part ends, and a tap after that schedules nothing.
- [ ] With permission refused, nothing is scheduled and nothing crashes.

#### T-44 · Same timer controls everywhere
Implements: C-09 · Depends on: T-35

Acceptance
- [ ] The Timer widget shows every state in the new F-18 table, and its buttons work without opening the app.
- [ ] Done on a habit timer in the Timer widget saves without opening the app. Under 1 minute, it saves nothing and returns to Idle.
- [ ] Done on a generic timer in the Timer widget or the Now widget opens the task picker, with the time frozen at the tap.
- [ ] The Now widget's generic timer line has working Pause/Resume and Done.
- [ ] Pausing in one place shows as paused everywhere: both widgets, the app's timer bar and the timer screen.
- [ ] T-19, T-20, T-23 and T-24 still pass, with their acceptance items updated to the new table.

#### T-45 · Timer Live Activity
Implements: C-10 · Depends on: T-44, T-36

Acceptance
- [ ] Starting a timer from the app, the Timer widget or the Now widget shows the Live Activity. Done or Discard anywhere ends it. (The control and Shortcuts are checked in T-46 and T-47.)
- [ ] Pause/Resume and Done work from the Lock Screen and the Dynamic Island without opening the app. A generic Done opens the task picker.
- [ ] A habit timer shows progress including time logged earlier that day.
- [ ] With Hide task names on, the habit name is hidden on the locked Lock Screen.
- [ ] With Live Activities turned off for the app, timers work as before.
- [ ] A timer started at 23:40 and finished at 00:20 still saves to the day it started, from the Live Activity too.

#### T-46 · Timer control
Implements: C-11 · Depends on: T-44, T-36

Acceptance
- [ ] The control appears in the controls gallery and works in Control Center and on the Lock Screen.
- [ ] Its label follows the timer's state in the F-32 table, including after changes made elsewhere.
- [ ] Tapping starts, pauses or resumes without opening the app. Every widget and the Live Activity refresh, and starting a timer from the control shows the Live Activity.

#### T-47 · Shortcuts actions
Implements: C-12 · Depends on: T-44, T-45

Acceptance
- [ ] All five actions appear in Shortcuts with the parameters in F-33, and the suggested phrases work with Siri.
- [ ] Each refusal in the F-33 table returns its message and changes nothing.
- [ ] Add task follows the editor's validation (F-15, D-035, D-069).
- [ ] Each action refreshes the widgets and the Live Activity and rebuilds notifications. Start timer shows the Live Activity.

#### T-48 · Export and import
Implements: C-13 · Depends on: T-38, T-42

Acceptance
- [ ] Export writes the F-29 format with every non-deleted row of every synced table, and no device-only state (no timer, seen list or snoozes).
- [ ] Importing an export from the same data gives identical tables: same ids, values and timestamps.
- [ ] An invalid file, a file with a broken `task_id`, a file with invalid settings values, and a newer version are each refused with their message, and nothing changes.
- [ ] Import with a running timer warns first, then discards it. After import, the seen list and snoozes are empty, and widgets and notifications match the imported data.
- [ ] A backup without optional columns imports with §3 defaults, and unknown columns are ignored.
- [ ] The format is covered by `Core` tests that don't depend on the platform.

#### T-49 · Start again opens the editor
Implements: C-14 · Depends on: T-38

Acceptance
- [ ] Start again opens the editor filled in from the ended habit, notes included, with the type read-only.
- [ ] At 13:00, for an ended Morning habit, Starts defaults to tomorrow. For an Evening or Anytime habit, it defaults to today.
- [ ] Save creates a new habit, and Cancel creates nothing. The ended habit and its history are unchanged.

#### T-50 · Shorter guide and Add a widget card
Implements: C-15 · Depends on: T-40

Acceptance
- [ ] The guide has the six pages in F-23. Skip on pages 1–4 jumps to page 5, and How to use shows pages 1–4 with Done.
- [ ] Page 3 shows the widget steps in pictures, legible in light mode, in dark mode and at the largest text size.
- [ ] Today shows the card while no Tempo widget is installed. It disappears once one is added, checked when the app becomes active, and stays gone after it's closed.
- [ ] Show me how opens guide page 3.
- [ ] T-28's acceptance items still pass with the new page numbers.

#### T-51 · Tempo Pro
Implements: C-16 · Depends on: T-37

Acceptance
- [ ] Without Pro, the non-Blue swatches and the Month and Year ranges show the Pro tag, and tapping them opens the Pro sheet without changing anything.
- [ ] Purchasing unlocks them at once, in the app and in the widgets' accents from their next update.
- [ ] Restore purchases restores Pro on a fresh install, with the store's test environment.
- [ ] With Pro revoked, a stored custom color shows as Blue and comes back when Pro returns. Stats falls back to Week.
- [ ] With no network, a cached Pro stays unlocked.
- [ ] The sheet never opens on its own, including on first launch and during the guide.

#### T-53 · Device verification
Implements: every task in Phase H · Depends on: T-35–T-51

Acceptance
- [ ] Every acceptance item in T-35–T-51 has been re-run on the final build.
- [ ] A full day on a physical iPhone and a physical iPad:
  - widgets change at each part start;
  - every widget button works;
  - every notification kind fires, including a snooze;
  - the Live Activity (iPhone only) and the control work;
  - a timer runs past midnight.
- [ ] The manual QA checklist in ios.md passes, with the items added in §5.
- [ ] SPEC's version is 1.1, and DOCUMENTATION.md describes every change as built.

#### T-52 · Final name
Implements: the SPEC header note · Depends on: the owner choosing a name · **Blocked**

It's listed last, after T-53, so the blocked task doesn't hold up the others (`CLAUDE.md` runs the first task that isn't done).

Acceptance
- [ ] The find-and-replace in the SPEC header is done across the docs, the strings and the identifiers listed in ios.md §2.
- [ ] Decide whether the bundle identifier keeps `tempo` before the App Store record is created. The display name can change later; the bundle identifier can't.
- [ ] The App Store record and the Pro product (T-51) are created only after this decision. The product ID doesn't contain the name, so it doesn't change.

---

## 5. iOS notes (for `docs/platform/ios.md`)

Add each note under its task ID. Check API names against the current SDK documentation before relying on them.

- **T-36.** Set the deployment target to 18.0 in every target and in `Package.swift` (`.iOS(.v18)`). The rule becomes: no API introduced in iOS 26 or later unless it's behind `if #available` with a fallback. The D-044 approach (no `@Query`, a fresh `ModelContext` per operation) stays.
- **T-37.** Add the new properties with default values, so SwiftData migrates automatically. If the project uses a versioned schema, add a new version with an automatic (lightweight) migration stage. Keep the device-only items in `DeviceState` (D-094).
- **T-39.** Update both string catalogs, the app's and the widget extension's (D-046).
- **T-40.** Expose the missed style through the settings snapshot that widgets already read (D-089), so they don't query the store separately.
- **T-43.** Use notification categories chosen at planning time:
  - one with both snooze actions;
  - one with only 15 minutes;
  - none.

  Snooze actions are background actions, so they don't open the app. Handle them in the notification delegate, write the snooze to `DeviceState`, and rebuild the plan.
- **T-44.** The new widget buttons reuse the existing timer intents with an explicit target state, as D-089 and D-090 do for checkboxes.
- **T-45.** ActivityKit:
  - Add `NSSupportsLiveActivities` to the app's Info.plist.
  - Put the activity attributes in `Shared/`.
  - Add the activity configuration to the widget bundle.
  - Make the timer intents Live Activity intents, so they run in the app's process and can start, update and end the activity.
  - Render the clock with the system's timer text, which counts on its own and freezes while paused, so the activity isn't updated every second.
  - Mark the habit name as privacy-sensitive for Hide task names.
- **T-46.** Add a control widget to the widget bundle that reads the timer state from `DeviceState`. Reload controls on every timer change, alongside the widget reloads.
- **T-47.** Add an App Shortcuts provider for the phrases. Add app entities and queries for today's open tasks and live duration habits, backed by `IntentEnvironment` (D-089). Put the new intents in the shared intents folder.
- **T-48.** Use the system's file export and import. Put Codable transfer types in `Core` with ISO 8601 dates. Import in a single save: delete, insert, save once, and roll back on failure.
- **T-50.** Detect installed widgets with WidgetKit's current-configurations call when the scene becomes active.
- **T-51.** StoreKit 2:
  - Use one non-consumable product, `pro.lifetime`. The ID doesn't contain the app's name or bundle ID, because product IDs can never change and the name isn't final (T-52). Owner's choice, 2026-10-12.
  - Listen for transaction updates from launch.
  - Read current entitlements at launch and on becoming active.
  - Restore with the App Store sync call.
  - Cache the result in `DeviceState` for the widgets.
  - Add a StoreKit configuration file for local tests and UI tests, and a `-ui-testing-pro` launch argument next to the existing ones (D-064).
- **Manual QA additions:** a real purchase and restore in sandbox, the Live Activity on a locked device, the control on the Lock Screen, and snooze actions from a locked device.

---

## 6. Defaults and limits (additions to SPEC §7)

| Item | Value |
|---|---|
| Missed style | Gentle (or Strict) |
| Correction window | Until today's Afternoon start |
| Part-start summaries | Morning on; Afternoon, Evening and Night off |
| Snooze | 15 min or 1 hour, at least 5 min before the part ends |
| Notes | 0–1,000 characters |
| Shortcuts Log time | 1–480 min |
| Backup format | `tempo-backup`, version 1 |
| Theme color without Pro | Blue |

---

## 7. Not in this change, and open questions

**Not in this change.** These are planned for a later update and stay in SPEC §2.2:
- Sync (CloudKit first, keeping the Android path open).
- Monthly and every-N-days repeats, with a "Count in stats" switch for chores.
- A "day ends at" setting.
- "Do today" for yesterday's missed one-time tasks.
- Apple Watch.

**Answered by the owner on 2026-10-12:**
1. **D-104:** iOS 18 as the minimum, as proposed.
2. **D-107:** Gentle is the default, and "Not done" is the word.
3. **D-108:** the window ends at Afternoon's start.
4. **D-118:** theme colors plus Month and Year stats, with a product ID that doesn't contain the name (`pro.lifetime`).

**Still open:**
- **T-52:** the final name, which is needed before the App Store record exists.
- **SPEC §1:** an Audience paragraph (§1.4). This isn't code, but it guides the other answers.

---

## 8. Review fixes (2026-10-12)

A review against SPEC 1.0, `DECISIONS.md`, `ios.md` and the code found these gaps. They're already folded into the sections above. The ones marked **Review detail (Agent)** above are recorded as Agent decisions when their task is built.

- §0: CHANGELOG comes before the code, as `CLAUDE.md` requires, and Phase H is added to SPEC §8 and PROGRESS before T-35.
- §1 and the glossary: the SPEC sections each change touches are complete, and "Noon start" reads "Afternoon start" (C-04).
- C-03: notes are editable wherever the title is.
- C-05: F-09 is in the list; switching to Strict marks today's current misses as seen, because the popup never fills the seen list in Gentle; grey replaces red in the Now widget footer and Missed rows, and VoiceOver says "not done"; Stats charts don't change.
- C-06: `editable` returns `FUTURE` and `TODAY` separately; F-06's "only way to add anything to a past day", §5.4, and the T-05 and T-06 acceptance items are updated; D-077 and D-020 are partly superseded too.
- C-08: a late Snooze tap never fires later than 5 minutes before the part ends.
- C-10: Live Activities don't show on iPad; the hidden name uses the same redaction as the Lock Screen widgets.
- C-12: Complete task offers every task that isn't done today; fixed times are rounded down to 5 minutes; the timer message also fits a paused timer.
- C-13: import also checks ids, titles, notes and the settings row's values, ignores unknown columns, and clears the pending open action. There's no 1.0 backup, so that edge case now covers any missing optional column.
- Build plan: T-43 and T-45 no longer check features built later (export, Shortcuts); T-47 depends on T-45; T-39 checks that "Afternoon" fits; T-52 is listed after T-53; the Pro product ID doesn't contain the name.
