defmodule PersonalHubWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use PersonalHubWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header
      id="app-header"
      class="sticky top-0 z-50 bg-white border-b border-gray-200 shadow-sm [&_summary::-webkit-details-marker]:hidden [&_summary::marker]:content-none"
    >
      <div class="max-w-6xl mx-auto px-4">
        <div class="flex items-center justify-between h-14 sm:h-16">
          <a
            href="/"
            class="text-lg sm:text-xl font-bold text-gray-900 hover:text-primary transition-colors tracking-tight"
          >
            Personal Hub
          </a>

          <nav class="hidden md:flex items-center gap-1">
            <a
              href="/"
              class="px-3 py-2 rounded-full text-sm font-medium text-gray-600 hover:bg-gray-100 transition-colors"
            >
              Dashboard
            </a>

            <details class="relative group">
              <summary class="flex items-center gap-1 px-3 py-2 rounded-full text-sm font-medium text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer select-none">
                Content
                <.icon name="hero-chevron-down" class="size-3.5 group-open:rotate-180 transition-transform" />
              </summary>
              <div class="absolute left-1/2 -translate-x-1/2 top-full z-[100] pt-2 min-w-56">
                <div class="w-56 bg-white rounded-xl shadow-lg border border-gray-100 py-2">
                  <a
                    href="/posts"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-document-text" class="size-5 text-gray-400" /> Blog Posts
                  </a>
                  <a
                    href="/notes"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-pencil-square" class="size-5 text-gray-400" /> Notes
                  </a>
                  <a
                    href="/tasks"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-clipboard-document-list" class="size-5 text-gray-400" /> Tasks
                  </a>
                  <a
                    href="/kanban"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-view-columns" class="size-5 text-gray-400" /> Kanban Board
                  </a>
                </div>
              </div>
            </details>

            <details class="relative group">
              <summary class="flex items-center gap-1 px-3 py-2 rounded-full text-sm font-medium text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer select-none">
                Tools
                <.icon name="hero-chevron-down" class="size-3.5 group-open:rotate-180 transition-transform" />
              </summary>
              <div class="absolute left-1/2 -translate-x-1/2 top-full z-[100] pt-2 min-w-56">
                <div class="w-56 bg-white rounded-xl shadow-lg border border-gray-100 py-2">
                  <a
                    href="/documents"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-document-magnifying-glass" class="size-5 text-gray-400" />
                    Document Viewer
                  </a>
                  <a
                    href="/visualize"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-chart-bar" class="size-5 text-gray-400" /> Data Viz
                  </a>
                  <a
                    href="/chess"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-puzzle-piece" class="size-5 text-gray-400" /> Chess
                  </a>
                  <a
                    href="/typing"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-command-line" class="size-5 text-gray-400" /> Typing Game
                  </a>
                  <a
                    href="/drop"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-violet-600 hover:bg-violet-50 transition-colors font-medium"
                  >
                    <.icon name="hero-paper-airplane" class="size-5 text-violet-500 -rotate-45" />
                    Drop
                  </a>
                  <a
                    href="/social"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-teal-600 hover:bg-teal-50 transition-colors font-medium"
                  >
                    <.icon name="hero-megaphone" class="size-5 text-teal-500" />
                    Social Composer
                  </a>
                  <a
                    href="/habits"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-green-600 hover:bg-green-50 transition-colors font-medium"
                  >
                    <.icon name="hero-calendar-days" class="size-5 text-green-500" />
                    Habits
                  </a>
                  <a
                    href="/focus"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-rose-600 hover:bg-rose-50 transition-colors font-medium"
                  >
                    <.icon name="hero-clock" class="size-5 text-rose-500" />
                    Focus Rooms
                  </a>
                  <a
                    href="/flashcards"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-yellow-600 hover:bg-yellow-50 transition-colors font-medium"
                  >
                    <.icon name="hero-rectangle-stack" class="size-5 text-yellow-500" />
                    Flashcards
                  </a>
                  <a
                    href="/budget"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-blue-600 hover:bg-blue-50 transition-colors font-medium"
                  >
                    <.icon name="hero-banknotes" class="size-5 text-blue-500" />
                    Local Budget
                  </a>
                </div>
              </div>
            </details>

            <a
              href="/drop"
              class="px-3 py-2 rounded-full text-sm font-medium text-violet-600 hover:bg-violet-50 transition-colors"
            >
              <.icon name="hero-paper-airplane" class="size-4 inline -rotate-45 mr-0.5" /> Drop
            </a>
            <a
              href="/chess"
              class="px-3 py-2 rounded-full text-sm font-medium text-gray-600 hover:bg-gray-100 transition-colors"
            >
              ♟ Chess
            </a>

            <details class="relative group ml-2">
              <summary class="flex items-center gap-1.5 px-4 py-2 rounded-full text-sm font-medium text-white bg-primary hover:bg-primary/90 shadow-sm transition-colors cursor-pointer list-none select-none">
                <.icon name="hero-plus" class="size-4" /> New
              </summary>
              <div class="absolute right-0 top-full z-[100] pt-2 min-w-56">
                <div class="w-56 bg-white rounded-xl shadow-lg border border-gray-100 py-2">
                  <a
                    href="/posts/new"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-document-plus" class="size-5 text-gray-400" /> New Post
                  </a>
                  <a
                    href="/notes/new"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-pencil" class="size-5 text-gray-400" /> New Note
                  </a>
                  <a
                    href="/tasks/new"
                    class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                  >
                    <.icon name="hero-clipboard-document-check" class="size-5 text-gray-400" />
                    New Task
                  </a>
                </div>
              </div>
            </details>
          </nav>

          <details class="md:hidden relative group z-[100]">
            <summary class="p-2 rounded-lg text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer list-none">
              <.icon name="hero-bars-3" class="size-6" />
            </summary>
            <div class="absolute right-0 top-full pt-2 w-64">
              <div class="w-64 bg-white rounded-xl shadow-lg border border-gray-100 py-2">
                <a
                  href="/"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <.icon name="hero-home" class="size-5 text-gray-400" /> Dashboard
                </a>
                <div class="border-t border-gray-100 my-1"></div>
                <p class="px-4 py-1.5 text-xs font-semibold text-gray-400 uppercase">Content</p>
                <a
                  href="/posts"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <.icon name="hero-document-text" class="size-5 text-gray-400" /> Blog Posts
                </a>
                <a
                  href="/notes"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <.icon name="hero-pencil-square" class="size-5 text-gray-400" /> Notes
                </a>
                <a
                  href="/tasks"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <.icon name="hero-clipboard-document-list" class="size-5 text-gray-400" /> Tasks
                </a>
                <a
                  href="/kanban"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <.icon name="hero-view-columns" class="size-5 text-gray-400" /> Kanban Board
                </a>
                <div class="border-t border-gray-100 my-1"></div>
                <p class="px-4 py-1.5 text-xs font-semibold text-gray-400 uppercase">Tools</p>
                <a
                  href="/documents"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <.icon name="hero-document-magnifying-glass" class="size-5 text-gray-400" />
                  Documents
                </a>
                <a
                  href="/visualize"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <.icon name="hero-chart-bar" class="size-5 text-gray-400" /> Data Viz
                </a>
                <a
                  href="/chess"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <.icon name="hero-puzzle-piece" class="size-5 text-gray-400" /> Chess
                </a>
                <a
                  href="/typing"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50"
                >
                  <.icon name="hero-command-line" class="size-5 text-gray-400" /> Typing Game
                </a>
                <div class="border-t border-gray-100 my-1"></div>
                <a
                  href="/drop"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-violet-600 hover:bg-violet-50 font-medium"
                >
                  <.icon name="hero-paper-airplane" class="size-5 text-violet-500 -rotate-45" /> Drop
                </a>
                <a
                  href="/social"
                  class="flex items-center gap-3 px-4 py-2.5 text-sm text-teal-600 hover:bg-teal-50 font-medium"
                >
                  <.icon name="hero-megaphone" class="size-5 text-teal-500" /> Social Composer
                </a>
                <a
                  href="/habits"
                  class="flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-green-600 hover:bg-green-50 transition-colors"
                >
                  <.icon name="hero-calendar-days" class="size-5 text-green-500" /> Habits
                </a>
                <a
                  href="/focus"
                  class="flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-rose-600 hover:bg-rose-50 transition-colors"
                >
                  <.icon name="hero-clock" class="size-5 text-rose-500" /> Focus Rooms
                </a>
                <a
                  href="/flashcards"
                  class="flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-yellow-600 hover:bg-yellow-50 transition-colors"
                >
                  <.icon name="hero-rectangle-stack" class="size-5 text-yellow-500" /> Flashcards
                </a>
                <a
                  href="/budget"
                  class="flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-blue-600 hover:bg-blue-50 transition-colors"
                >
                  <.icon name="hero-banknotes" class="size-5 text-blue-500" /> Local Budget
                </a>
              </div>
            </div>
          </details>
        </div>
      </div>
    </header>

    <main class="p-4 max-w-6xl mx-auto">
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
