# Architecture Guide — ScenarioTimetableApp

## Overview

This is a **Swift/SwiftUI iOS app** using an **MVC-style architecture**.
Students import their UCL timetable, define study tasks and goals, and the app
automatically schedules study sessions into free time slots.

---

## Team Ownership Map

| Role | Owner | Folders / Files |
|------|-------|----------------|
| **Algorithm (Controller)** | Salavat | `Algorithm/`, `Tests/AlgorithmTests.swift` |
| **App Integration (Controller)** | Adry | `App/`, `Controllers/` |
| **Data & Services (Model + Controller)** | Asher | `Models/`, `Services/`, `Tests/ServiceTests.swift` |
| **UI (View)** | Josh | `Views/`, `Views/Components/` |

> **Rule:** Only edit files in your own folders. If you need something from
> another layer, discuss the interface first and agree on the protocol/contract
> before either side writes code.

---

## Folder Structure

```
ScenarioTimetableApp/
├── App/                          # App entry point & root navigation
│   ├── ScenarioTimetableApp.swift    # @main entry
│   └── ContentView.swift             # Root view / tab navigation
│
├── Models/                       # Data structures (ASHER)
│   ├── TimetableEntry.swift          # One timetable class/event
│   ├── StudyTask.swift               # A study task with deadline & priority
│   ├── StudySession.swift            # A scheduled study block (algorithm output)
│   ├── UserPreferences.swift         # User scheduling preferences
│   └── WeekSchedule.swift            # Full week representation
│
├── Services/                     # Data fetching & persistence (ASHER)
│   ├── UCLAPIService.swift           # UCL timetable API client
│   ├── PersistenceService.swift      # Local storage (SwiftData / UserDefaults)
│   └── CalendarService.swift         # iOS Calendar (EventKit) integration
│
├── Algorithm/                    # Scheduling algorithm (SALAVAT)
│   └── SchedulingAlgorithm.swift     # Core logic: tasks + free time → schedule
│
├── Controllers/                  # ViewModels / state management (ADRY)
│   ├── TimetableViewModel.swift      # Timetable data flow & state
│   └── TaskViewModel.swift           # Task CRUD & scheduling triggers
│
├── Views/                        # SwiftUI views (JOSH)
│   ├── TimetableView.swift           # Weekly timetable display
│   ├── TaskListView.swift            # List/manage study tasks
│   ├── AddTaskView.swift             # Form to create a new task
│   ├── PreferencesView.swift         # User preferences screen
│   └── Components/
│       ├── TimeSlotView.swift        # Single time block cell
│       └── TaskRowView.swift         # Single task row in list
│
└── Resources/
    └── Assets.xcassets/              # App icons, colors, images
```

---

## Data Flow

```
┌──────────────┐     ┌────────────────────┐     ┌──────────────────┐
│   Services   │────▶│   Controllers /    │────▶│     Views        │
│  (Asher)     │     │   ViewModels       │     │   (Josh)    │
│              │◀────│   (Adry)           │◀────│                  │
└──────────────┘     └────────┬───────────┘     └──────────────────┘
                              │
                              ▼
                     ┌────────────────────┐
                     │    Algorithm       │
                     │    (Salavat)       │
                     └────────────────────┘
```

1. **Services** fetch raw data (UCL API, local storage, calendar).
2. **Controllers/ViewModels** receive data, call the **Algorithm** to generate a schedule, and expose state to the Views.
3. **Views** display the state and forward user actions back to Controllers.
4. **Algorithm** is a pure function layer — takes inputs, returns a schedule. No side effects.

---

## Key Interfaces (Agree on These First)

### Models → Everyone depends on these
All layers share the model types. **Asher defines them first**, then everyone
codes against those types.

### Services → Controllers
Controllers call services to fetch/save data. Asher exposes simple async
methods; Adry calls them.

### Algorithm → Controllers
Salavat's algorithm takes `[TimetableEntry]`, `[StudyTask]`, and
`UserPreferences` as input and returns `[StudySession]`. The integrator calls
this when the user requests a schedule.

### Controllers → Views
Controllers are `@Observable` classes. The UI person binds views to controller
properties and calls controller methods for user actions.

---

## How to Work Without Conflicts

1. **Models first.** Asher defines the model structs early. Everyone else codes
   against those types.
2. **Stay in your folder.** Don't edit files outside your ownership area.
3. **Use protocols at boundaries.** If you need to mock another layer for
   testing, define a protocol (e.g., `UCLAPIServiceProtocol`) so your code
   doesn't depend on the concrete implementation.
4. **Pull before push.** Always `git pull --rebase` before pushing.
5. **Branch per feature.** Work on `feature/<your-name>/<description>` branches
   and merge via pull request.
