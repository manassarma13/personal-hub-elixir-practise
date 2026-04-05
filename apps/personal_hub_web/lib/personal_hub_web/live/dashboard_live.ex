defmodule PersonalHubWeb.DashboardLive do
  use PersonalHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Dashboard",
       posts_count: 0,
       published_posts_count: 0,
       notes_count: 0
     )}
  end

  @impl true
  def handle_event("ls:loaded", data, socket) do
    posts = data["posts"] || []
    notes = data["notes"] || []

    {:noreply,
     assign(socket,
       posts_count: length(posts),
       published_posts_count: Enum.count(posts, fn p -> p["published"] == true end),
       notes_count: length(notes)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
    <div id="local-store" phx-hook="LocalStore" phx-update="ignore" data-collections="posts,notes"></div>
    <div class="space-y-8">
      <div class="pt-4 sm:pt-6 pb-2">
        <h1 class="text-2xl sm:text-3xl font-bold text-gray-900 tracking-tight">Dashboard</h1>
        <p class="text-gray-500 mt-1">Your personal hub at a glance</p>
      </div>

      <div class="grid grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-5">
        <div class="bg-white rounded-2xl border border-gray-200 p-4 sm:p-6 hover:shadow-md transition-shadow">
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-50 mb-3">
            <.icon name="hero-document-text" class="size-5 text-blue-600" />
          </span>
          <h2 class="text-2xl sm:text-3xl font-bold text-gray-900">{@posts_count}</h2>
          <p class="text-sm text-gray-500 mt-1">Posts <span class="text-green-600">({@published_posts_count})</span></p>
          <.link navigate={~p"/posts"} class="inline-block mt-2 text-sm font-medium text-primary hover:underline">View &rarr;</.link>
        </div>

        <div class="bg-white rounded-2xl border border-gray-200 p-4 sm:p-6 hover:shadow-md transition-shadow">
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-amber-50 mb-3">
            <.icon name="hero-pencil-square" class="size-5 text-amber-600" />
          </span>
          <h2 class="text-2xl sm:text-3xl font-bold text-gray-900">{@notes_count}</h2>
          <p class="text-sm text-gray-500 mt-1">Notes</p>
          <.link navigate={~p"/notes"} class="inline-block mt-2 text-sm font-medium text-primary hover:underline">View &rarr;</.link>
        </div>

        <div class="bg-white rounded-2xl border border-gray-200 p-4 sm:p-6 hover:shadow-md transition-shadow">
          <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-teal-50 mb-3">
            <.icon name="hero-clipboard-document-list" class="size-5 text-teal-600" />
          </span>
          <h2 class="text-2xl sm:text-3xl font-bold text-gray-900">Tasks</h2>
          <p class="text-sm text-gray-500 mt-1">Task Manager</p>
          <.link navigate={~p"/tasks"} class="inline-block mt-2 text-sm font-medium text-primary hover:underline">View &rarr;</.link>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-3 sm:gap-5">
        <.link navigate={~p"/kanban"} class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group">
          <div class="flex items-center gap-4">
            <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-indigo-50 group-hover:bg-indigo-100 transition-colors">
              <.icon name="hero-view-columns" class="size-6 text-indigo-600" />
            </span>
            <div>
              <h3 class="font-semibold text-gray-900">Kanban Board</h3>
              <p class="text-xs text-gray-500 mt-0.5">Board view &amp; calendar</p>
            </div>
          </div>
        </.link>

        <.link navigate={~p"/documents"} class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group">
          <div class="flex items-center gap-4">
            <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-violet-50 group-hover:bg-violet-100 transition-colors">
              <.icon name="hero-document-magnifying-glass" class="size-6 text-violet-600" />
            </span>
            <div>
              <h3 class="font-semibold text-gray-900">Document Viewer</h3>
              <p class="text-xs text-gray-500 mt-0.5">PDF, XLSX, DOCX, PPTX</p>
            </div>
          </div>
        </.link>

        <.link navigate={~p"/visualize"} class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group">
          <div class="flex items-center gap-4">
            <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-emerald-50 group-hover:bg-emerald-100 transition-colors">
              <.icon name="hero-chart-bar" class="size-6 text-emerald-600" />
            </span>
            <div>
              <h3 class="font-semibold text-gray-900">Data Visualization</h3>
              <p class="text-xs text-gray-500 mt-0.5">Charts, JSON upload, demos</p>
            </div>
          </div>
        </.link>

        <.link navigate={~p"/chess"} class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group">
          <div class="flex items-center gap-4">
            <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-amber-50 group-hover:bg-amber-100 transition-colors text-2xl">
              ♟
            </span>
            <div>
              <h3 class="font-semibold text-gray-900">Chess</h3>
              <p class="text-xs text-gray-500 mt-0.5">Play against friends</p>
            </div>
          </div>
        </.link>

        <.link navigate={~p"/typing"} class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group">
          <div class="flex items-center gap-4">
            <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-sky-50 group-hover:bg-sky-100 transition-colors">
              <.icon name="hero-command-line" class="size-6 text-sky-600" />
            </span>
            <div>
              <h3 class="font-semibold text-gray-900">Typing Game</h3>
              <p class="text-xs text-gray-500 mt-0.5">WPM test, 60 seconds</p>
            </div>
          </div>
        </.link>
      </div>

      <div class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6">
        <h2 class="text-base sm:text-lg font-semibold text-gray-900 mb-3">Quick Actions</h2>
        <div class="flex flex-wrap gap-2 sm:gap-3">
          <.link navigate={~p"/posts/new"} class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors">
            <.icon name="hero-document-plus" class="size-4 text-gray-400" />
            New Post
          </.link>
          <.link navigate={~p"/notes/new"} class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors">
            <.icon name="hero-pencil" class="size-4 text-gray-400" />
            New Note
          </.link>
          <.link navigate={~p"/tasks/new"} class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors">
            <.icon name="hero-clipboard-document-check" class="size-4 text-gray-400" />
            New Task
          </.link>
          <.link navigate={~p"/documents"} class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors">
            <.icon name="hero-document-arrow-up" class="size-4 text-gray-400" />
            View Docs
          </.link>
          <.link navigate={~p"/visualize"} class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors">
            <.icon name="hero-chart-bar" class="size-4 text-gray-400" />
            Charts
          </.link>
          <.link navigate={~p"/chess"} class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors">
            ♟ Play Chess
          </.link>
          <.link navigate={~p"/typing"} class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors">
            <.icon name="hero-command-line" class="size-4 text-gray-400" />
            Typing Game
          </.link>
        </div>
      </div>
    </div>
    </Layouts.app>
    """
  end
end
