# Personal Hub

A fullstack Elixir umbrella application powered by Phoenix LiveView — delivering real-time features with zero JavaScript frameworks, zero npm dependencies, and no database server.

## 1. Features

- **Drop**: Ephemeral real-time text sharing between devices via 6-digit room codes.
- **Blog**: Full CRUD with publish/draft, relative timestamps, and edit history.
- **Notes**: Quick notes with pin/unpin functionality and a responsive grid layout.
- **Tasks**: Priority levels, status transitions, and due dates with overdue alerts.
- **Kanban Board**: Three-column board view + monthly calendar with color-coded items.
- **Document Viewer**: Upload and render PDF, XLSX, DOCX, and PPTX — parsed with the Erlang stdlib.
- **Data Visualization**: Bar, line, pie, doughnut, radar, scatter, and heatmap charts.
- **Chess**: Real-time multiplayer with game codes, move validation, and in-game chat.
- **Typing Game**: 60-second WPM speed test with live accuracy tracking.
- **Dashboard**: Unified overview with stats, feature cards, and quick actions.

## 2. Tech Stack

- **Core Language**: Elixir 1.19 / Erlang OTP
- **Web Framework**: Phoenix 1.8
- **Real-time UI**: Phoenix LiveView 1.1
- **Styling**: Tailwind CSS v4 + daisyUI
- **Charts**: Chart.js 4.4.7 (vendored)
- **Data Persistence**: Browser `localStorage` and OTP in-memory processes
- **Document Parsing**: Erlang `:zip` + `:xmerl`
- **HTTP Server/Client**: Bandit (Server) / Req (Client)

## 3. Architecture

<<<<<<< HEAD
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
=======
The project adheres to the Elixir umbrella project pattern to separate concerns cleanly:

### Umbrella Structure
* **`personal_hub` (Core Logic):** Contains backend business logic and OTP (Open Telecom Platform) supervision trees. It handles server-side operations like the multiplayer chess engine, ephemeral room management, analytics tracking, and document parsing independently of web-specific code.
* **`personal_hub_web` (Web Layer):** The Phoenix web application. It handles routing, LiveView components (the UI), and real-time WebSocket communication, relying on the core `personal_hub` app for all its backend functionality.

### Data Storage & Flow (No Database)
* **Client-Side (`localStorage`):** Features like Blog, Notes, Tasks, and the Kanban Board save data directly in the user's browser using `localStorage`. A JavaScript hook (`LocalStore`) bridges this local data back to the Elixir LiveView over WebSockets.
* **Server-Side Ephemeral State (OTP Processes):** For real-time features, Elixir's concurrency primitives manage state in-memory:
  * **GenServers** manage individual game states (e.g., a chess match) or temporary rooms.
  * **PubSub** broadcasts real-time events between users.
  * **DynamicSupervisors & Registries** spin up and track new isolated processes on demand.

## 4. Tech Usage Explained

- **Elixir & OTP:** Utilized to spin up thousands of lightweight, isolated, fault-tolerant processes. Instead of storing temporary chess games or sharing rooms in a database, each instance is a living process (`GenServer`) that manages its own state and automatically cleans itself up (expires) when no longer needed.
- **Phoenix LiveView:** Allows building rich, real-time user experiences directly in Elixir. WebSockets carry diffs of HTML and user events, completely removing the need to build a distinct REST API or use heavy frontend frameworks like React or Vue.
- **Browser localStorage via Hooks:** Bypasses the need for a heavyweight database by allowing user-specific data to live entirely on the client, synced seamlessly to the LiveView state using custom Phoenix JS hooks.
- **Tailwind CSS & daisyUI:** Speeds up UI deUnified overview with stats, feature cards, and quick actions.velopment by providing utility classes and pre-built components, keeping the UI looking modern and responsive without custom CSS bloat.

## 5. Future Enhancements for "Vibe Coding" Safety

To make the app robust, maintainable, and safe for rapid iterative development (vibe coding), the following tools and practices will be implemented:

- **Linting & Code Formatting:** Integrating tools like `mix format` and `Credo` to enforce strict style guidelines, catch Elixir anti-patterns early, and ensure code consistency.
- **Code Scans (Security):** Adding `Sobelow` to detect common Phoenix security vulnerabilities, such as cross-site scripting (XSS), SQL injection, or misconfigured headers.
- **Testing:**
  - *Unit Testing:* Comprehensive `ExUnit` tests for core logic models (e.g., chess validation, parsing logic).
  - *Integration Testing:* Testing LiveView rendering and state transitions upon user interaction.
  - *End-to-End (E2E) Testing:* Utilizing tools like `Wallaby` or Cypress to simulate real user journeys across the browser.
- **CI/CD Pipelines:** Automated workflows (e.g., GitHub Actions) that run lints, code scans, and tests on every commit, ensuring that changes are safely verified before being merged.

## 6. How to Make MD Files to Build this Application

Building a complex, stateful application requires meticulous planning. Using Markdown (`.md`) files is the core planning methodology for this architecture, focusing on three fundamental pillars:

### A. Design Patterns
Markdown files are used to blueprint the design patterns *before* writing code. For example, sketching out the OTP Supervision Tree or deciding which GenServers belong under a DynamicSupervisor. We define process boundaries, pub-sub topics, and communication protocols (e.g., `handle_call` vs `handle_cast`) in plain text to ensure the system architecture is sound.

### B. Data Structures
Before implementing a feature, we use markdown to explicitly define the state representation. For example, defining the `%GameState{}` struct for Chess or the `%Room{}` struct for Drop. We write down the exact typespecs, what each key represents, and how the data will mutate over time. This acts as our single source of truth for the domain model.

<<<<<<< HEAD
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
=======
### C. Dynamic Programming & Algorithms
For complex logic, such as evaluating legal chess moves (sliding pieces, checkmate detection) or optimizing document parsing, we write out the algorithms in markdown pseudocode. Breaking down a complex problem into sub-problems (dynamic programming) in a human-readable document makes it significantly easier to translate into functional Elixir pipelines and recursive functions later.

This "Documentation-Driven Development" ensures that all edge cases, state transitions, and process lifecycles are resolved abstractly, leading to faster, more confident coding.

## 7. Real-Time Connectivity Scenario: Multiplayer Chess

To illustrate how users (nodes) connect and interact in real-time without a database, consider the multiplayer Chess and in-game chat feature:

1. **Initiation:** Player A creates a new Chess game. The Phoenix backend uses a `DynamicSupervisor` to spawn a new, isolated `GenServer` process dedicated solely to this match. The `Registry` maps a unique 6-digit room code to this specific process.
2. **Connection:** Player B enters the 6-digit code. Their LiveView process uses the `Registry` to locate the exact `GenServer` managing Player A's game and connects to it.
3. **State Management:** Both players maintain independent WebSocket connections to their own LiveView processes, but both LiveViews query the *same* backend `GenServer` to retrieve the current board state and chat history.
4. **Real-Time Updates (PubSub):** When Player A makes a move or sends a chat message, the `GenServer` validates the action and uses `Phoenix.PubSub` to broadcast an event (e.g., `"chess_move"` or `"chat_message"`) to the room's specific topic.
5. **Synchronization:** Player B's LiveView, which is subscribed to this PubSub topic, instantly receives the event, updates its local UI state, and pushes the visual changes to Player B's browser. This process happens in milliseconds, living entirely in server memory.

---

### Getting Started (Development)

```bash
# Install dependencies
mix setup

# Start the development server
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000). No database setup required.

```bashUnified overview with stats, feature cards, and quick actions.
# Compile, format, and run tests
mix precommit
```

## Deployment

**Required in production:** `SECRET_KEY_BASE` (at least 64 bytes — use `mix phx.gen.secret`).
> **What is `SECRET_KEY_BASE`?** In Phoenix, this is a critical security parameter used to cryptographically sign and encrypt cookies and other session data. Without a secure, unpredictable key, malicious actors could tamper with the session state. You must generate a unique key for your production environment to keep user connections secure.

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
