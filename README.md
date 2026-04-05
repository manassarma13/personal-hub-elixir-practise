# Personal Hub — Elixir Fullstack Application

A fullstack Elixir application built as an **umbrella project** using **Phoenix LiveView** for a rich, real-time UI — with **zero JavaScript frameworks** and **no database server**. All user content (posts, notes, tasks) is persisted in the browser via **localStorage**, while server-side features like multiplayer chess use Elixir's OTP primitives.

## What Is This?

A Swiss Army knife for your personal stuff — 9 features in one app:

- **Dashboard** — Overview of all features at a glance
- **Blog** — Write and publish blog posts with relative timestamps
- **Notes** — Quick notes with pin/unpin support, grid layout
- **Tasks** — Todo list with priorities (low/medium/high), statuses (todo/in-progress/done), and due dates
- **Kanban Board** — Kanban view + monthly calendar showing all tasks, posts, and notes
- **Document Viewer** — Upload and view PDF, XLSX, DOCX, PPTX files directly in the browser
- **Data Visualization** — Interactive charts (bar, line, pie, doughnut, radar, scatter, heatmap) with demo datasets and JSON upload
- **Chess** — Real-time multiplayer chess with game codes, in-game chat, powered by GenServer + PubSub
- **Typing Game** — 60-second WPM speed test with live accuracy feedback

## Architecture

This is an **umbrella project** with 2 apps:

```
personal-hub-elixir-practise/
├── apps/
│   ├── personal_hub/                  # Core business logic
│   │   └── lib/personal_hub/
│   │       ├── application.ex         # OTP supervisor (PubSub, Registry, DynamicSupervisor)
│   │       ├── chess.ex               # Chess game logic (moves, validation, check/checkmate)
│   │       ├── chess/game_server.ex   # GenServer for managing game state
│   │       └── document_parser.ex     # PDF/XLSX/DOCX/PPTX parsing with Erlang :zip/:xmerl
│   │
│   └── personal_hub_web/             # Phoenix web layer
│       ├── assets/
│       │   ├── js/app.js              # LocalStore hook (localStorage bridge)
│       │   ├── css/app.css            # Tailwind CSS v4
│       │   └── vendor/chart.js        # Chart.js 4.4.7 (vendored)
│       └── lib/personal_hub_web/
│           ├── components/            # Layouts, CoreComponents
│           ├── helpers/               # TimeHelpers (relative time formatting)
│           └── live/                  # All LiveViews
│               ├── dashboard_live.ex
│               ├── post_live/         # Blog (index + show)
│               ├── note_live/         # Notes
│               ├── task_live/         # Tasks
│               ├── kanban_live/       # Kanban + Calendar
│               ├── chess_live/        # Multiplayer chess
│               ├── document_live/     # Document viewer
│               ├── visualize_live/    # Data visualization
│               └── typing_live/       # Typing speed game
├── config/                            # Environment configs (dev, test, prod)
├── README.md
├── Project.md
└── pitch.md
```

### How It Works

```
┌─────────────────────────────────────────────────────┐
│                     Browser                         │
│                                                     │
│  localStorage ◄──► LocalStore JS Hook ◄──► LiveView │
│  (posts, notes,    (phx-hook bridge)       (Elixir) │
│   tasks)                                            │
└───────────────────────┬─────────────────────────────┘
                        │ WebSocket
┌───────────────────────▼─────────────────────────────┐
│                Phoenix Server                       │
│                                                     │
│  PubSub ──── GenServer (Chess) ──── Registry        │
│              DynamicSupervisor                      │
│              DocumentParser (zip/xmerl)             │
└─────────────────────────────────────────────────────┘
```

- **Content (Posts/Notes/Tasks)** — stored in browser localStorage, synced to LiveView via the `LocalStore` JS hook
- **Chess** — server-side GenServer processes, real-time via PubSub
- **Documents** — uploaded and parsed server-side, rendered in LiveView
- **Charts** — Chart.js driven by LiveView hooks

## Features

### Content Management (localStorage)
- **Blog Posts** — Full CRUD with publish/draft status, relative timestamps ("5m ago"), edited indicators
- **Notes** — Quick notes with pin/unpin, grid layout, relative timestamps
- **Tasks** — Status transitions (todo → in_progress → done), priority levels (low/medium/high), due dates with overdue highlighting

### Kanban Board & Calendar
- **Kanban view** — Three columns (Todo, In Progress, Done) with task counts and recent posts/notes sidebar
- **Calendar view** — Monthly grid showing tasks by due date, posts and notes by creation date, color-coded legend

### Document Viewer
- **PDF** — Native browser rendering via iframe
- **XLSX** — Parsed with Erlang `:zip` and `:xmerl`, displayed as interactive tables with sheet tabs
- **DOCX** — Text extraction from Word documents
- **PPTX** — Slide-by-slide text extraction

### Data Visualization
Interactive Chart.js charts via LiveView hook — bar, line, pie, doughnut, radar, scatter, heatmap with demo datasets and JSON upload

### Chess
Real-time multiplayer chess — GenServer + DynamicSupervisor + Registry + PubSub — with game codes and in-game chat

### Typing Game
60-second WPM speed test using ColocatedHooks (Phoenix 1.8) for real-time keystroke tracking

### OTP Patterns Used
- **GenServer** — Chess game state management
- **DynamicSupervisor** — Spawning game processes on demand
- **Registry** — Looking up game processes by game code
- **PubSub** — Broadcasting moves, chat messages, game events

## How to Run

```bash
# Install dependencies
mix setup

# Start the server
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000)

No database setup needed — content is stored in your browser's localStorage.

## Pages & Routes

| Route | Page |
|-------|------|
| `/` | Dashboard |
| `/posts` | Blog Posts |
| `/posts/:id` | Post Detail |
| `/notes` | Notes |
| `/tasks` | Tasks |
| `/kanban` | Kanban Board & Calendar |
| `/documents` | Document Viewer |
| `/visualize` | Data Visualization |
| `/chess` | Multiplayer Chess |
| `/typing` | Typing Game |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Elixir 1.19 / Erlang OTP 28 |
| Web Framework | Phoenix 1.8 |
| Real-time UI | Phoenix LiveView 1.1 |
| Styling | Tailwind CSS v4 |
| Charts | Chart.js 4.4.7 (vendored) |
| Data Storage | Browser localStorage (content) / OTP processes (chess) |
| Document Parsing | Erlang `:zip` + `:xmerl` |
| HTTP Client | Req |

## Deployment — Free Hosting

Since there's no database, deployment is very simple. Only `SECRET_KEY_BASE` is needed.

### Option 1: Fly.io (recommended)

```bash
# Install Fly CLI
curl -L https://fly.io/install.sh | sh

# Login & launch
fly auth signup
fly launch

# Set the secret
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)

# Deploy
fly deploy
```

No volumes, no database config, no migrations needed.

### Option 2: Gigalixir (free tier)

```bash
pip install gigalixir
gigalixir signup
gigalixir login
gigalixir create
git push gigalixir main
```

### Option 3: Render

Create a new **Web Service** on [render.com](https://render.com), connect your GitHub repo, and set:
- **Build Command**: `mix deps.get && mix assets.deploy && mix release`
- **Start Command**: `_build/prod/rel/personal_hub/bin/personal_hub start`
- **Environment Variable**: `SECRET_KEY_BASE`

## Development

```bash
# Run all checks before committing
mix precommit

# Run tests
mix test

# Run previously failed tests
mix test --failed
```
