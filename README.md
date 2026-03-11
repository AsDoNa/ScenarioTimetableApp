# ScenarioTimetableApp

A Swift/SwiftUI iOS app that helps UCL students plan their study time by
automatically scheduling study sessions into free timetable slots.

## Features

- Import UCL timetable via API
- Define study tasks with deadlines and priorities
- Automatic study session scheduling into free time
- User preferences (study hours, break length, days off)
- iOS Calendar integration

## Architecture

**MVC** — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full
breakdown, data flow diagram, and ownership map.

## Team Ownership

| Folder | Owner | Role |
|--------|-------|------|
| `Models/`, `Services/` | Asher | Data & Services |
| `Algorithm/` | Salavat | Scheduling Algorithm |
| `Controllers/`, `App/` | Integrator | App Integration |
| `Views/` | UI | User Interface |

## Getting Started

1. Clone the repo
2. Open in Xcode (create an `.xcodeproj` / use Swift Package if not already set up)
3. Read `docs/ARCHITECTURE.md` to understand the structure
4. Work only in your assigned folders
5. Use feature branches: `feature/<your-name>/<description>`

## Git Workflow

- Always `git pull --rebase` before pushing
- One feature branch per task
- Merge via pull request
