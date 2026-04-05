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
    <header class="sticky top-0 z-50 bg-white border-b border-gray-200 shadow-sm">
      <div class="max-w-6xl mx-auto px-4">
        <div class="flex items-center justify-between h-14 sm:h-16">
          <a href="/" class="text-lg sm:text-xl font-bold text-gray-900 hover:text-primary transition-colors tracking-tight">
            Personal Hub
          </a>

          <nav class="hidden md:flex items-center gap-1">
            <a href="/" class="px-3 py-2 rounded-full text-sm font-medium text-gray-600 hover:bg-gray-100 transition-colors">
              Dashboard
            </a>

            <div class="relative group/content">
              <button class="flex items-center gap-1 px-3 py-2 rounded-full text-sm font-medium text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer">
                Content
                <.icon name="hero-chevron-down" class="size-3.5" />
              </button>
              <div class={[
                "absolute left-1/2 -translate-x-1/2 top-full pt-2",
                "opacity-0 invisible pointer-events-none",
                "group-hover/content:opacity-100 group-hover/content:visible group-hover/content:pointer-events-auto",
                "group-focus-within/content:opacity-100 group-focus-within/content:visible group-focus-within/content:pointer-events-auto",
                "transition-all duration-150"
              ]}>
                <div class="w-56 bg-white rounded-xl shadow-lg border border-gray-100 py-2">
                  <a href="/posts" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-document-text" class="size-5 text-gray-400" />
                    Blog Posts
                  </a>
                  <a href="/notes" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-pencil-square" class="size-5 text-gray-400" />
                    Notes
                  </a>
                  <a href="/tasks" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-clipboard-document-list" class="size-5 text-gray-400" />
                    Tasks
                  </a>
                  <a href="/kanban" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-view-columns" class="size-5 text-gray-400" />
                    Kanban Board
                  </a>
                </div>
              </div>
            </div>

            <div class="relative group/tools">
              <button class="flex items-center gap-1 px-3 py-2 rounded-full text-sm font-medium text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer">
                Tools
                <.icon name="hero-chevron-down" class="size-3.5" />
              </button>
              <div class={[
                "absolute left-1/2 -translate-x-1/2 top-full pt-2",
                "opacity-0 invisible pointer-events-none",
                "group-hover/tools:opacity-100 group-hover/tools:visible group-hover/tools:pointer-events-auto",
                "group-focus-within/tools:opacity-100 group-focus-within/tools:visible group-focus-within/tools:pointer-events-auto",
                "transition-all duration-150"
              ]}>
                <div class="w-56 bg-white rounded-xl shadow-lg border border-gray-100 py-2">
                  <a href="/documents" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-document-magnifying-glass" class="size-5 text-gray-400" />
                    Document Viewer
                  </a>
                  <a href="/visualize" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-chart-bar" class="size-5 text-gray-400" />
                    Data Viz
                  </a>
                  <a href="/chess" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-puzzle-piece" class="size-5 text-gray-400" />
                    Chess
                  </a>
                  <a href="/typing" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-command-line" class="size-5 text-gray-400" />
                    Typing Game
                  </a>
                </div>
              </div>
            </div>

            <a href="/chess" class="px-3 py-2 rounded-full text-sm font-medium text-gray-600 hover:bg-gray-100 transition-colors">
              ♟ Chess
            </a>

            <div class="relative group/create">
              <button class="flex items-center gap-1.5 ml-2 px-4 py-2 rounded-full text-sm font-medium text-white bg-primary hover:bg-primary/90 shadow-sm transition-colors cursor-pointer">
                <.icon name="hero-plus" class="size-4" />
                New
              </button>
              <div class={[
                "absolute right-0 top-full pt-2",
                "opacity-0 invisible pointer-events-none",
                "group-hover/create:opacity-100 group-hover/create:visible group-hover/create:pointer-events-auto",
                "group-focus-within/create:opacity-100 group-focus-within/create:visible group-focus-within/create:pointer-events-auto",
                "transition-all duration-150"
              ]}>
                <div class="w-56 bg-white rounded-xl shadow-lg border border-gray-100 py-2">
                  <a href="/posts/new" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-document-plus" class="size-5 text-gray-400" />
                    New Post
                  </a>
                  <a href="/notes/new" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-pencil" class="size-5 text-gray-400" />
                    New Note
                  </a>
                  <a href="/tasks/new" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors">
                    <.icon name="hero-clipboard-document-check" class="size-5 text-gray-400" />
                    New Task
                  </a>
                </div>
              </div>
            </div>
          </nav>

          <div class="md:hidden relative group/mobile">
            <button class="p-2 rounded-lg text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer">
              <.icon name="hero-bars-3" class="size-6" />
            </button>
            <div class={[
              "absolute right-0 top-full pt-2",
              "opacity-0 invisible pointer-events-none",
              "group-hover/mobile:opacity-100 group-hover/mobile:visible group-hover/mobile:pointer-events-auto",
              "group-focus-within/mobile:opacity-100 group-focus-within/mobile:visible group-focus-within/mobile:pointer-events-auto",
              "transition-all duration-150"
            ]}>
              <div class="w-64 bg-white rounded-xl shadow-lg border border-gray-100 py-2">
                <a href="/" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                  <.icon name="hero-home" class="size-5 text-gray-400" /> Dashboard
                </a>
                <div class="border-t border-gray-100 my-1"></div>
                <p class="px-4 py-1.5 text-xs font-semibold text-gray-400 uppercase">Content</p>
                <a href="/posts" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                  <.icon name="hero-document-text" class="size-5 text-gray-400" /> Blog Posts
                </a>
                <a href="/notes" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                  <.icon name="hero-pencil-square" class="size-5 text-gray-400" /> Notes
                </a>
                <a href="/tasks" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                  <.icon name="hero-clipboard-document-list" class="size-5 text-gray-400" /> Tasks
                </a>
                <a href="/kanban" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                  <.icon name="hero-view-columns" class="size-5 text-gray-400" /> Kanban Board
                </a>
                <div class="border-t border-gray-100 my-1"></div>
                <p class="px-4 py-1.5 text-xs font-semibold text-gray-400 uppercase">Tools</p>
                <a href="/documents" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                  <.icon name="hero-document-magnifying-glass" class="size-5 text-gray-400" /> Documents
                </a>
                <a href="/visualize" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                  <.icon name="hero-chart-bar" class="size-5 text-gray-400" /> Data Viz
                </a>
                <a href="/chess" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                  <.icon name="hero-puzzle-piece" class="size-5 text-gray-400" /> Chess
                </a>
                <a href="/typing" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                  <.icon name="hero-command-line" class="size-5 text-gray-400" /> Typing Game
                </a>
              </div>
            </div>
          </div>
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
