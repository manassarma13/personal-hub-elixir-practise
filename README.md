# Personal Hub

A fullstack Elixir umbrella application powered by Phoenix LiveView — delivering 10 real-time features with zero JavaScript frameworks, zero npm dependencies, and no database server.

Content is persisted in the browser via localStorage. Server-side features like multiplayer chess and ephemeral text sharing leverage Elixir's OTP primitives (GenServer, DynamicSupervisor, Registry, PubSub) for lightweight, fault-tolerant concurrency.

## Overview

### 1. Architecture Structure (Umbrella App)
The project is split into two main applications under the `apps/` directory, adhering to the Elixir umbrella project pattern:
*   **`personal_hub` (Core Logic):** This contains all the backend business logic and OTP (Open Telecom Platform) supervision trees. It handles complex server-side operations like the multiplayer chess engine, ephemeral room management for text sharing, analytics tracking, and document parsing. It operates completely independently of any web-specific code.
*   **`personal_hub_web` (Web Layer):** This is the Phoenix web application. It handles routing, LiveView components (the UI), and real-time WebSocket communication with the browser. It relies on the core `personal_hub` app for functionality.

### 2. Data Storage & Flow (No Database)
A unique aspect of this project is that it **does not use a database** (like PostgreSQL or MySQL). Instead, it manages state in two ways:
*   **Client-Side (`localStorage`):** For features like the Blog, Notes, Tasks, and Kanban Board, the data is saved directly in the user's browser using `localStorage`. A JavaScript hook (`LocalStore`) acts as a bridge, communicating this local data back to the Elixir LiveView over WebSockets so the server can render the UI.
*   **Server-Side Ephemeral State (OTP Processes):** For real-time and multiplayer features, Elixir's concurrency primitives are used to store state in-memory:
    *   **GenServers:** Used to manage individual game states (e.g., a chess match) or temporary rooms (e.g., the "Drop" text sharing feature). Once a room expires or a game ends, the GenServer is terminated, and the data is wiped.
    *   **PubSub:** Phoenix PubSub broadcasts real-time events between different users (like a chess move or a chat message).
    *   **DynamicSupervisors & Registries:** Used to spin up new isolated processes on demand (like a new chess game) and keep track of them.

## Features

| Feature | Description | Storage |
|---------|-------------|---------|
| **Drop** | Ephemeral real-time text sharing between devices via 6-digit room codes | In-memory GenServer (auto-expires) |
| **Blog** | Full CRUD with publish/draft, relative timestamps, edit history | Browser localStorage |
| **Notes** | Quick notes with pin/unpin, responsive grid layout | Browser localStorage |
| **Tasks** | Priority levels, status transitions, due dates with overdue alerts | Browser localStorage |
| **Kanban Board** | Three-column board view + monthly calendar with color-coded items | Browser localStorage |
| **Document Viewer** | Upload and render PDF, XLSX, DOCX, PPTX — parsed with Erlang stdlib | Server-side (ephemeral) |
| **Data Visualization** | Bar, line, pie, doughnut, radar, scatter, heatmap charts via Chart.js | Server-side (ephemeral) |
| **Chess** | Real-time multiplayer with game codes, move validation, in-game chat | GenServer per game |
| **Typing Game** | 60-second WPM speed test with live accuracy tracking | Client-side |
| **Dashboard** | Unified overview with stats, feature cards, and quick actions | — |
| **Social Composer** | Write once, preview for X/LinkedIn/Instagram/Threads/Bluesky with character limits and one-click copy | Browser localStorage |

## User Journeys

### 1. The "Zero-Infrastructure" Guest
*   **Discovery:** A user follows a link (e.g. from a LinkedIn post) to the dynamic Cloudflare URL.
*   **Zero-Friction:** They land instantly on the Dashboard with no sign-up or database-driven delay.
*   **Interaction:** They play a 60-second Typing Test or join a real-time Chess room.
*   **Collaboration:** They join a **Drop** room, paste a snippet, and see it sync instantly with the owner.
*   **Privacy:** They close the tab. No account was created, and no data was harvested.

### 2. The "Private Command Center" (Owner)
*   **Initialization:** The owner starts the home server. The app is reachable globally via a secure tunnel.
*   **Organization:** They use **Notes** and **Kanban** for daily planning. All data is persisted in their local browser storage.
*   **Seamless Transfer:** They use **Drop** to move text/links between their phone and desktop without using a third-party chat app.
*   **Stateless Review:** They upload sensitive `.xlsx` or `.docx` files to the **Document Viewer** to extract text, knowing the file is never written to a persistent disk.

### 3. The "In-Memory" Interaction
*   **Stateful Gaming:** Two players join a Chess game via a code. The server spawns a unique `GameServer` process.
*   **Ephemeral Sharing:** A "Drop" room is created for a quick file/text transfer. The room auto-terminates after 10 minutes of inactivity, wiping all traces from the server's memory.
*   **Silent Monitoring:** The owner checks session stats via the server-side analytics, which tracks visitors using process monitoring instead of client-side tracking scripts.

## Architecture

```
personal-hub/
├── apps/
│   ├── personal_hub/                  # Core business logic (no web dependencies)
│   │   └── lib/personal_hub/
│   │       ├── application.ex         # OTP supervisor tree
│   │       ├── chess.ex               # Chess engine (moves, validation, checkmate)
│   │       ├── chess/game_server.ex   # GenServer per chess game
│   │       ├── analytics.ex           # GenServer: session stats (bounded history)
│   │       ├── drop/room_server.ex    # GenServer per Drop room (auto-expiry)
│   │       └── document_parser.ex     # XLSX/DOCX/PPTX via Erlang :zip + :xmerl
│   │
│   └── personal_hub_web/             # Phoenix web layer
│       ├── assets/
│       │   ├── js/app.js              # LocalStore, ChartJS hooks; header nav closes on navigate
│       │   ├── css/app.css            # Tailwind CSS v4
│       │   └── vendor/chart.js        # Chart.js 4.4.7 (vendored, no npm)
│       └── lib/personal_hub_web/
│           ├── components/            # Layouts, CoreComponents
│           ├── helpers/               # TimeHelpers (relative time formatting)
│           ├── hooks/                 # LiveView on_mount (e.g. analytics)
│           └── live/                  # LiveViews (feature modules)
├── config/                            # Environment-specific configuration
├── docker-compose.yml                 # Local prod-style run (loads .env)
├── .env.example                       # Template for SECRET_KEY_BASE, PHX_*, PORT
└── Dockerfile                         # Production-ready multi-stage build
```

### Data Flow

```
┌──────────────────────────────────────────────────────┐
│                      Browser                          │
│                                                       │
│  localStorage ◄──► LocalStore JS Hook ◄──► LiveView   │
│  (posts, notes,    (phx-hook bridge)       (Elixir)   │
│   tasks)                                              │
└────────────────────────┬──────────────────────────────┘
                         │ WebSocket
┌────────────────────────▼──────────────────────────────┐
│                 Phoenix Server                         │
│                                                        │
│  PubSub ──── GenServer (Chess/Drop/Analytics) ──── Registry │
│              DynamicSupervisor (process lifecycle)          │
│              DocumentParser (Erlang :zip + :xmerl)          │
└────────────────────────────────────────────────────────┘
```

### OTP Supervision Tree

```
PersonalHub.Supervisor
├── DNSCluster
├── Phoenix.PubSub (PersonalHub.PubSub)
├── Registry (PersonalHub.Chess.Registry)
├── DynamicSupervisor (PersonalHub.Chess.GameSupervisor)
├── Registry (PersonalHub.Drop.Registry)
├── DynamicSupervisor (PersonalHub.Drop.RoomSupervisor)
└── PersonalHub.Analytics
```

## Routes

| Route | LiveView | Feature |
|-------|----------|---------|
| `/` | `DashboardLive` | Dashboard |
| `/drop` | `DropLive.Index` | Drop (text sharing) |
| `/posts` | `PostLive.Index` | Blog posts |
| `/posts/:id` | `PostLive.Show` | Post detail |
| `/notes` | `NoteLive.Index` | Notes |
| `/tasks` | `TaskLive.Index` | Tasks |
| `/kanban` | `KanbanLive.Index` | Kanban board + calendar |
| `/documents` | `DocumentLive.Index` | Document viewer |
| `/visualize` | `VisualizeLive.Index` | Data visualization |
| `/chess` | `ChessLive.Index` | Multiplayer chess |
| `/typing` | `TypingLive.Index` | Typing game |
| `/social` | `SocialLive.Index` | Social media composer |
| `/admin/analytics` | `AnalyticsLive` | Real-time visitor analytics |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Elixir 1.19 / Erlang OTP (see `Dockerfile` pins, e.g. OTP 26.x) |
| Web Framework | Phoenix 1.8 |
| Real-time UI | Phoenix LiveView 1.1 |
| Styling | Tailwind CSS v4 + daisyUI |
| Charts | Chart.js 4.4.7 (vendored) |
| Persistence | Browser localStorage / OTP processes |
| Document Parsing | Erlang `:zip` + `:xmerl` |
| HTTP Client | Req |
| HTTP Server | Bandit |

## Getting Started

```bash
# Install dependencies
mix setup

# Start the development server
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000). No database setup required.

Optional project-root **`.env`**: `config/dev.exs` loads it so you can set `SECRET_KEY_BASE` or other vars without exporting them in the shell. Copy **`.env.example`** to **`.env`** and edit.

If **port 4000 is already in use** (e.g. Docker still running), stop the other process or run:

```bash
PORT=4001 mix phx.server
```

## Development

```bash
# Compile, format, and run tests (run before every commit)
mix precommit

# Run tests
mix test

# Run previously failed tests only
mix test --failed
```

## Deployment

**Required in production:** `SECRET_KEY_BASE` (at least 64 bytes — use `mix phx.gen.secret`).

**Recommended:** `PHX_HOST` (public hostname). For HTTP behind no TLS (e.g. local Docker), set `PHX_SCHEME=http`, `PHX_PUBLIC_PORT`, and `PORT` to match the URL users open (see **`config/runtime.exs`** and **`.env.example`**).

No database, no volumes, no migrations.

```bash
# Generate a secret
mix phx.gen.secret
```

**Docker:** build with the [Dockerfile](./Dockerfile), or from the repo root:

```bash
cp .env.example .env   # then set SECRET_KEY_BASE and any overrides
docker compose up --build
```

Refer to **`Ship.md`** (local-only; not in git if you keep it untracked) for VPS notes if you use that workflow.

## License

Private project. All rights reserved.
