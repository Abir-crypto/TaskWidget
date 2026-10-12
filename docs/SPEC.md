# Tempo — Product Spec

> **Working title.** "Tempo" is a placeholder name. Renaming it is a find-and-replace across the docs and the identifiers listed in `docs/platform/ios.md` §2.

| | |
|---|---|
| Version | 1.0 |
| Date | 2026-10-06 |
| Status | Ready to build |
| v1 platforms | iPhone and iPad |
| Later | Android (this spec is written to be reused unchanged) |

---

## 0. How this spec works

- **This file says what the app does, not how a platform builds it.** It never names a framework or an API. Platform details live in `docs/platform/<platform>.md` (iOS: `docs/platform/ios.md`), organized by the same IDs.
- **Features** (`F-01`, `F-02`, …) in §3 describe behavior. **Rules** in §5 give the exact algorithms that features rely on. **Tasks** (`T-01`, `T-02`, …) in §8 are the build steps, in order, each with acceptance criteria.
- **IDs never change.** Nothing is renumbered. A removed feature or task stays where it is, marked `Removed (date): reason`.
- **This file is the source of truth for intended behavior.** Every change to how the app behaves is made here first (process in `CLAUDE.md`) and recorded in `docs/CHANGELOG.md`.

| File | Purpose |
|---|---|
| `CLAUDE.md` | How the agent works on this repo |
| `docs/SPEC.md` | This file: what the app does, platform-neutral, with the build plan |
| `docs/platform/ios.md` | How each feature and task is built on iOS |
| `docs/DOCUMENTATION.md` | As-built reference: what the app does right now, in full detail |
| `docs/PROGRESS.md` | Status of every task |
| `docs/DECISIONS.md` | Design decisions and the reasons for them |
| `docs/CHANGELOG.md` | Dated history of changes to the spec |

---

## 1. Product

### 1.1 Concept

Tempo is a to-do list organized by the time of day. Every task says *when* in the day it belongs: morning, afternoon, evening, night, a fixed time, or anytime today. One-time tasks are done once. Habits repeat on chosen weekdays and are tracked over weeks, months and years. Widgets are the main way to use the app: a glance shows what's next, and tasks can be checked off and timed without opening it.

### 1.2 Principles

1. **Widget-first.** The most common actions work from widgets.
2. **Organized by time of day.** No lists, tags, projects or priorities.
3. **Honest records.** A task not done within its part of the day is missed. Today can be corrected until midnight, and yesterday until the afternoon starts. Earlier days are final.
4. **On the device, no account.** v1 has no sign-up and no sync.
5. **Platform-neutral data and rules,** so an Android app and future sync can reuse them.

### 1.3 Glossary

| Term | Meaning |
|---|---|
| Task | Anything the user adds. Has a title, a type and a timing. |
| One-time task | A task for one specific date. |
| Habit | A repeating task: a progress habit or a duration habit. |
| Progress habit | A habit checked off on each scheduled day, e.g. take medicine. |
| Duration habit | A habit measured in minutes against a daily target, e.g. read 30 min. |
| Part of the day | Morning, Afternoon, Evening or Night. The user sets their start times. |
| Timing | When in the day a task belongs: a fixed time, a part of the day, or anytime. |
| Occurrence | A task on one specific day. Computed from the task and its schedule, never stored. |
| Schedule | A habit's timing, weekdays and target from a given day onward. Habits keep a history of schedules. |
| Completion | A record that a one-time task or a progress habit was done on a day. |
| Time entry | Seconds logged to a duration habit on a day, by the timer or by hand. |
| Target | A duration habit's daily minutes. |
| Weekly goal | The sum of a duration habit's targets over its scheduled days in a week. |
| Set length | An optional number of calendar days a habit runs for, e.g. 30. |
| Status | Upcoming, Open, Done, Short or Missed (§5.4). Computed, never stored. |
| Day key | A calendar day written as an integer `yyyymmdd`, e.g. `20261006`. |
| Minute of day | Minutes after local midnight, 0–1439. |
| Missed style | How missed tasks are shown: Gentle or Strict (F-30). It never changes statuses or stats. |
| Correction window | From midnight until today's Afternoon start, during which yesterday can still be corrected (§5.11). |

---

## 2. Scope

### 2.1 In v1

- One-time tasks, progress habits and duration habits.
- Notes on tasks (F-01).
- Timing by fixed time, part of the day or anytime, with part-of-day start times set by the user.
- Habit schedules on chosen weekdays, with an optional set length.
- Time tracking with a timer and with manual logging; daily targets and weekly goals.
- Missed tracking: a Missed tab and a missed-tasks popup, shown Gentle or Strict (F-30).
- A correction window for yesterday, until today's Afternoon starts (§5.11).
- Snoozing fixed-time and ending-soon reminders (F-07).
- Notifications: part-of-day summaries, ending-soon reminders, fixed-time reminders, an end-of-day recap, and a running-timer alert.
- Screens: Today, Tasks (with History), Missed, Stats, Habit detail, Task editor, Settings, Timer screen, Task picker.
- Widgets: Timer (small), Day (medium), Focus (medium), Now (large), Lock Screen (rectangular and inline).
- First-launch guide, and an empty state on every screen.
- iPhone and iPad with the same layout.
- A theme color for the app and its widgets (F-27).
- An appearance for the app: the system's light or dark mode, or always one of them (F-28).

### 2.2 Not in v1

- Accounts, sync, server backup, and the Android app. The data model is ready for them (F-26).
- Live Activities, Control Center controls, Siri or Shortcuts actions, Apple Watch, Mac.
- Subtasks, tags, lists, priorities, attachments, sharing.
- Manual reordering of tasks.
- Different part-of-day times on different weekdays.
- The circular Lock Screen widget and the extra-large iPad widget.
- Natural-language input.

---

## 3. Features

### F-01 · Task types

| Type | Example | Repeats | Goal | What's tracked |
|---|---|---|---|---|
| One-time | Renew passport on Thursday | No, one date | Do it | Done or missed |
| Progress habit | Take medicine every day for 30 days | On chosen weekdays | Check it off on each scheduled day | Days done and missed |
| Duration habit | Read 30 min a day | On chosen weekdays | Reach the daily target and the weekly goal | Minutes per day, days on target, weekly totals |

- Every task has a title (1–100 characters after trimming spaces) and a timing (F-02).
- Every task can have notes (0–1,000 characters after trimming spaces and line breaks; empty means none). Notes aren't part of a habit's schedule history: like the title, an edit applies everywhere, and notes can be changed wherever the title can. Notes never appear in widgets, on the Lock Screen or in notifications.
- The type is chosen when the task is created and can't be changed afterward, because changing it would make a habit's history meaningless.
- In stats, one-time tasks only appear as a count of completed tasks.

### F-02 · Timing and parts of the day

**Timing** works the same for every task type:

| Timing | Example | Belongs to | Reminder |
|---|---|---|---|
| Fixed time | Interview at 12:30 | The part of the day that contains the time | Fixed-time reminder, 10 min before by default |
| Part of the day | Gym in the evening | That part | Ending-soon reminder for that part |
| Anytime | Renew passport, sometime today | The Anytime group, which belongs to no part | End-of-day recap only |

**Parts of the day:** Morning, Afternoon, Evening, Night.

The part that starts at `noon_start` is called **Afternoon** everywhere the user can see it. Its stored values stay as they are: `noon` in §4.2, `noon_start` in §4.5, and ids such as `part-start.<day>.noon` (§0: enum values never change once shipped).

- The user sets the start time of each part in the first-launch guide and in Settings. Defaults: Morning 06:00, Afternoon 12:00, Evening 17:00, Night 21:00.
- Each part ends when the next one starts. Night ends at midnight.
- Times before Morning's start, such as a fixed-time task at 05:00, belong to Morning.
- Start times use 15-minute steps, must be in order, and each part must last at least 30 minutes.
- Tasks store their part, not clock times. Changing a start time immediately moves every task in that part, along with its reminders and widget updates. Past days aren't affected, because their statuses are final (§5.4).
- Fixed times use 5-minute steps.

### F-03 · Habit schedules and goals

- **Weekdays:** one or more of Monday–Sunday, all selected by default. Only selected days are scheduled.
- **Start day:** today by default, and never earlier than today. Nothing is scheduled before it.
- **Length:** Ongoing (default), or a set number of calendar days from 1 to 365. The last day is the start day + length − 1. For example, "take medicine for 30 days on Mon, Wed and Fri" runs for 30 calendar days, which is about 13 scheduled days.
- **Target (duration habits only):** daily minutes, 5–480 in 5-minute steps, 30 by default.
- **Weekly goal (duration habits):** the sum of the targets of the habit's scheduled days in that week, counting only days between the start day and the last day. Weeks start on the first weekday of the user's region.

**Ending a habit**
- A habit with a set length ends after its last day. It moves to History › Habits with its result.
- Any habit can be ended by hand with **End habit**. Its last day becomes yesterday, or today if today already has a completion or a time entry. It moves to History.
- **Start again** (in History) creates a new habit with the same title, type, schedule, target and length, starting today. The ended habit keeps its history unchanged. Each habit has its own stats.

**Editing a habit**
- **Title:** the change applies everywhere, including history.
- **Timing, weekdays or target:** the change applies from today onward. Days before today keep the schedule they had (schedule history, §4.2). Several edits on the same day replace that day's earlier change.
- **Length:** moves the last day. If the new last day falls before today, the habit ends, as with End habit.
- **Start day:** can only be changed while it's still in the future.
- **Delete with history** removes the habit and all of its history and stats, after confirmation. **End habit** is always offered next to it, as the way to stop a habit without losing its history.

### F-04 · Daily cycle and status

**Status of an occurrence** (the exact algorithm is in §5.4):

| Status | Meaning |
|---|---|
| Upcoming | Its part of the day hasn't started yet. |
| Open | Its part of the day is in progress. Anytime tasks are Open all day. |
| Done | One-time or progress: completed. Duration: the day's minutes have reached the target. |
| Short | Duration only: its part ended with some minutes logged, but fewer than the target. |
| Missed | Its part ended and it isn't done. For duration habits, this means no minutes were logged. |

- A task becomes Missed or Short when its part of the day ends:
  - Morning tasks at Afternoon's start.
  - Afternoon tasks at Evening's start.
  - Evening tasks at Night's start.
  - Night and Anytime tasks at midnight.
  - Fixed-time tasks when their part ends.
- In the Missed tab, in counts and in stats, Short counts as missed but shows its minutes ("20 of 30 min").

**What can change, and when**

| Day | Allowed |
|---|---|
| Today | Everything, until midnight: complete, undo, log time and move, including tasks already Missed or Short |
| Yesterday, before today's Afternoon starts | Complete and undo (one-time and progress), Log time, and deleting time entries. Nothing else (§5.11). |
| Earlier days, and yesterday after the window | Nothing; they're read-only. The one exception: a timer started on that day still saves to it (F-06). |
| Future days | One-time tasks can be completed early, moved, edited or deleted. Habits can't be completed, and time can't be logged. |

**Move to tomorrow** (one-time tasks only)
- If the task isn't missed, its date changes to the next day.
- If it's Missed today, it stays on today as missed, and a copy with the same title, notes and timing is created for tomorrow.
- On a future day, the action is called **Move to next day** and moves the date forward by one day.

### F-05 · Time tracking

- Only duration habits receive time.
- Time is recorded as **time entries**. Each one has a habit, a day, a number of seconds and a source (timer or manual).
- A habit's minutes for a day are the sum of that day's entries. There's no upper limit; going past the target is normal.
- Time can be logged on any day between the habit's start and last day, whether or not that day is scheduled. Minutes on an unscheduled day count toward weekly totals and time stats, but they don't make that day scheduled.
- **Log time** adds time by hand: choose 5–480 minutes in 5-minute steps. Log time works for today, and for yesterday during the correction window (§5.11).
- Today's entries, and yesterday's during the window, can be deleted in Habit detail. Other entries on past days are read-only.
- Minutes are always shown as whole minutes, rounded down from the total seconds.

### F-06 · Timer

There's one timer at a time per device. Its state stays on the device and is never synced.

**Kinds of timer**
- **Generic timer:** started from the Timer widget, with no habit. The habit is chosen when the timer is finished.
- **Habit timer:** started with ▶ on a duration habit, either in the Now widget or in the app (Today rows, Habit detail). It starts counting immediately.

**States:** Idle, Running, Paused. A timer can be paused and resumed any number of times.

**Who controls the timer.** Only the places marked with controls below can act on it; every other place just displays it.

| Place | Generic timer | Habit timer |
|---|---|---|
| Timer widget (small) | Pause/Resume, Done | Display only: the habit name and the clock, or "Paused". Tapping opens the app's timer screen. |
| Now widget (large) | Display only: the line "Timer running · 05:12". Tapping opens the app. | Timer mode with Pause/Resume, Done and Discard |
| App (timer bar and timer screen) | Full control | Full control |

While a timer exists, whether running or paused, every ▶ button is hidden and the Timer widget shows the timer instead of Start. The current timer has to be finished or discarded before another can start.

**Done**
- The clock stops at the moment Done is tapped. Time spent afterward, for example choosing a habit, isn't counted.
- If the timer ran for less than 1 minute, nothing is saved, and the app says "Less than a minute, nothing saved."
- **Habit timer, Done in the Now widget:** the time is saved without opening the app. The widget returns to its list with the habit's progress updated.
- **Habit timer, Done in the app:** the time is saved and the confirmation appears.
- **Generic timer, Done** (in the Timer widget or the app): the app opens the **task picker**.
  - It lists the duration habits that are live on the timer's day: today, or the previous day if the timer ran past midnight.
  - First come those scheduled today and still below their target, each with progress ("Read · 10 of 30 min"). After them come the rest, including habits already past their target.
  - Choosing a habit saves the time and shows the confirmation.
  - **Discard** throws the time away.
  - It can't be dismissed by swiping. Time is thrown away only with **Discard**.
  - If there are no duration habits, it shows "No duration tasks yet" with **Add a duration task** and **Discard**.
  - **Add a duration task** keeps the finished time, and the picker reopens when the editor closes.
  - For **Change task**, it leaves out the entry's current habit and offers **Cancel** instead of Discard.
- **Confirmation:** "Added 18 min to Read · 28 of 30 min today," with **Undo** (deletes the entry) and **Change task** (opens the picker and moves the entry). It disappears after about 5 seconds.

**Discard** stops the timer and saves nothing. It's available in the Now widget's timer mode, on the app's timer screen and in the task picker.

**Which day the time counts for:** the entry is saved to the day the timer was started, even if Done is tapped after midnight. Apart from the correction window (§5.11), this is the only way to add anything to a past day.

**Running alert:** when a timer has run continuously for the alert time (2 hours by default) since it was last started or resumed, a notification appears (F-07). It has two actions:
- **Stop** pauses the timer and opens the app's timer screen.
- **Keep going** dismisses the alert, which comes back after another alert period.

Pausing, Done or Discard cancels the alert.

**In the app**
- **Timer bar:** shown above the tabs on every screen while a timer exists. It shows the habit name (or "Timer"), the clock counting up, Pause/Resume and Done. Tapping it opens the timer screen.
- **Timer screen:** a large clock, the habit name, Pause/Resume, Done and Discard. For habit timers it also shows progress toward the target, including time logged earlier that day ("22 of 30 min today").

### F-07 · Notifications

| Kind | When | Sent only if | Example title / body | Tapping opens |
|---|---|---|---|---|
| Part starts | At the part's start | The part has at least one task today that isn't done | "Afternoon · 3 tasks" / "Call the bank, Interview at 12:30, Read" | Today, at that part |
| Ending soon | The lead time before the part ends (30 min by default) | Something in the part still isn't done | "Evening ends in 30 min" / "2 left: Gym, Read (10 of 30 min)" | Today, at that part |
| Fixed time | The lead time before the task (10 min by default) | The task isn't done | "Interview at 12:30" / "In 10 min" | Today, at that task |
| End-of-day recap | At the recap time (23:30 by default) | At least one task today isn't done | "Today: 2 missed, 1 still open" (Strict; Gentle in F-30) / "Call the bank, Read (20 of 30 min), Plan tomorrow" | Missed tab |
| Timer running | As described in F-06 | A timer is running | "Read timer is still running" / "It's been running for 2 hours." | Timer screen |

- Each part's summary has its own switch (F-16). Only Morning's is on by default.
- Lists show up to 3 names, then "and N more".
- The Morning summary also lists open Anytime tasks, after Morning's own tasks ("…and 2 anytime"). It's sent even if Morning itself has no tasks, as long as there are Anytime tasks.
- A duration habit counts as not done until it reaches its target.
- Ending soon fires at the part's end minus the lead time, but never before the part starts.
- If the lead time would put a fixed-time reminder in the past, for example a task created at 12:25 for 12:30, no reminder is sent.
- Notification text always reflects the latest data. Any change to tasks, completions or time entries rebuilds the pending notifications, whether it was made in the app, in a widget or from a notification action.
- Each kind can be turned off in Settings, and the lead times and the recap time can be changed (F-16).
- **Snooze:** fixed-time and ending-soon notifications offer **Snooze 15 min** and **Snooze 1 hour**. An option is offered only if it lands at least 5 minutes before the part ends, judged from the reminder's planned fire time. Part summaries, the recap and the timer alert can't be snoozed.
  - A snoozed reminder fires at the moment Snooze was tapped plus the chosen time, but never later than 5 minutes before its part ends; if that moment has already passed when Snooze is tapped, nothing is scheduled.
  - Its text is built from current data when it's planned. Fixed time: the title as before, and the body "In N min" before the task's time, "Starts now" at it, or "Started N min ago" after it. Ending soon: "Evening ends in N min" with the current list.
  - It fires only if its condition still holds when the plan is rebuilt: for a fixed-time task, the task isn't done and fixed-time reminders are on; for ending soon, the part still has tasks that aren't done and ending-soon reminders are on.
  - Snoozing a snoozed reminder replaces it. There's at most one snooze per original reminder.
  - Snoozes are device-only state (§4.6). They're cleared when they fire, when their condition stops holding, and when the day changes.
  - Tapping Snooze never opens the app.
- Permission is requested on the last page of the first-launch guide. If it's refused, nothing is scheduled, and Settings shows that notifications are off, with a link to the system settings.
- Platforms limit how many notifications can be scheduled in advance. At least the next 48 hours must always be scheduled. The schedule is topped up whenever the app opens, after every change, and in the background where the platform allows it.

### F-08 · Missed tasks

**Missed tab**

The tab has two sections:
- **Today**, labelled "You can still change these": today's Missed and Short occurrences and, during the correction window (§5.11), yesterday's under a "Yesterday" subheading. Each of today's rows offers **Mark done** (one-time and progress), **Log time** (duration) and **Move to tomorrow** (one-time). Yesterday's rows offer **Mark done** and **Log time**, never Move. A task leaves the section as soon as it's no longer missed, and when the window closes yesterday's rows move to Earlier.
- **Earlier:** every Missed and Short occurrence before today, read-only and grouped by date. During the window, it leaves out yesterday.

The Earlier section has **Sort** and **Filter**:
- Sort: newest first (the default) or oldest first.
- Date range: All (the default), This week, This month, or a custom range.
- Type: one-time, progress and duration, in any combination.
- Part of the day: Morning, Afternoon, Evening, Night, Anytime. Fixed-time tasks count under their part.
- A specific task.
- While any filter is active, a **Clear filters** button appears. Filters reset when the app restarts.

Other details:
- A count above Earlier reflects the active filters ("14 missed" (Strict; Gentle in F-30)).
- Each row shows the title, a type icon, when it was due ("Tue 29 Sep · Afternoon" or "Tue 29 Sep · 12:30"), and for duration habits the minutes ("20 of 30 min").
- In the Strict style, the tab's badge shows how many tasks are Missed or Short today. The Gentle style has no badge (F-30).
- Deleted tasks disappear from the list. Ended habits stay in it.

**Missed popup**
- Only in the Strict style (F-30).
- It's shown when the app is opened normally, not from a widget or a notification, and today has missed tasks the user hasn't been shown yet.
- It appears over the current screen, normally Today. It says "You missed 2 tasks today," lists them, and offers **Review missed tasks** and **Not now**. Review switches to the Missed tab and highlights those tasks in its Today section.
- Each missed task appears in the popup only once, and either button counts as having seen it. The list of seen tasks is kept on the device and resets each day.
- If the app was opened from a widget or a notification, the popup waits until the next normal open. The badge still shows in the meantime.
- The end-of-day recap still lists all of today's missed tasks, including ones already seen in the popup.

### F-09 · Navigation and app structure

- Four tabs: **Today**, **Tasks**, **Missed** (called Not done in the Gentle style, F-30), with a badge in the Strict style, and **Stats**.
- **Settings** opens from a gear button on Today. **History** opens from a clock button on Tasks.
- A floating **+** button on Today and Tasks opens the task editor (F-15).
- While a timer exists, the timer bar (F-06) sits above the tabs on every screen.
- **Destinations the app can open directly**, used by widgets and notifications:
  - Today, optionally at a given day, part or task.
  - A new task, optionally preset with a day and a type.
  - The Missed tab.
  - The timer screen.
  - The task picker for a finished generic timer.

### F-10 · Today screen

**Layout, top to bottom**
1. **Header:** the day's title ("Today", "Tomorrow", "Yesterday", or a date like "Thu 8 Oct") and the gear button.
2. **Day strip:** the seven days of the week. Swiping moves by a week, and tapping selects a day.
   - Each day shows a dot if it has tasks, and a red dot if it has missed tasks (Strict; Gentle in F-30).
   - A "Today" button returns to today whenever another day is selected.
3. **Sections, in this order:** Morning, Afternoon, Evening, Night, Anytime.
   - On today, parts that have ended collapse into one line, for example "Morning · 2 done · 1 missed" (Strict; Gentle in F-30). Tapping the line expands it.
   - The current part is highlighted and shows "ends in 1h 20m", updated every minute.
   - Later parts and Anytime are expanded.
   - A part with no tasks shows "Nothing this evening" in small grey text. Afternoon's reads "Nothing this afternoon" on today and "Nothing in the afternoon" on other days.
   - Within a part, fixed-time tasks come first in time order, then part-of-day tasks in the order they were created.
4. **The floating + button,** which adds a task to the selected day.

**Rows**
- **One-time and progress:** a checkbox, the title, and the time if it has a fixed time. Missed tasks are marked "Missed" in red (Strict; Gentle in F-30), and done tasks have their title struck through.
- **Duration:** the title, progress ("10 of 30 min") and ▶. The ▶ is hidden while a timer exists. Once the target is reached the row shows Done, and time can still be added.
- A small notes icon shows when a task has notes.
- **Tapping a row:** a one-time task opens the editor, and a habit opens Habit detail.
- **Swipe actions,** offered only where F-04 allows them: Done/Undo, Log time (duration), Move to tomorrow (one-time), Edit and Delete.
- **Delete:** a one-time task is deleted after confirmation. A habit offers End habit or Delete with history (F-03).
- A running timer can't be orphaned: ending or deleting a habit whose timer is running asks first, then discards the timer.

**Other days**
- Past days are read-only, except yesterday during the correction window (§5.11): a line under the header reads "You can still change yesterday until 12:00", using Afternoon's start, and rows accept complete, undo and Log time. Swipe actions show only those.
- Future days show one-time tasks and scheduled habits. One-time tasks there can be completed early or moved.

**Log time sheet:** opened from a duration row, from the Missed tab or from Habit detail. It has a minutes picker (5–480, in 5-minute steps) and saves to today. Opened from one of yesterday's rows during the window, it saves to yesterday, and its title says "Yesterday".

The missed popup (F-08) appears on this screen.

### F-11 · Tasks tab

- A segmented control switches between **Habits** and **One-time**. The last choice is remembered.
- **Habits:** every active habit, meaning one that hasn't ended. Each row shows:
  - the title, a type icon and a schedule summary ("Mon, Wed, Fri · Evening");
  - goal progress: for progress habits "4 of 5 this week", or "Day 12 of 30" with a set length; for duration habits "2h 10m of 3h 30m this week".
  - Tapping a row opens Habit detail.
- **One-time:** every one-time task from today onward that isn't done, grouped by date (Today, Tomorrow, Thu 8 Oct, …), with its timing. Missed ones live in the Missed tab, not here. Tapping a row opens the editor.
- In both lists, a small notes icon shows when a task has notes.
- The floating + opens the editor with the type preset from the segment. Habits presets a progress habit, which can still be changed in the editor; One-time presets a one-time task.
- A clock button opens History.

### F-12 · History

- A segmented control switches between **One-time** and **Habits**.
- **One-time:** completed one-time tasks, grouped by the day they were completed, newest first. Mark not done is offered when the task's date is editable (§5.11): today, a future date, or yesterday during the window. Others are read-only.
- **Habits:** ended habits, whether their set length finished or they were ended by hand. Each shows its result and a **Start again** button (F-03). Tapping a habit opens Habit detail.
  - Progress habits: "Done 27 of 30 days".
  - Duration habits: "On target 18 of 20 days · 14h 20m total".
- A search field filters by title.

### F-13 · Habit detail

- **Header:** the title, type, schedule summary, target (for duration habits), and length ("Day 12 of 30" or "Ongoing"), then the notes, when there are any.
- **This week:** seven dots for the days, each showing done, short, missed, upcoming or not scheduled.
- **Month calendar:** each scheduled day is colored by its result. Arrows move between months.
- **Stats for this week, this month and this year:** the completion rate. For duration habits it adds the total time and, for this week, the time against the weekly goal.
- **Streak:** current and best (§5.7).
- **Today's time entries, and yesterday's during the window** (duration habits): the source and minutes of each, and each can be deleted.
- **Recent missed days** (Strict; Gentle in F-30): up to 10, newest first. "See all" opens the Missed tab filtered to this habit.
- **Buttons:**
  - Edit.
  - Log time (duration habits, when allowed today).
  - ▶ (duration habits; hidden while a timer exists).
  - End habit for an active habit, or Start again for an ended one.

### F-14 · Stats

**Range:** Week, Month or Year, with arrows to move back in time. It can't go past the current period, or back before the first task was created.

**Cards, top to bottom**
1. **Overview:**
   - the habits' completion rate, with the change from the previous range ("82%, up 8 points from last week"), hidden when there's no previous data;
   - habit days done out of those scheduled ("23 of 28");
   - the number of one-time tasks completed;
   - the total time logged.
2. **Completion chart:** for Week, a bar for each day; for Month, a calendar grid colored by day; for Year, a bar for each month. Tapping a day opens it in Today, read-only for past days.
3. **Time:** each duration habit's time logged in the range, against its goal for the range ("Read · 3h 10m of 3h 30m").
4. **Parts of the day:** the completion rate for each part and for Anytime, plus "Most missed: Evening" (Strict; Gentle in F-30).
5. **Streaks:** the current and best streak for each habit, highest current streak first.
6. **Habits:** each habit's rate for the range. Tapping one opens Habit detail.

The formulas are in §5.7, and the empty state is in F-24.

### F-15 · Task editor

The editor opens from the + button, from empty-state Add buttons, from Edit actions, and from widget links. Presets for the day and the type come from where it was opened.

**Fields**
1. **Type:** One-time, Progress or Duration. It can't be changed after the task is created; when editing, it's shown read-only.
2. **Title.**
3. **Notes:** optional, several lines.
4. **When:** Fixed time, Part of the day, or Anytime. Fixed time shows a time picker in 5-minute steps. Part of the day shows Morning, Afternoon, Evening and Night.
5. **One-time only:** the date. It defaults to the day selected in Today, or otherwise today. Past dates aren't allowed.
6. **Habits only:**
   - Repeat on: seven weekday toggles, all on by default.
   - Starts: a date, today by default, never in the past.
   - Length: Ongoing, or a number of days (1–365, 30 by default when switched on).
7. **Duration only:** the daily target (5–480 min in 5-minute steps, 30 by default).

**Rules**
- **Save** is disabled until the task is valid. It needs a non-empty title, at least one weekday for habits, a time for fixed timing, and a part for part timing.
- Messages appear under the field that needs fixing: "Add a title", "Notes can be up to 1,000 characters.", "Pick at least one day".
- When the task is for today, parts that have already ended can't be chosen, and neither can fixed times inside them. They're shown greyed out with "Already over".
- Editing a habit shows a note under its schedule: "Changes apply from today. Earlier days keep their old schedule."
- **Edit mode** adds **Delete** for one-time tasks, or **End habit** and **Delete with history** for habits. Each asks for confirmation.

### F-16 · Settings

- **Parts of the day:** the start times of Morning, Afternoon, Evening and Night (rules in F-02).
- **Missed tasks:** Gentle or Strict (F-30), Gentle by default. Footer: "Gentle shows tasks you didn't get to as Not done, without a badge or a popup. Strict marks them Missed in red."
- **Reminders:**
  - When a part starts: Morning, Afternoon, Evening and Night, each on or off (Morning on, the others off).
  - Ending soon: on or off, with a lead time of 15, 30, 45 or 60 min (30 by default).
  - Fixed-time tasks: on or off, with a lead time of 5, 10, 15 or 30 min (10 by default).
  - End-of-day recap: on or off, with a time in 15-minute steps between Night's start and 23:45 (23:30 by default).
  - Running timer alert: on or off, after 1, 2 or 3 hours (2 by default).
  - The notification permission status, with a link to the system settings when notifications are off.
- **Theme:** the app's appearance (F-28) and its color (F-27).
- **Privacy:** Hide task names on the Lock Screen (off by default).
- **Help:** How to use, which opens pages 1–5 of the guide (F-23).
- **About:** the app version.
- Every reminder is on by default, except the Afternoon, Evening and Night summaries.

### F-17 · Widgets: general rules

- Widgets show **today only**, and switch to the new day at midnight on their own.
- They update exactly at each part's start, one hour before each fixed-time task, at each fixed time, and at midnight, all without the app running.
- Any change anywhere refreshes every widget, whether it was made in the app, through a widget button or from a notification action.
- Widget buttons work without opening the app, unless a feature says otherwise.
- Status is never shown by color alone; an icon or text always goes with it. Widgets adapt to dark mode and to tinted styles.
- Widgets use the theme color (F-27) for their accents. In the tinted and clear Home Screen styles and on the Lock Screen, the system's colors apply instead.
- Widgets follow the system's light or dark mode, whatever the app's appearance (F-28).
- A widget never shows controls for a timer it doesn't control (F-06).
- If a widget can't load its data, it shows "Open Tempo to refresh" and tries again 15 minutes later.

### F-18 · Timer widget (small)

| State | Shows | Buttons |
|---|---|---|
| Idle | "Timer" and a Start button | Start begins a generic timer |
| Generic timer, running | The clock counting up | Pause, Done |
| Generic timer, paused | The time so far and "Paused" | Resume, Done |
| Habit timer, running or paused | The habit name and the clock, or "Paused" | None. Tapping opens the app's timer screen. |

- Done opens the app (F-06).
- Tapping anywhere outside the buttons opens the app: on the timer screen if a timer exists, otherwise on Today.

### F-19 · Day widget (medium)

- Four columns: Morning, Afternoon, Evening and Night. The current part is highlighted.
- Each column shows one mark per task: ✓ done, ○ not done yet, ✗ missed (Strict; Gentle in F-30), and ◐ short or a duration habit with some time logged. It shows at most 6 marks, then "+N".
- Under each column: "done", "N left", or nothing if the part has no tasks.
- A footer shows "Anytime · N left" while Anytime tasks are open.
- Tapping a column opens Today at that part.
- With no tasks today it shows "No tasks today", and tapping opens the editor for today. When everything is done, every mark is ✓ and it shows "You're free today".
- The widget has no buttons.

### F-20 · Focus widget (medium)

The Focus widget is information only, with no buttons. It shows the result of the next-task rule (§5.6):
- **A top line saying when:** "NEXT · 12:30 · in 45 min", "AFTERNOON · until 17:00", "EVENING · from 17:00" or "ANYTIME".
- **The title,** shown large.
- **For duration habits,** progress such as "10 of 30 min".
- **"Then:"** followed by the item after it.

When nothing is left, it shows "You're free today", plus "All N tasks done" only if every one of today's tasks is done. "Then:" shows only the next item's title. Tapping opens the app at that task, or on Today.

### F-21 · Now widget (large)

**List mode**
- **Header:** the current part's name, "ends in 1h 20m", and "N left".
- **Tasks:** the current part's tasks (fixed-time first, in time order). Then the next part's header and tasks, as many as fit. Then Anytime tasks if there's room. At most 8 rows appear below the header.
- If the current part has no tasks, the next part with tasks comes first. When nothing is left in the day, it shows "You're free today".
- **Rows:**
  - One-time and progress tasks have a checkbox; tap it to complete and tap again to undo.
  - Duration habits show their progress and ▶.
- **"+N more"** appears when tasks don't fit; tapping it opens Today.
- **Footer:** "2 missed today ›" (Strict; Gentle in F-30) when today has missed tasks. Tapping it opens the Missed tab.
- While a generic timer exists, a display-only line appears at the top, "Timer running · 05:12", and the ▶ buttons are hidden.

**Timer mode** (while a habit timer exists)
- The whole widget becomes the timer. It shows:
  - the habit name;
  - the clock counting up;
  - a progress bar toward the target, including time logged earlier ("22 of 30 min today");
  - Pause/Resume, Done and Discard.
- Done saves without opening the app and returns to list mode. Discard returns to list mode without saving.
- The widget stays in timer mode until Done or Discard.

### F-22 · Lock Screen widgets

There are two sizes: **rectangular**, under the clock, and **inline**, a single line above the clock. Both are information only. Tapping opens the app at the task shown.

| Situation | Rectangular (line 1 / line 2) | Inline |
|---|---|---|
| A fixed-time task coming up | "12:30 · in 45 min" / "Interview" | "Next: Interview at 12:30" |
| A part-of-day task open now | "Afternoon · until 17:00" / "Call the bank" | "Afternoon: Call the bank" |
| A duration habit | "Evening · 10 of 30 min" or "12:30 · 10 of 30 min" / "Read" (its time, part or "Anytime", then its progress) | Follows its timing like any other task: "Evening: Read" or "Next: Read at 12:30" |
| A task in a later part | "Evening · from 17:00" / "Gym" | "Evening: Gym" |
| An Anytime task | "Anytime" / "Renew passport" | "Anytime: Renew passport" |
| Nothing left | "You're free today" / "All N tasks done", shown only when every one of today's tasks is done | "You're free today" |

- The task shown comes from the next-task rule (§5.6).
- With **Hide task names on the Lock Screen** turned on, titles are hidden while the device is locked and appear once it's unlocked. With Hide task names on, the inline widget hides its whole line while the device is locked.
- The widget gallery calls them Next task.

### F-23 · First-launch guide

The guide is a set of swipeable pages, shown once on first launch:
1. **Welcome:** plan your day by parts of the day.
2. **Three kinds of tasks:** one-time, progress and duration.
3. **Reminders:** part summaries, ending-soon reminders, and missed tasks.
4. **Widgets:** Timer, Day, Focus, Now and the Lock Screen, and what each one does.
5. **Missed and Stats.**
6. **Your parts of the day:** start-time pickers filled with the defaults, following the rules in F-02.
7. **Notifications:** Allow, which asks for the system permission, or Not now.

- Pages 1–5 have **Skip**, which jumps to page 6, so the setup pages are never skipped.
- Finishing page 7 closes the guide for good. Pages 1–5 can be reopened from Settings › How to use.
- Each page has an illustration or icon, a title, and one or two sentences.

### F-24 · Empty states

Every place that can be empty shows a message. Buttons labelled with "Add" open the editor, preset for where they are.

| Where | Message | Button |
|---|---|---|
| Today, with no tasks today | No tasks today | Add a task |
| Today, on a future day | Nothing planned for Thu 8 Oct | Add a task, preset to that day |
| Today, on an empty past day | Nothing was planned for Mon 5 Oct | — |
| Today, an empty part | Nothing this evening (small, grey); "Nothing this afternoon" on today and "Nothing in the afternoon" on other days | — |
| Tasks › Habits | No habits yet | Add a habit |
| Tasks › One-time | No upcoming tasks | Add a task |
| History › One-time | Nothing completed yet | — |
| History › Habits | Finished habits will appear here | — |
| History, a search with no results | No matches | — |
| Missed › Today | You haven't missed a task today (Strict; Gentle in F-30) | — |
| Missed › Earlier | Nothing missed before today (Strict; Gentle in F-30) | — |
| Missed, filters with no results | No missed tasks match these filters (Strict; Gentle in F-30) | Clear filters |
| Stats, with no habits | Add a habit to see your stats | Add a habit |
| Habit detail, with no data yet | No data yet. Check back after its first day. | — |
| Task picker, with no duration habits | No duration tasks yet | Add a duration task, Discard |
| Day and Now widgets, with no tasks | No tasks today | Tapping opens the editor |
| Focus and Lock Screen widgets, with nothing left | You're free today | — |

### F-25 · iPad

- The layout and features are the same as on iPhone.
- Content is limited to a readable width of about 700 points and centered.
- All orientations are supported, along with split-screen and windowed multitasking. In a narrow window, the app looks like the phone version.
- The same widgets come in the same sizes, including the Lock Screen widgets.

### F-26 · Data and future sync

- v1 stores everything on the device, with no account and no server.
- The data model (§4) is designed so that a future sync service, such as Supabase or Firebase, and an Android app can use it unchanged:
  - Tables are flat and linked by IDs, with no nested data.
  - IDs are UUIDs created on the device.
  - Every row has `updated_at`. Deleting a row sets `deleted_at` instead of removing it.
  - Days and times are stored as platform-neutral numbers (§5.1).
  - Enum values are fixed strings, and they never change once shipped.
- Some data stays on the device and will never sync: the timer, the missed popup's list of seen tasks, whether the guide was completed, the pending open action, scheduled notifications, snoozes, whether the Add a widget card was closed, and the Pro entitlement.

### F-27 · Theme color

The user chooses the app's color in Settings › Theme.

- **Choices:** eight presets, Blue (the default), Indigo, Purple, Pink, Red, Orange, Green and Teal, and Custom.
  - Each preset has a light and a dark shade, so it reads well in light and dark mode.
  - Custom opens the system color picker. The chosen color is used as it is in light and dark mode, without transparency.
  - The current choice is marked. Once a custom color is chosen, the Custom swatch shows it.
- **Where it applies,** at once and on every screen: buttons and links, checkboxes, the selected day in the day strip, the part in progress and its "ends in", progress rings and bars, the floating + button, the timer bar, the guide, and the highlight in Missed.
- **Widgets:** the Home Screen widgets use it for their accents (the Day widget's current part, the Focus widget's top line, the Timer and Now widgets' buttons and progress) from their next update. The Lock Screen widgets and the tinted and clear Home Screen styles keep the system's colors (F-17).
- **What doesn't change:** the status colors (done green, missed red in the Strict style or grey in the Gentle style (F-30), short orange), which always come with an icon or text, and the app icon.
- A stored color the app can't read is treated as Blue.

### F-28 · Appearance

The user chooses whether the app follows the system's light or dark mode in Settings › Theme, above the colors.

- **Choices:** System (the default), Dark and Light. System follows the device's mode as it changes; Dark and Light always use that mode.
- **Where it applies,** at once: every screen of the app, with its sheets, dialogs and menus, the guide and the color picker.
- **What doesn't change:** the widgets, the Lock Screen, notifications and the screen shown while the app launches keep following the device's mode.
- A stored appearance the app can't read is treated as System.

### F-30 · Missed style

The user chooses how missed tasks are shown in Settings: **Gentle** (the default) or **Strict**. The style changes only how missed tasks look and read. It never changes their status, the Missed queries (§5.8) or the stats (§5.7), so honest records (§1.2) still hold. Strict is the 1.0 behavior.

| Where | Strict | Gentle (default) |
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
| Now widget footer | "2 missed today ›", red | "2 not done today ›", grey |
| End-of-day recap title | "Today: 2 missed, 1 still open" | "Today: 1 still open, 2 not done" |
| Stats, Parts of the day | "Most missed: Evening" | "Most often not done: Evening" |
| Habit detail list | "Recent missed days" | "Recent days not done" |
| Empty state, Missed › Today | "You haven't missed a task today" | "Nothing left undone today" |
| Empty state, Missed › Earlier | "Nothing missed before today" | "Nothing undone before today" |
| Empty state, filters | "No missed tasks match these filters" | "No tasks match these filters" |

- **Short** looks the same in both styles: orange ◐ with "20 of 30 min".
- In Gentle, the Missed tab's rows use secondary grey instead of red, and spoken descriptions say "not done" wherever they'd say "missed" (for example the day strip's "Has tasks not done").
- The Stats charts color a completion rate, not a status, so they're the same in both styles.
- The style applies at once, in the app, the widgets and the notifications planned from then on.
- The popup never runs in Gentle, so nothing is added to its seen list (§4.6) there. Switching from Gentle to Strict adds today's tasks that are missed at that moment to the seen list, so the popup only shows tasks missed after the switch, at the next normal open.
- A stored style the app can't read is treated as Gentle.

---

## 4. Data model

Types: `uuid`, `text`, `int`, `bool`, `timestamp` (UTC). A `?` marks a column that can be empty. Every synced table has `id`, `created_at`, `updated_at` and `deleted_at?`, and reads always ignore rows where `deleted_at` is set.

### 4.1 `tasks`

| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| title | text | 1–100 characters |
| type | text | `one_time` · `progress` · `duration` |
| date | int? | One-time tasks: day key |
| start_day | int? | Habits: day key |
| length_days | int? | Habits: empty means ongoing |
| ended_on | int? | Habits: last day, when ended by hand |
| notes | text? | 1–1,000 characters after trimming spaces and line breaks; empty notes are stored as no value |
| created_at, updated_at, deleted_at? | timestamp | |

A habit's **last day** is the earlier of `start_day + length_days − 1` and `ended_on`. Either one may be empty; if both are, the habit has no last day.

### 4.2 `schedules`

| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| task_id | uuid | → `tasks.id` |
| effective_from | int | Day key. Always `0` for one-time tasks. |
| timing | text | `fixed` · `part` · `anytime` |
| fixed_minute | int? | Minute of day in 5-minute steps, when `timing = fixed` |
| part | text? | `morning` · `noon` · `evening` · `night`, when `timing = part` |
| weekdays | int | Habits: a bitmask with Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64 (every day = 127). One-time tasks: 0. |
| target_minutes | int? | Duration habits |
| created_at, updated_at, deleted_at? | timestamp | |

- The schedule for day `d` is the row with the greatest `effective_from` that is ≤ `d`.
- A one-time task has exactly one schedule row, which is updated in place.
- Editing a habit's timing, weekdays or target:
  - creates a row with `effective_from = today`;
  - or updates the row that already has `effective_from = today`, if there is one;
  - or, for a habit that hasn't started yet, updates its first row in place.

### 4.3 `completions`

| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| task_id | uuid | A one-time task or a progress habit |
| day | int | Day key. For one-time tasks, the task's date. |
| created_at, updated_at, deleted_at? | timestamp | |

- A (task, day) pair counts as done if at least one non-deleted row exists for it.
- Undo sets `deleted_at` on every row for that pair. Duplicate rows, which a future sync could produce, are harmless.

### 4.4 `time_entries`

| Column | Type | Notes |
|---|---|---|
| id | uuid | |
| task_id | uuid | A duration habit |
| day | int | Day key |
| seconds | int | Greater than 0 |
| source | text | `timer` · `manual` |
| created_at, updated_at, deleted_at? | timestamp | |

### 4.5 `settings`

A single row with a fixed id.

| Column | Type | Default |
|---|---|---|
| morning_start · noon_start · evening_start · night_start | int | 360 · 720 · 1020 · 1260 |
| notify_part_start | bool | Removed (2026-10-12): replaced by the four columns below, one per part |
| notify_part_start_morning | bool | true |
| notify_part_start_noon | bool | false |
| notify_part_start_evening | bool | false |
| notify_part_start_night | bool | false |
| notify_ending_soon | bool | true |
| ending_soon_lead | int | 30 |
| notify_fixed | bool | true |
| fixed_lead | int | 10 |
| notify_recap | bool | true |
| recap_minute | int | 1410 (23:30) |
| notify_timer | bool | true |
| timer_alert_minutes | int | 120 |
| hide_lock_screen_titles | bool | false |
| tint_color | text | "blue" |
| appearance | text | "system" |
| missed_style | text | "gentle" |
| updated_at | timestamp | |

`tint_color` is a preset (`blue`, `indigo`, `purple`, `pink`, `red`, `orange`, `green` or `teal`) or a custom color written `#RRGGBB` (F-27).

`appearance` is `system`, `dark` or `light` (F-28).

`missed_style` is `gentle` or `strict` (F-30). A value the app can't read is treated as `gentle`.

### 4.6 State kept on the device only (never synced)

| Item | Contents |
|---|---|
| Timer | Habit id (empty for a generic timer), kind (`generic` or `habit`), the day it started, accumulated seconds, and the current segment's start (empty while paused) |
| Missed popup's seen list | Occurrence ids (`<task_id>_<day>`) and the day they belong to. It clears when the day changes. |
| Guide completed | bool |
| Pending open action | Written by widget buttons that open the app, for example "choose a habit for the finished timer" |
| Scheduled notifications | Managed entirely by §5.9 |
| Snoozes | A list of {original id, kind, fire time, day}. Cleared when the day changes (F-07). |
| Add a widget card closed | bool (F-10) |
| Pro entitlement | Whether Pro is unlocked, and when the store last confirmed it (F-34) |

---

## 5. Rules reference

### 5.1 Days and times

- Every date and time in the data is **floating local time**: a day key plus a minute of day, read in the device's current time zone. A 09:00 task stays at 09:00 when the user travels.
- To turn one into a real moment, build the year, month, day, hour and minute in the local calendar.
  - If that time doesn't exist (a daylight-saving gap), use the next valid moment.
  - If it happens twice (a daylight-saving overlap), use the first.
- Day arithmetic always goes through the calendar, never through day-key integers.
- Midnight means the start of the next day.
- The first day of the week comes from the user's region setting.

### 5.2 Parts of the day

```
start(p): morning_start, noon_start, evening_start, night_start
end(morning) = noon_start     end(noon)  = evening_start
end(evening) = night_start    end(night) = 1440

partOf(m) = morning  if m < noon_start
            noon     if m < evening_start
            evening  if m < night_start
            night    otherwise

window(o) = timing part     → [start(part), end(part))
            timing fixed    → window of partOf(fixed_minute)
            timing anytime  → [0, 1440)
```

### 5.3 Occurrences

For a day `d`:
- A one-time task occurs on `d` if and only if `date == d`.
- A habit occurs on `d` if and only if all three hold: `start_day ≤ d`, `d ≤` its last day (if it has one), and `d`'s weekday is in `schedule(d).weekdays`.
- Deleted tasks never occur.
- An occurrence's id is `<task_id>_<day>`.

### 5.4 Status

```
status(o, now):
  if o is one-time or progress and completed(o.task, o.day): return DONE
  if o is duration and minutes(o.task, o.day) ≥ schedule(o.day).target_minutes: return DONE
  today = dayKey(now)
  if o.day > today: return UPCOMING
  if o.day == today:
      m = minuteOfDay(now)
      if m < window(o).start: return UPCOMING
      if m < window(o).end:   return OPEN
  // the part has ended, or it's a past day
  if o is duration and minutes(o.task, o.day) > 0: return SHORT
  return MISSED
```

Whether an occurrence can be changed follows the table in F-04 and §5.11.

### 5.5 Duration math

- `minutes(task, d)` = floor(the sum of the seconds of that day's non-deleted entries ÷ 60).
- The scheduled days in a week are the days that fall between the start day and the last day, and whose weekday is in that day's schedule.
- `weeklyGoal` = the sum of `schedule(day).target_minutes` over the scheduled days in the week. This handles a target that changes mid-week.
- `weeklyTotal` = the sum of `minutes` over every day in the week between the start day and the last day, scheduled or not.
- The goal is met when `weeklyTotal ≥ weeklyGoal`.
- Example: target 30 on Mon, Wed and Fri gives a goal of 90. Logging Mon 50, Wed 0, Fri 45 and Sat 20 gives 115, so the goal is met. Wednesday is still Missed.

### 5.6 Next-task rule (Focus widget and Lock Screen)

Candidates are today's occurrences that are neither Done, Missed nor Short.

1. A fixed-time candidate whose time is now or within the next 60 minutes, choosing the earliest time.
2. Otherwise, a candidate in the current part, excluding fixed-time ones more than 60 minutes ahead. Fixed-time candidates whose time has passed come first (earliest first), then part-of-day candidates in creation order.
3. Otherwise, the earliest coming item. Fixed-time candidates count at their time, and part-of-day candidates of later parts count at their part's start. On a tie, fixed-time wins, then creation order.
4. Otherwise, an Anytime candidate, in creation order.
5. Otherwise, nothing, which shows as "You're free today".

The Focus widget's "Then:" line is the result of applying the rule again with the chosen item removed.

### 5.7 Stats formulas

For a range R (a week, month or year), counting up to and including today:
- **Counted habit days:** habit occurrences in R. Today's are counted only once they're Done, Missed or Short. Upcoming and Open don't count.
- **A habit day is done** when a progress habit is completed, or a duration habit's minutes reach that day's target.
- **Completion rate** = days done ÷ counted days. With no counted days, it shows "—".
- **Change from previous:** the previous range's rate subtracted from this one, in percentage points. Hidden when the previous range has no counted days.
- **One-time completed:** the number of one-time tasks whose date is in R and that have a completion.
- **Total time:** the sum of `minutes` across all habits and days in R.
- **Time per duration habit:** its minutes in R, against the sum of its targets over all its scheduled days in R, including days of R still to come.
- **Parts of the day:** for each part and for Anytime, (done ÷ counted) over every type of occurrence in R whose status is final (Done, Missed or Short). Fixed-time tasks count in their part. **Most missed** is the part with the lowest rate among those with at least 3 counted occurrences.
- **Streak:** the run of consecutive done scheduled days, counting back from the most recent counted day. Days that aren't scheduled are skipped and don't break it. Today doesn't break it while it's still Upcoming or Open. **Best** is the longest run ever.

### 5.8 Missed queries

- **Missed today:** today's occurrences with status Missed or Short.
- **Missed earlier:** occurrences before today with status Missed or Short. They include ended habits and exclude deleted tasks. The filters and sort order in F-08 apply.
- **Unseen:** missed today, minus the popup's seen list.

### 5.9 Notification planning

`plan(now, data, settings)` returns a list of {id, fire time, title, body, destination}. It covers at least the next 48 hours, and preferably 72.

| Id | Fires at | Included when (judged on current data) |
|---|---|---|
| `part-start.<day>.<part>` | `start(part)` | The part's switch is on, and the part has candidates. For Morning, Anytime candidates count too. |
| `ending-soon.<day>.<part>` | max(`start(part)`, `end(part) − lead`) | The part has candidates |
| `fixed.<task_id>.<day>` | fixed time − lead | The task isn't done |
| `recap.<day>` | `recap_minute` | That day will have tasks that aren't done |
| `timer-alert` | segment start + n × alert period (the next one only) | A timer is running |
| `snooze.fixed.<task_id>.<day>` / `snooze.ending-soon.<day>.<part>` | The snoozed time | The original reminder's condition still holds |

- Fixed-time and ending-soon items carry the snooze options that land at least 5 minutes before their part ends.
- Only items whose fire time is after now are kept. They're sorted by fire time and trimmed to the platform's limit, keeping the earliest.
- After any change, the whole plan is rebuilt.

### 5.10 Widget update moments

- **Timeline moments:** now, each part's start, each fixed time minus 60 minutes, each fixed time, and midnight.
- **For the Now widget's timer mode:** also the moment the target is reached.
- **Coverage:** today and tomorrow, so the widgets stay correct across midnight even if a refresh arrives late.
- **Between moments:** counting text such as timers and "in 45 min" updates itself.

### 5.11 Editable days

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

---

## 6. Edge cases

| Case | Behavior |
|---|---|
| An Afternoon task created at 16:50 | Open, then Missed at 17:00 |
| At 00:00 Tuesday | Monday enters the correction window. Sunday becomes final (§5.11). |
| At Afternoon's start | Yesterday becomes final. Open screens update at that moment, as they do at part boundaries. |
| A habit whose last day was yesterday | Yesterday is still correctable during the window. |
| Correcting yesterday changes a streak or a weekly total | Stats are computed, so they update at once (§5.7). |
| A yesterday row is open in Missed when the window closes | It moves to Earlier and becomes read-only. |
| A part's start time changed while today's tasks are open | Statuses are recalculated immediately, so a task can become Missed or Open again for today |
| Time zone change | Tasks keep their wall-clock times in the new zone. Notifications and widgets are rebuilt. |
| Daylight-saving gap or overlap | Handled by §5.1 |
| A habit's weekdays changed mid-week | Each day uses the schedule it had, so the weekly goal adds up day by day |
| A timer running past midnight | Saved to the day it started |
| The device restarts while a timer runs | The timer continues, because it's based on stored start times |
| The device clock is changed by hand | The timer follows the clock. This is accepted. |
| Ending or deleting a habit while its timer runs | The app asks first, then discards the timer |
| A generic timer is finished with no duration habits | The task picker shows its empty state (F-24) |
| A missed one-time task is moved to tomorrow | Today keeps it as missed, and tomorrow gets a copy |
| Notifications refused | Nothing is scheduled, and Settings shows the status |
| More notifications than the platform allows | The earliest ones are kept, and later ones are added on later rebuilds |
| Many tasks in one part | Widgets show "+N" or "+N more" |
| Very long titles | Truncated in widgets, wrapped in the app |
| The recap time set before Night's start | Not allowed, because the picker's range starts at Night |
| The app is opened for the first time | The guide (F-23), then the empty states (F-24) |

---

## 7. Defaults and limits

| Item | Value |
|---|---|
| Part starts | Morning 06:00 · Afternoon 12:00 · Evening 17:00 · Night 21:00 |
| Part start step / minimum length | 15 min / 30 min |
| Fixed time step | 5 min |
| Ending-soon lead | 30 min (15, 30, 45 or 60) |
| Fixed-time lead | 10 min (5, 10, 15 or 30) |
| End-of-day recap | 23:30 |
| Running timer alert | 2 hours (1, 2 or 3) |
| Snooze | 15 min or 1 hour, at least 5 min before the part ends |
| Duration target | 30 min, from 5 to 480 in 5-minute steps |
| Log time | 5–480 min in 5-minute steps |
| Set length | 1–365 days, 30 when switched on |
| Title | 1–100 characters |
| Notes | 0–1,000 characters |
| Minimum timer time saved | 1 minute |
| Day widget marks per column | 6, then "+N" |
| Notification horizon | At least 48 hours |
| Readable width on tablets | About 700 points |
| Theme color | Blue (8 presets, or a custom color) |
| Appearance | System (or Dark, or Light) |
| Missed style | Gentle (or Strict) |
| Correction window | Until today's Afternoon start |
| Part-start summaries | Morning on; Afternoon, Evening and Night off |

---

## 8. Build plan

Build the tasks in order, one at a time. Each task lists the features it implements, the tasks it depends on, what to build, and its acceptance criteria. The platform-specific notes for each task are in `docs/platform/<platform>.md` under the same ID. A task is done only when every acceptance item passes (definition of done in `CLAUDE.md`).

Unless a task says otherwise, tests use the default part times, a fixed time zone, and dates in October 2026. Tuesday 6 Oct 2026 is "today".

### Phase A · Foundation

#### T-01 · Project skeleton
Implements: setup · Depends on: none

- Create the project, app, widget extension, core logic module, and folder structure described in the platform file.
- Put `CLAUDE.md` and every file in `docs/` in place.

Acceptance
- [ ] The app builds and launches on phone and tablet simulators, showing a placeholder screen.
- [ ] A placeholder widget appears in the widget gallery.
- [ ] The core module's test suite runs, with one placeholder test.
- [ ] The folder structure matches the platform file.

#### T-02 · Days, weekdays and parts of the day
Implements: §5.1, §5.2, the rules in F-02 · Depends on: T-01

- Day keys, minute of day, weekday bitmasks, part windows, `partOf`, and validation of the settings' part times.

Acceptance
- [ ] Day keys convert to dates and back. Adding days works across month ends, year ends and daylight-saving changes.
- [ ] The bitmask for Mon, Wed and Fri is 21, and every day is 127.
- [ ] With the defaults, `partOf`: 05:00 → morning, 11:59 → morning, 12:00 → noon, 20:59 → evening, 21:00 → night, 23:59 → night.
- [ ] Part times that are out of order, not on a 15-minute step, or that leave a part shorter than 30 minutes are rejected.
- [ ] Custom part times move the windows to match.

#### T-03 · Data model and storage
Implements: §4, F-26 · Depends on: T-01

- Every table in §4, a storage interface that the rest of the app uses, soft deletes, and the device-only state from §4.6.
- The storage is shared between the app and the widgets.

Acceptance
- [ ] Each table supports create, read, update and soft delete. Soft-deleted rows never appear in reads.
- [ ] `updated_at` changes on every write.
- [ ] The settings row is created with the defaults on first launch.
- [ ] Device-only state survives an app restart.
- [ ] Data written by the app can be read by the widget extension.

#### T-04 · Occurrences and schedule history
Implements: §5.3, the data rules in F-03, §4.2 · Depends on: T-02, T-03

Acceptance
- [ ] A one-time task occurs only on its date.
- [ ] A Mon/Wed/Fri habit occurs on Mon 5 Oct and Wed 7 Oct, but not on Tue 6 Oct.
- [ ] A 30-day habit starting 1 Oct has 30 Oct as its last day and no occurrence on 31 Oct.
- [ ] A habit with `ended_on` set doesn't occur after that day.
- [ ] Changing a habit's weekdays on Wed: occurrences on Mon and Tue still use the old weekdays.
- [ ] Two edits on the same day leave a single schedule row for that day.
- [ ] Editing a habit that hasn't started yet updates its first schedule row.

#### T-05 · Status and the daily cycle
Implements: §5.4, F-04 · Depends on: T-04

Acceptance
- [ ] An Afternoon task: 11:59 Upcoming, 12:00 Open, 16:59 Open, 17:00 Missed. Completed at 18:00 the same day, it's Done.
- [ ] A fixed-time task at 12:30 is Missed at 17:00. An Anytime task is Missed at midnight.
- [ ] A duration habit with target 30 at its part's end: 20 min → Short, 0 min → Missed, 30 min → Done (and Done as soon as it reaches 30).
- [ ] Editing: today allows everything; yesterday during the window allows only what §5.11 allows; earlier days allow nothing; a future one-time task can be completed early; a future habit occurrence can't be completed.
- [ ] Move to tomorrow: a task that isn't missed moves its date; a missed one stays missed and gets a copy for tomorrow.

#### T-06 · Duration math
Implements: §5.5, F-05 · Depends on: T-05

Acceptance
- [ ] Minutes are the floor of the summed seconds (3,599 s → 59 min).
- [ ] The §5.5 example gives a goal of 90, a total of 115, and the goal met.
- [ ] A target that changes from 30 to 45 on Wed makes the week's goal 30 + 45 + 45.
- [ ] Entries can't be added to future days, or to past days other than yesterday during the window (the timer exception is tested in T-19).

#### T-07 · Next-task rule and missed queries
Implements: §5.6, §5.8 · Depends on: T-05

Acceptance
- [ ] At 11:45, with a fixed 12:30 task and an Afternoon task: the result is the 12:30 task (rule 1).
- [ ] At 13:00, with an Afternoon task and a fixed 16:00 task: the result is the Afternoon task (rule 2), and "Then" is the 16:00 task.
- [ ] At 13:00, with only an Evening task: the result is the Evening task, "from 17:00" (rule 3).
- [ ] At 22:00, with only an open Anytime task: the result is that task (rule 4). With nothing open: "You're free today."
- [ ] Missed today includes Short. Missed earlier respects every filter and both sort orders. Unseen excludes tasks on the seen list.

#### T-08 · Stats calculations
Implements: §5.7 · Depends on: T-06, T-07

Acceptance
- [ ] With 23 done out of 28 counted habit days, the rate is 82%.
- [ ] An evening habit at 13:00 today isn't counted yet.
- [ ] The change from the previous range is hidden when the previous range has no counted days.
- [ ] A duration habit's time goal includes the days of the range still to come.
- [ ] The part rates and "Most missed" follow §5.7, including the minimum of 3.
- [ ] A Mon/Wed/Fri habit done Mon, Wed and Fri keeps its streak across Tue and Thu, and an Open today doesn't break it.
- [ ] With no habits, the rate is "—".

### Phase B · App screens

#### T-09 · App structure and navigation
Implements: F-09 · Depends on: T-03

Acceptance
- [ ] The four tabs work. The gear opens Settings and the clock opens History (placeholders for now).
- [ ] The floating + appears on Today and Tasks, opens the editor (placeholder), and never covers the last row of a list.
- [ ] Every destination in F-09 opens correctly from an external link.
- [ ] There's space reserved for the timer bar above the tabs, and the Missed badge is in place.

#### T-10 · Settings
Implements: F-16, the setting rules in F-02 · Depends on: T-09

Acceptance
- [ ] Every setting in F-16 is present, saved, and keeps its value after a restart.
- [ ] Invalid part times can't be chosen.
- [ ] The notification permission status and its link to the system settings are shown.

#### T-11 · Task editor
Implements: F-15, F-01, the editing rules in F-03 · Depends on: T-04, T-09

Acceptance
- [ ] Each type can be created with each timing.
- [ ] All validation from F-15 works, with its messages.
- [ ] The type is read-only when editing.
- [ ] Past dates and start days can't be chosen. Parts that have ended today are greyed out with "Already over".
- [ ] Editing a habit's schedule writes schedule rows as in §4.2, and the editor shows its note.
- [ ] Delete, End habit and Delete with history each confirm first, then behave as in F-03.

#### T-12 · Today screen and Log time
Implements: F-10, Log time from F-05 · Depends on: T-05, T-06, T-11

Acceptance
- [ ] The sections, their order, and the order within each part match F-10.
- [ ] Ended parts collapse, the current part is highlighted, and its countdown updates every minute.
- [ ] Statuses change at part boundaries while the screen stays open.
- [ ] The day strip shows dots (red for missed), swipes by week, and has a "Today" button.
- [ ] Past days are read-only. Future days follow the rules in F-04.
- [ ] The swipe actions and tap behavior match F-10. Log time adds an entry to today.
- [ ] The empty states match F-24.

#### T-13 · Tasks tab
Implements: F-11 · Depends on: T-12

Acceptance
- [ ] The segment is remembered after a restart.
- [ ] The Habits rows show their progress summaries, as in F-11.
- [ ] The One-time list is grouped by date and excludes done and missed tasks.
- [ ] The + presets its type from the segment.
- [ ] The empty states match F-24.

#### T-14 · History
Implements: F-12 · Depends on: T-13

Acceptance
- [ ] Both segments show the right items in the right order.
- [ ] Today's completions can be undone, and older ones can't.
- [ ] Start again creates a new habit starting today, and the old one stays.
- [ ] Search filters by title.
- [ ] The empty states match F-24.

#### T-15 · Habit detail
Implements: F-13 · Depends on: T-08, T-12

Acceptance
- [ ] The week dots, the month calendar, the stats, the streak and the recent missed days match the underlying data.
- [ ] Today's entries can be deleted, and past entries can't.
- [ ] Every button behaves as in F-13. "See all" opens Missed filtered to this habit.

#### T-16 · Missed tab
Implements: F-08 (the tab) · Depends on: T-07, T-12

Acceptance
- [ ] The Today section's actions work, and a task leaves the section as soon as it's no longer missed.
- [ ] Earlier is read-only. Its sort and filters work, the count follows the filters, and Clear filters resets them.
- [ ] The badge shows today's missed count.
- [ ] The empty states match F-24.

#### T-17 · Missed popup
Implements: F-08 (the popup) · Depends on: T-16

Acceptance
- [ ] Opening the app normally with unseen missed tasks shows the popup over the current screen.
- [ ] Review switches to the Missed tab and highlights those tasks. Not now closes the popup.
- [ ] A task that has been seen never triggers the popup again. The seen list resets the next day.
- [ ] Opening the app from a widget or a notification doesn't show the popup, and the next normal open does.

#### T-18 · Stats screen
Implements: F-14 · Depends on: T-08, T-09

Acceptance
- [ ] Every card in F-14 shows correct data for Week, Month and Year.
- [ ] Navigating back works within its limits.
- [ ] Tapping a day in the chart opens that day in Today.
- [ ] The empty state matches F-24.

### Phase C · Timer

#### T-19 · Timer engine
Implements: the rules in F-06 · Depends on: T-06

Acceptance
- [ ] Only one timer can exist.
- [ ] Paused time isn't counted, and pause and resume can repeat any number of times.
- [ ] The time freezes at Done.
- [ ] Under 1 minute, nothing is saved.
- [ ] Time from a timer started at 23:40 and finished at 00:20 is saved to the day it started.
- [ ] Discard saves nothing.
- [ ] The alert time follows "since last start or resume", and pausing cancels the alert.
- [ ] Ending or deleting a habit whose timer is running discards the timer.

#### T-20 · Timer in the app
Implements: the app parts of F-06 · Depends on: T-19, T-12, T-15

Acceptance
- [ ] ▶ on a Today row and in Habit detail starts a habit timer. Every ▶ is hidden while a timer exists.
- [ ] The timer bar shows on every tab with working controls, and tapping it opens the timer screen.
- [ ] The timer screen's progress includes time logged earlier that day.
- [ ] A generic timer's Done opens the task picker, with the order from F-06, Discard, and its empty state.
- [ ] The confirmation offers Undo and Change task, and both work.

### Phase D · Notifications

#### T-21 · Notifications
Implements: F-07, §5.9, the alert in F-06 · Depends on: T-10, T-16, T-19

Acceptance
- [ ] Every kind fires at the right time, with the text from F-07, only when its condition holds.
- [ ] Completing a task removes it from the summaries waiting to fire, and from the ending-soon and recap notifications, or cancels them when nothing is left.
- [ ] Turning a kind off in Settings or changing a lead time takes effect immediately.
- [ ] At least 48 hours of notifications are always scheduled, within the platform's limit.
- [ ] Tapping each notification opens its destination. The timer alert's Stop and Keep going work.
- [ ] With permission refused, nothing is scheduled and nothing crashes.

### Phase E · Widgets

#### T-22 · Widget foundation
Implements: F-17, §5.10 · Depends on: T-05, T-07, T-19, T-21

Acceptance
- [ ] Widgets read the same data as the app.
- [ ] With the app closed, widgets change exactly at the part boundaries, at fixed times, and at midnight.
- [ ] Any change in the app or from a widget refreshes every widget and rebuilds the notifications.
- [ ] A load failure shows "Open Tempo to refresh".

#### T-23 · Timer widget
Implements: F-18 · Depends on: T-22, T-20

Acceptance
- [ ] Every state in F-18 displays correctly, and its buttons work without opening the app.
- [ ] Done on a generic timer opens the app's task picker, with the time frozen at the tap.
- [ ] A habit timer started elsewhere shows here as display only.

#### T-24 · Now widget
Implements: F-21 · Depends on: T-22, T-23

Acceptance
- [ ] List mode shows the current part, then the next part, then Anytime, with "+N more" and the missed footer.
- [ ] Checkboxes complete and undo without opening the app.
- [ ] ▶ turns the widget into timer mode, and the Timer widget then displays the same timer.
- [ ] In timer mode, Done saves without opening the app and Discard saves nothing. Both return to list mode.
- [ ] While a generic timer exists, the display-only line shows and every ▶ is hidden.

#### T-25 · Day widget
Implements: F-19 · Depends on: T-22

Acceptance
- [ ] The columns, marks, labels, footer and highlight match F-19.
- [ ] Each column opens Today at its part.
- [ ] The empty and "free" states work.

#### T-26 · Focus widget
Implements: F-20 · Depends on: T-22

Acceptance
- [ ] It shows the next-task rule's result with the right "when" line and "Then:" line, and updates on its own as time passes.
- [ ] "You're free today" shows when nothing is left.
- [ ] Tapping opens the app at that task.

#### T-27 · Lock Screen widgets
Implements: F-22 · Depends on: T-26, T-10

Acceptance
- [ ] Both sizes show every situation in the F-22 table.
- [ ] With "Hide task names" on, titles are hidden while the device is locked.

### Phase F · Finish

#### T-28 · First-launch guide
Implements: F-23 · Depends on: T-10, T-21

Acceptance
- [ ] It shows on first launch only.
- [ ] Skip jumps to page 6.
- [ ] Page 6 saves the part times. Page 7 asks for notification permission.
- [ ] How to use in Settings reopens pages 1–5.

#### T-29 · Empty states check
Implements: F-24 · Depends on: T-28

Acceptance
- [ ] Every row of the F-24 table has been checked in the app and in the widgets.
- [ ] Every "Add" button opens the editor preset correctly.

#### T-30 · iPad
Implements: F-25 · Depends on: T-29

Acceptance
- [ ] Every screen respects the readable width.
- [ ] All orientations and multitasking sizes work, and narrow windows look like the phone.
- [ ] The widgets and Lock Screen widgets work on iPad.

#### T-31 · Accessibility and polish
Implements: quality across every feature · Depends on: T-30

Acceptance
- [ ] Every control has an accessible label, and statuses are announced as text.
- [ ] Layouts hold at the largest text sizes.
- [ ] Dark mode and tinted widget styles are legible.
- [ ] Completing a task and switching days give light haptic feedback.

#### T-32 · Final verification
Implements: everything · Depends on: T-31

Acceptance
- [ ] Every acceptance item in T-01–T-31 has been re-run on the final build.
- [ ] The manual QA checklist in the platform file passes.
- [ ] `docs/DOCUMENTATION.md` describes every feature as built.

### Phase G · Additions

#### T-33 · Theme color
Implements: F-27, F-16, F-17, §4.5 · Depends on: T-32

Acceptance
- [ ] Settings › Theme shows the eight presets and Custom, with the current choice marked and every swatch named for VoiceOver.
- [ ] Choosing a preset or a custom color re-tints the whole app at once, and the Home Screen widgets' accents from their next update. The choice survives a restart.
- [ ] Every preset reads well in light and dark mode. The status colors and the app icon don't change.
- [ ] Existing data is kept when the store gains the new column, and a stored color the app can't read is treated as Blue.

#### T-34 · Appearance
Implements: F-28, F-16, F-17, §4.5 · Depends on: T-33

Acceptance
- [ ] Settings › Theme shows Appearance, with System, Dark and Light, above the colors. The current choice is marked, and each choice is named for VoiceOver.
- [ ] Dark and Light change every screen of the app at once, with its sheets, dialogs and menus; System follows the device again. The choice survives a restart.
- [ ] The widgets and notifications keep following the device's mode.
- [ ] Existing data, the theme color included, is kept when the store gains the new column, and a stored appearance the app can't read is treated as System.

### Phase H · Pre-launch changes (1.1)

The changes `C-01`–`C-16` are described in `docs/CHANGE-SPEC-1.1.md`. Each task copies its change into this file before it's built, so until then the features it names (F-29–F-34, §5.11) are only in the change spec. T-52 is listed last because it's blocked on the owner choosing a name.

#### T-35 · Spec catches up with the build
Implements: F-06, F-20, F-21, F-22 (C-01) · Depends on: T-34

Acceptance
- [ ] F-06, F-20, F-21 and F-22 in SPEC match D-084, D-090, D-091 and D-092, and DOCUMENTATION.md agrees.
- [ ] CLAUDE.md has the D-103 rule.
- [ ] CHANGELOG records the edits.

#### T-36 · Minimum system version
Implements: the minimum system version (C-02, platform file only) · Depends on: T-35

Acceptance
- [ ] Every target and the `Core` package target iOS 18.0, and the project builds without warnings about it.
- [ ] CLAUDE.md and ios.md state the new API rule (CHANGE-SPEC-1.1 §5).
- [ ] The full test suite passes.

#### T-37 · Data model changes
Implements: §4.1, §4.5, §4.6, F-26 (the data model changes in CHANGE-SPEC-1.1 §3) · Depends on: T-36

Acceptance
- [ ] An existing store opens with its data intact, and the new columns take the defaults in CHANGE-SPEC-1.1 §3.
- [ ] `notes` is trimmed, empty notes are stored as no value, and notes over 1,000 characters are rejected.
- [ ] An unreadable `missed_style` reads as `gentle`.
- [ ] The new device-only items survive a restart, and Snoozes clear when the day changes.
- [ ] The widget extension reads the new settings columns.

#### T-38 · Notes
Implements: notes in F-01, F-04, F-10, F-11, F-13, F-15, §4.1 (C-03) · Depends on: T-37

Acceptance
- [ ] Notes can be added, changed and cleared in the editor for every task type.
- [ ] Habit detail shows notes. Rows in Today and Tasks show the notes icon only when there are notes.
- [ ] No widget, Lock Screen widget or notification shows notes.
- [ ] Move to tomorrow on a missed task copies its notes.
- [ ] Editing a habit's notes doesn't create a schedule row.

#### T-39 · "Afternoon" on screen
Implements: F-02's part names and all user-facing text (C-04) · Depends on: T-35

Acceptance
- [ ] No user-facing text says "Noon": app, widgets, Lock Screen widgets, notifications, guide or empty states. This is checked in both string catalogs.
- [ ] Stored values, `noon_start` and notification ids are unchanged, and existing data loads.
- [ ] Empty parts read "Nothing this afternoon" today and "Nothing in the afternoon" on other days.
- [ ] The longer name fits: the Day widget's columns, the Focus widget's top line and both Lock Screen widgets, at the default and largest text sizes they allow.

#### T-40 · Missed style
Implements: F-30 (C-05) · Depends on: T-37, T-39

Acceptance
- [ ] Settings shows Missed tasks with Gentle and Strict, set to Gentle on a new install.
- [ ] Every row of the F-30 table shows the right text, color and mark in each style, in the app and in the widgets.
- [ ] In Gentle, the tab has no badge and the popup never appears. In Strict, both behave as in 1.0 (T-16, T-17).
- [ ] Statuses, Missed queries and every Stats number are identical in both styles for the same data.
- [ ] Switching style updates the app and widgets at once, and the next notification rebuild uses the new copy.
- [ ] Every status still has an icon or text as well as a color (F-17).

#### T-41 · Correction window
Implements: §5.11 (C-06) · Depends on: T-40

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
Implements: part summaries in F-07, F-16, §5.9 (C-07) · Depends on: T-37, T-39

Acceptance
- [ ] Settings shows four part-start switches. On a new install, only Morning is on.
- [ ] With the defaults, only the Morning summary is planned, and it still lists open Anytime tasks.
- [ ] Turning on any part's switch plans that part's summaries at once.
- [ ] Ending-soon, fixed-time and recap notifications are unchanged.

#### T-43 · Snooze
Implements: snoozing in F-07, §5.9 (C-08) · Depends on: T-42

Acceptance
- [ ] Fixed-time and ending-soon notifications offer only the snooze options that land at least 5 minutes before their part ends. For example, Evening's ending soon at 20:30 offers only 15 min.
- [ ] Snoozing schedules one reminder at the tap time plus the option, without opening the app. Snoozing again replaces it.
- [ ] A snoozed fixed-time reminder after its time reads "Started N min ago".
- [ ] Completing the task, or the part running out of candidates, cancels the snooze at the next rebuild.
- [ ] Snoozes are cleared at midnight. (That they aren't exported is checked in T-48.)
- [ ] A late tap fires no later than 5 minutes before the part ends, and a tap after that schedules nothing.
- [ ] With permission refused, nothing is scheduled and nothing crashes.

#### T-44 · Same timer controls everywhere
Implements: F-06, F-17, F-18, F-21 (C-09) · Depends on: T-35

Acceptance
- [ ] The Timer widget shows every state in the new F-18 table, and its buttons work without opening the app.
- [ ] Done on a habit timer in the Timer widget saves without opening the app. Under 1 minute, it saves nothing and returns to Idle.
- [ ] Done on a generic timer in the Timer widget or the Now widget opens the task picker, with the time frozen at the tap.
- [ ] The Now widget's generic timer line has working Pause/Resume and Done.
- [ ] Pausing in one place shows as paused everywhere: both widgets, the app's timer bar and the timer screen.
- [ ] T-19, T-20, T-23 and T-24 still pass, with their acceptance items updated to the new table.

#### T-45 · Timer Live Activity
Implements: F-31 (C-10) · Depends on: T-44, T-36

Acceptance
- [ ] Starting a timer from the app, the Timer widget or the Now widget shows the Live Activity. Done or Discard anywhere ends it. (The control and Shortcuts are checked in T-46 and T-47.)
- [ ] Pause/Resume and Done work from the Lock Screen and the Dynamic Island without opening the app. A generic Done opens the task picker.
- [ ] A habit timer shows progress including time logged earlier that day.
- [ ] With Hide task names on, the habit name is hidden on the locked Lock Screen.
- [ ] With Live Activities turned off for the app, timers work as before.
- [ ] A timer started at 23:40 and finished at 00:20 still saves to the day it started, from the Live Activity too.

#### T-46 · Timer control
Implements: F-32 (C-11) · Depends on: T-44, T-36

Acceptance
- [ ] The control appears in the controls gallery and works in Control Center and on the Lock Screen.
- [ ] Its label follows the timer's state in the F-32 table, including after changes made elsewhere.
- [ ] Tapping starts, pauses or resumes without opening the app. Every widget and the Live Activity refresh, and starting a timer from the control shows the Live Activity.

#### T-47 · Shortcuts actions
Implements: F-33 (C-12) · Depends on: T-44, T-45

Acceptance
- [ ] All five actions appear in Shortcuts with the parameters in F-33, and the suggested phrases work with Siri.
- [ ] Each refusal in the F-33 table returns its message and changes nothing.
- [ ] Add task follows the editor's validation (F-15, D-035, D-069).
- [ ] Each action refreshes the widgets and the Live Activity and rebuilds notifications. Start timer shows the Live Activity.

#### T-48 · Export and import
Implements: F-29 (C-13) · Depends on: T-38, T-42

Acceptance
- [ ] Export writes the F-29 format with every non-deleted row of every synced table, and no device-only state (no timer, seen list or snoozes).
- [ ] Importing an export from the same data gives identical tables: same ids, values and timestamps.
- [ ] An invalid file, a file with a broken `task_id`, a file with invalid settings values, and a newer version are each refused with their message, and nothing changes.
- [ ] Import with a running timer warns first, then discards it. After import, the seen list and snoozes are empty, and widgets and notifications match the imported data.
- [ ] A backup without optional columns imports with the defaults in §4, and unknown columns are ignored.
- [ ] The format is covered by `Core` tests that don't depend on the platform.

#### T-49 · Start again opens the editor
Implements: Start again in F-03 and F-12 (C-14) · Depends on: T-38

Acceptance
- [ ] Start again opens the editor filled in from the ended habit, notes included, with the type read-only.
- [ ] At 13:00, for an ended Morning habit, Starts defaults to tomorrow. For an Evening or Anytime habit, it defaults to today.
- [ ] Save creates a new habit, and Cancel creates nothing. The ended habit and its history are unchanged.

#### T-50 · Shorter guide and Add a widget card
Implements: F-23 and the Add a widget card in F-10 (C-15) · Depends on: T-40

Acceptance
- [ ] The guide has the six pages in F-23. Skip on pages 1–4 jumps to page 5, and How to use shows pages 1–4 with Done.
- [ ] Page 3 shows the widget steps in pictures, legible in light mode, in dark mode and at the largest text size.
- [ ] Today shows the card while no Tempo widget is installed. It disappears once one is added, checked when the app becomes active, and stays gone after it's closed.
- [ ] Show me how opens guide page 3.
- [ ] T-28's acceptance items still pass with the new page numbers.

#### T-51 · Tempo Pro
Implements: F-34 (C-16) · Depends on: T-37

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
- [ ] The manual QA checklist in ios.md passes, with the items added in CHANGE-SPEC-1.1 §5.
- [ ] SPEC's version is 1.1, and DOCUMENTATION.md describes every change as built.

#### T-52 · Final name
Implements: the SPEC header note · Depends on: the owner choosing a name · **Blocked**

It's listed last, after T-53, so the blocked task doesn't hold up the others (`CLAUDE.md` runs the first task that isn't done).

Acceptance
- [ ] The find-and-replace in the SPEC header is done across the docs, the strings and the identifiers listed in ios.md §2.
- [ ] Decide whether the bundle identifier keeps `tempo` before the App Store record is created. The display name can change later; the bundle identifier can't.
- [ ] The App Store record and the Pro product (T-51) are created only after this decision. The product ID doesn't contain the name, so it doesn't change.
