# Tempo

**A to-do app for iPhone and iPad that organizes your day by morning, afternoon, evening and night. You use it mostly from widgets.**

Every task in Tempo says *when* in the day it belongs: a fixed time, a part of the day, or anytime today. One-time tasks and repeating habits share the same list. Most things can be done from the Home Screen or the Lock Screen without opening the app. Anything you didn't get to is recorded honestly instead of quietly rolling over to the next day.

> **Status:** in development and not on the App Store yet. Every 1.0 feature is built and tested, and the 1.1 pre-launch changes are under way (see the [Roadmap](#roadmap)). "Tempo" is a working title.

- iOS and iPadOS 18 or later, as one universal app
- Swift and SwiftUI, with no third-party dependencies
- All data stays on the device. There's no account and no server.

---

## Contents

- [Why Tempo](#why-tempo)
- [Features](#features)
  - [Planning by time of day](#planning-by-time-of-day)
  - [Honest records](#honest-records)
  - [Time tracking and the timer](#time-tracking-and-the-timer)
  - [Widgets](#widgets)
  - [Reminders](#reminders)
  - [Screens](#screens)
  - [Personalization and polish](#personalization-and-polish)
  - [Your data](#your-data)
- [Roadmap](#roadmap)
- [How it's built](#how-its-built)
- [Building and running](#building-and-running)
- [How this project is developed](#how-this-project-is-developed)

---

## Why Tempo

Most to-do apps are organized around lists, projects, tags and due dates. They tell you *what* you have to do, but not *when in the day* you'll do it. That causes a few familiar problems:

| Problem | What Tempo does |
|---|---|
| A list of 15 things "due today" doesn't tell you what to do **right now**. | Tasks are grouped into Morning, Afternoon, Evening and Night, and the widgets always show the next thing. |
| Unfinished tasks roll over or stay red forever, so you never see what actually slipped. | A task not done within its part of the day is recorded as missed, and you can review those in their own tab. |
| You have to open the app to check or tick anything off, so after a while you stop opening it. | Widgets come first. You can check off tasks and start, pause and finish timers from the Home Screen and Lock Screen. |
| Habits ("take medicine", "read 30 minutes") live in a separate tracker with its own reminders. | One-time tasks, check-off habits and timed habits live in the same day, with the same reminders. |
| A personal to-do list shouldn't need an account or a server. | Everything is stored on the device, in a data model that's ready for sync later. |

### Principles

1. **Widget-first.** The most common actions work from widgets.
2. **Organized by time of day.** No lists, tags, projects or priorities.
3. **Honest records.** A task not done within its part of the day is missed. Today can be corrected until midnight, and yesterday until the afternoon starts. Earlier days are final.
4. **On the device, no account.** No sign-up and no sync in v1.
5. **Platform-neutral data and rules,** so an Android app and future sync can reuse them.

---

## Features

The feature IDs (`F-xx`) refer to the full product spec in [`docs/SPEC.md`](docs/SPEC.md).

### Planning by time of day

#### Three kinds of tasks · `F-01`

**Problem:** To-do apps and habit trackers are usually separate apps, and neither handles "read 30 minutes a day" well, because that isn't a checkbox.

| Type | Example | Goal |
|---|---|---|
| **One-time** | Renew passport on Thursday | Do it once |
| **Progress habit** | Take medicine every day for 30 days | Check it off on each scheduled day |
| **Duration habit** | Read 30 min a day | Reach a daily target in minutes, and a weekly goal |

- A task's type is set when you create it and can't change afterward, so a habit's history always means the same thing.

#### Notes · `F-01`

**Problem:** A title often isn't enough: you also need the address, the dosage or the chapter you're on.

- Any task can have notes, up to 1,000 characters. A small icon marks tasks that have them.
- Notes never appear in widgets, on the Lock Screen or in notifications, so they stay private.

#### Timing and parts of the day · `F-02`

**Problem:** A due date tells you which day, not when in that day. "Sometime today" tasks drift toward the evening and get dropped.

- Every task has a timing:
  - a **fixed time** ("Interview at 12:30");
  - a **part of the day** ("Gym in the evening");
  - **Anytime** ("Renew passport, sometime today").
- The four parts are **Morning, Afternoon, Evening and Night**. You set their start times (by default 06:00, 12:00, 17:00 and 21:00).
- Tasks store their part, not a clock time. If you move Evening to start at 18:00, every evening task moves with it, along with its reminders and widget updates. Past days aren't affected.
- Times are local, so a 09:00 task stays at 09:00 when you travel. Daylight-saving changes are handled.

#### Habit schedules and goals · `F-03`

**Problem:** Real habits don't run every day forever. And in many trackers, editing a habit rewrites its past: switch from "daily" to "weekdays" and last month's record changes too.

- **Repeat on** any set of weekdays, from a **start day**, either **ongoing** or for a **set length** of 1–365 days (for example, a 30-day challenge).
- **Duration habits** have a daily target of 5–480 minutes. Their **weekly goal** is the sum of that week's scheduled targets, so a short Wednesday can be made up on Saturday.
- **Schedule history:** a change to the timing, weekdays or target applies from today onward. Earlier days keep the schedule they had, so old stats stay correct.
- **End habit** stops a habit and keeps its history. **Delete with history** removes it completely, after you confirm. Ended habits move to History.

#### Task editor · `F-15`

**Problem:** It's easy to create a task that can't succeed. A morning task added at 3 pm would be missed the moment it was saved.

- One form for every type, filled in from where you opened it: the selected day, the Tasks segment, or a widget.
- Parts of the day that are already over are greyed out as "Already over".
- Messages appear right under the field that needs fixing, and Save stays disabled until the task is valid.
- When you edit a habit, a note explains that changes apply from today and that earlier days keep their old schedule.

### Honest records

#### Status and the daily cycle · `F-04`

**Problem:** In most to-do apps an overdue task just carries over, so you never get an honest picture of what you actually did each day.

- Each task, on each day, has a status: **Upcoming**, **Open**, **Done**, **Short** (a duration habit with some time logged, but less than the target) or **Missed**.
- A task becomes Missed when its part of the day ends. Morning tasks are missed when Afternoon starts, and Night and Anytime tasks at midnight.
- Statuses are calculated from the clock and never stored. They're always correct, even after the app has been closed for days, with no background job keeping them up to date.
- **Move to tomorrow** (one-time tasks): if the task is already missed, it stays on today as missed and a copy goes to tomorrow, so the record stays honest.
- Future one-time tasks can be completed early or moved. Past days are read-only.

#### Correction window for yesterday · `§5.11`

**Problem:** A hard midnight cutoff punishes forgetting to *log* something, not forgetting to *do* it. Taking your medicine at 23:50 and ticking it off at 00:10 shouldn't count as a permanent miss.

- Until today's Afternoon starts, you can still correct yesterday: complete or undo tasks, log time, and delete time entries.
- Today shows "You can still change yesterday until 12:00" while the window is open.
- After that, yesterday is final, like every day before it.

#### Missed tab and missed popup · `F-08`

**Problem:** Things that slipped disappear from view, so you can't learn from them: which habits you skip, or which part of your day keeps falling apart.

- The **Today** section ("You can still change these") lists today's missed tasks, plus yesterday's during the correction window. You can mark them done, log time or move them to tomorrow.
- The **Earlier** section lists every missed day before that, read-only. You can sort it and filter it by date range, task type, part of the day or a specific task.
- **Missed popup** (Strict style only): when you open the app normally, it says "You missed 2 tasks today" and offers to review them. Each task appears in it only once, and it never appears when you opened the app from a widget or a notification.

#### Missed style: Gentle or Strict · `F-30`

**Problem:** Red labels, badges and popups all point at failure. That motivates some people and makes others delete the app.

- **Gentle** (the default): tasks you didn't get to read "Not done" in grey. There's no badge and no popup, and the tab is called Not done.
- **Strict:** "Missed" in red, a red dot on those days, a badge on the tab and the missed popup.
- The style only changes how missed tasks look. Statuses and stats are the same in both styles, so the record stays honest either way.

### Time tracking and the timer

#### Time tracking and Log time · `F-05`

**Problem:** Not every minute gets timed live. Maybe you read a paper book, or went for a run without your phone.

- Time is recorded as entries, from the timer or by hand, and a habit's minutes for a day are the sum of that day's entries.
- **Log time** adds 5–480 minutes in 5-minute steps, to today (or to yesterday during the correction window).
- There's no upper limit: going past the target is normal. Time logged on an unscheduled day still counts toward the weekly total.
- Today's entries can be deleted in Habit detail if you made a mistake.

#### Timer · `F-06`

**Problem:** Most timers make you decide what you're timing before you start, lose time when you work past midnight, and keep running for hours when you forget them.

- **Generic timer:** start it right away, and choose which habit the time belongs to when you finish. The task picker lists habits still below today's target first, with their progress ("Read · 10 of 30 min").
- **Habit timer:** tap ▶ on a duration habit and it starts counting immediately.
- There's one timer at a time. You can pause and resume it as often as you like, with the same controls in the app, the widgets and the Live Activity. The last action wins.
- Time counts toward the **day the timer started**, even if you finish after midnight.
- Under a minute, nothing is saved. Otherwise a confirmation appears ("Added 18 min to Read · 28 of 30 min today") with **Undo** and **Change task**.
- **Running alert:** after 2 hours of running (you can change this), a notification asks whether to **Stop** or **Keep going**.
- While a timer exists, a **timer bar** sits above the tabs on every screen. The **timer screen** shows a large clock and progress toward the target, including time you logged earlier that day.

#### Timer Live Activity · `F-31` *(in progress)*

**Problem:** People expect a running timer on the Lock Screen and in the Dynamic Island. Without a Timer widget on the Home Screen, there's otherwise no way to see the timer outside the app.

- Shows the habit name, the clock, and for habit timers a progress bar ("22:15 of 30 min today"), with **Pause/Resume** and **Done**.
- It starts and ends with the timer, wherever the timer was started or finished.
- With **Hide task names** on, the habit name is hidden while the device is locked.

### Widgets

Widgets are the main way to use Tempo.

#### Rules every widget follows · `F-17`

**Problem:** A widget that shows stale data is worse than no widget at all. And a widget that can only open the app doesn't save you any time.

- Widgets show **today** and move to the new day at midnight on their own.
- They update at the start of each part of the day, an hour before and at each fixed-time task, and at midnight, without the app running.
- Any change anywhere (in the app, from a widget button or from a notification) refreshes every widget.
- Widget buttons work without opening the app.
- Status is never shown by color alone; an icon or text always goes with it. Widgets support dark mode and the tinted Home Screen styles.

| Widget | Size | What it shows | What it's for |
|---|---|---|---|
| **Timer** · `F-18` | Small | **Start**, or the running clock with Pause/Resume and Done | Start timing with one tap from the Home Screen |
| **Day** · `F-19` | Medium | Four columns, one per part of the day, with a mark per task (✓ done, ○ to do, ✗ missed or – not done, ◐ partly done) and "N left" | Seeing the shape of the whole day at a glance |
| **Focus** · `F-20` | Medium | The one next thing, in large text ("NEXT · 12:30 · in 45 min"), and what comes after it | Answering "what should I do right now?" without reading a list |
| **Now** · `F-21` | Large | The current and next parts' tasks with checkboxes and ▶. While a habit timer runs, the whole widget becomes the timer | Getting through the day without opening the app |
| **Lock Screen** · `F-22` | Rectangular and inline | The next task ("12:30 · in 45 min / Interview") | Seeing what's next whenever you pick up your phone |

**How "next" is chosen** (Focus and Lock Screen): a fixed-time task within the next hour comes first. Otherwise it's something in the current part, then the earliest thing coming up, then an Anytime task. When nothing is left, the widget says "You're free today".

**Privacy:** with **Hide task names on the Lock Screen** turned on, titles stay hidden until the device is unlocked.

### Reminders

#### Notifications · `F-07`

**Problem:** Too many reminders and people switch them all off. A reminder at the wrong moment gets forgotten, and one with outdated text can be wrong.

| Kind | When | Example |
|---|---|---|
| **Part starts** | When a part of the day begins | "Afternoon · 3 tasks": Call the bank, Interview at 12:30, Read |
| **Ending soon** | 30 min before a part ends (you can change this) | "Evening ends in 30 min": 2 left: Gym, Read (10 of 30 min) |
| **Fixed time** | 10 min before a timed task (you can change this) | "Interview at 12:30": In 10 min |
| **End-of-day recap** | 23:30 by default | "Today: 1 still open, 2 not done" |
| **Timer running** | After the alert time | "Read timer is still running" |

- Each one is sent only when it's needed, for example only if something in that part isn't done yet.
- Each part's summary has its own switch. **Only Morning's is on by default**, to keep a busy day from bringing a stream of notifications.
- **Snooze:** fixed-time and ending-soon reminders offer **Snooze 15 min** and **Snooze 1 hour**. A snoozed reminder never fires after its part of the day is nearly over, and it's dropped if the task gets done in the meantime.
- The text always reflects your latest data. Any change rebuilds the planned notifications, and at least the next 48 hours are always scheduled, topped up in the background.
- Tapping a notification opens the right place: Today at that part or task, the Missed tab, or the timer screen.

### Screens

The app has four tabs (**Today**, **Tasks**, **Missed** and **Stats**), with Settings and History one tap away, and a floating **+** button for adding tasks. `F-09`

#### Today · `F-10`

**Problem:** A flat list doesn't show where you are in the day.

- A **day strip** for the week, with a dot on days that have tasks. Swipe to move between weeks.
- Sections for **Morning, Afternoon, Evening, Night and Anytime**. Parts that are over collapse into one line ("Morning · 2 done · 1 not done"). The current part is highlighted with "ends in 1h 20m", updated every minute.
- Rows have a checkbox, or progress and ▶ for duration habits. Swipe actions offer only what's allowed for that day (Done, Log time, Move to tomorrow, Edit, Delete).
- Past days are read-only, and future days are for planning ahead.
- Ending or deleting a habit while its timer is running asks first, so a timer is never left without a habit.

#### Tasks · `F-11`

**Problem:** Today shows one day, but you also need an overview of everything you've committed to.

- **Habits:** every active habit, with its schedule ("Mon, Wed, Fri · Evening") and progress ("4 of 5 this week", "Day 12 of 30", "2h 10m of 3h 30m this week").
- **One-time:** everything coming up that isn't done yet, grouped by date.

#### History · `F-12`

**Problem:** Finished things deserve a record. Ended habits shouldn't clutter the active list, but they shouldn't disappear either.

- Completed one-time tasks, grouped by the day they were done, with search.
- Ended habits with their result ("Done 27 of 30 days", "On target 18 of 20 days · 14h 20m total") and **Start again**, which begins a new run while leaving the old one's history untouched.

#### Habit detail · `F-13`

**Problem:** "Am I actually keeping this habit?" takes more than a checkmark to answer.

- This week as seven dots, plus a month calendar colored by result.
- Completion rates for the week, month and year. Duration habits also show total time and the time against this week's goal.
- Current and best **streak**.
- Today's time entries, which you can delete, and recent missed days with a link to all of them.

#### Stats · `F-14`

**Problem:** Looking at one habit at a time doesn't show patterns across your whole routine, like the part of the day you keep dropping.

- **Week, Month or Year**, with arrows to go back in time.
- **Overview:** the completion rate and its change from the previous period ("82%, up 8 points from last week"), habit days done, one-time tasks completed, and total time logged.
- A **completion chart**, **time per habit** against its goal, the completion rate **per part of the day** ("Most often not done: Evening"), **streaks**, and each habit's rate.

### Personalization and polish

- **Settings** · `F-16`: part-of-day start times, Gentle or Strict, every reminder with its timing, theme, privacy, and help, all on one screen.
- **Theme color** · `F-27`: eight colors, each with a light and a dark shade, or a custom color. It applies to the app and to the widgets' accents. Status colors never change, so done, missed and short always mean the same thing.
- **Appearance** · `F-28`: System, Dark or Light for the app. Widgets always follow the device.
- **First-launch guide** · `F-23`: a few short pages explaining parts of the day, task types, reminders and widgets. You can skip the explanations, but not the two setup pages (your part-of-day times and the notification permission). You can reopen it from Settings › How to use.
- **Empty states** · `F-24`: every empty screen explains why it's empty and offers the right **Add** button, already filled in for that place.
- **iPad** · `F-25`: the same app and widgets, with content kept to a readable width. It supports every orientation, Split View and Stage Manager, and looks like the phone version in a narrow window.
- **Accessibility:** every control has a VoiceOver label, statuses are read out as text, layouts hold up at the largest text size, and completing a task gives haptic feedback.

### Your data

#### On the device, ready for sync · `F-26`

**Problem:** A personal to-do list shouldn't need an account. And an app built only for one device usually has to rebuild its data model before it can add sync or reach another platform.

- Everything is stored on the device, in a store shared by the app and its widgets. There's no account and no server.
- The data model is ready for sync and Android from the start: flat tables linked by UUIDs, an `updated_at` on every row, deletes that mark rows instead of removing them, and days and times stored as platform-neutral numbers.
- State that belongs to one device (the running timer, snoozes, the missed popup's seen list) is kept apart and will never sync.

---

## Roadmap

The 1.1 pre-launch changes are tracked in [`docs/PROGRESS.md`](docs/PROGRESS.md). Done so far: notes, the "Afternoon" name, the Gentle/Strict missed style, the correction window, per-part summaries, snooze, and the same timer controls everywhere.

| Next | What it solves |
|---|---|
| **Timer Live Activity** (`F-31`, in progress) | Seeing and controlling the timer from the Lock Screen and Dynamic Island |
| **Timer control** (`F-32`) | Starting, pausing and resuming the timer from Control Center, the Lock Screen or the Action button |
| **Shortcuts actions** (`F-33`) | Add task, Complete task, Start timer, Pause or resume timer, and Log time, from Siri and automations |
| **Export and import** (`F-29`) | Years of habit history currently depend on a full device backup. A JSON backup protects it and moves it to a new device. |
| **Start again opens the editor** | A morning habit restarted at 3 pm would be missed straight away. The editor offers tomorrow instead. |
| **Shorter guide and an "Add a widget" card** | Widgets are the main way to use the app, but many people never add one |
| **Tempo Pro** (`F-34`) | A one-time purchase that unlocks extra theme colors and the Month and Year stats. Tasks, habits, every widget, reminders, the timer and export stay free. |
| **Device verification** | A full day on a physical iPhone and iPad before release |
| **Final name** | Replacing the working title |

**Not planned for v1:** accounts and sync, Android, Apple Watch, Mac, subtasks, tags, lists, priorities, attachments, sharing, manual reordering, and natural-language input.

---

## How it's built

**Stack:** Swift, SwiftUI, SwiftData, WidgetKit, App Intents, ActivityKit, UserNotifications and Swift Charts. There are no third-party dependencies.

```
App screens (SwiftUI) ─┐
Widgets (WidgetKit) ───┼──▶ Managers (Shared/Managers) ──▶ Core (pure rules)
App Intents ───────────┘            │
                                    ▼
                   Storage (SwiftData in the App Group)
                   Device-only state (App Group UserDefaults)
```

- **Views → view models → managers → `Core`.** View models are `@Observable @MainActor`. Managers hold the side effects. The app, the widgets and the widget buttons (App Intents) all use the same managers.
- **`Core`** is a Swift package of pure, synchronous rules: occurrences, statuses, duration math, the next-task rule, stats, missed queries and notification planning. It never reads the system clock; "now" and the calendar are always passed in, so every rule is tested against a fixed clock.
- **Storage is the single source of truth.** The app and the widget extension both write to one store in the App Group. Every read or write uses a fresh `ModelContext`, with no `@Query`, so each process sees the other's writes. After every write, widgets reload and notifications are rebuilt.
- **Statuses are never stored.** They're calculated from the clock, so nothing has to run at part boundaries to keep them correct.

```
Tempo/            The app: App/, Views/<Screen>/ (view + view model), Components/, Resources/
TempoWidgets/     The widget extension: one folder per widget, plus the Live Activity
Shared/           Code used by both: Managers/, Storage/, Intents/, DeepLink/, Utilities/
Packages/Core/    Pure rules and their tests
TempoTests/       App tests (managers, storage, notifications, widgets, view models)
TempoUITests/     UI tests, including accessibility audits of every screen
docs/             Spec, platform guide, progress, decisions, changelog, as-built docs
```

---

## Building and running

**Requirements:** Xcode 16 or later (developed with Xcode 27) and an iOS 18 or later simulator or device.

1. Open `Tempo.xcodeproj` and choose the **Tempo** scheme.
2. Run it on an iPhone or iPad simulator.
3. To run it on a device, set your own development team, and change the App Group `group.akumatech.tempo` in both entitlements files and in `StoreFactory.appGroup`. [`docs/platform/ios.md`](docs/platform/ios.md) §2 lists every identifier.

```bash
# Core rules
swift test --package-path Packages/Core

# App and UI tests (find a simulator with: xcrun simctl list devices available)
xcodebuild -scheme Tempo -destination 'platform=iOS Simulator,name=<iPhone>' test

# Formatting
swift format lint --recursive Tempo TempoWidgets TempoTests Shared Packages
```

---

## How this project is developed

Tempo is built **spec-first**. Every change in behavior is written into the spec before any code changes, and every judgment call is recorded with its reason.

| Document | What it's for |
|---|---|
| [`docs/SPEC.md`](docs/SPEC.md) | **What** to build: features (`F-xx`), exact rules (§5) and the build plan (`T-xx`). Platform-neutral, so it can be reused for Android. |
| [`docs/platform/ios.md`](docs/platform/ios.md) | **How** it's built on iOS: architecture, storage, widgets, notifications |
| [`docs/DOCUMENTATION.md`](docs/DOCUMENTATION.md) | What the app does **right now**, as built, feature by feature |
| [`docs/PROGRESS.md`](docs/PROGRESS.md) | The status of every task |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Why things are the way they are |
| [`docs/CHANGELOG.md`](docs/CHANGELOG.md) | Every change to the spec, with its date |

The work is done one task at a time, in order. A task is finished only when the build has no new warnings, every test passes, every acceptance item is checked, and the as-built documentation matches the code. The project has over 600 tests across the `Core` rules, the app and the UI.
