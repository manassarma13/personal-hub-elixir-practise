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
      <div id="local-store" phx-hook="LocalStore" phx-update="ignore" data-collections="posts,notes">
      </div>
      <div class="space-y-8">
        <div class="pt-4 sm:pt-6 pb-2 flex items-end justify-between">
          <div>
            <h1 class="text-2xl sm:text-3xl font-bold text-gray-900 tracking-tight">Dashboard</h1>
            <p class="text-gray-500 mt-1">Your personal hub at a glance</p>
          </div>
          <button
            id="export-data-btn"
            phx-hook=".ExportData"
            phx-update="ignore"
            class="inline-flex items-center gap-1.5 px-3 py-1.5 sm:px-4 sm:py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-medium shadow-sm transition-colors cursor-pointer"
          >
            <.icon name="hero-arrow-down-tray" class="size-4" />
            <span class="hidden sm:inline">Download Backup</span>
            <span class="sm:hidden">Export</span>
          </button>
        </div>

        <script :type={Phoenix.LiveView.ColocatedHook} name=".ExportData">
          export default {
            mounted() {
              this.el.addEventListener("click", e => {
                const data = {};
                for (let i = 0; i < localStorage.length; i++) {
                  const key = localStorage.key(i);
                  try {
                    data[key] = JSON.parse(localStorage.getItem(key));
                  } catch(err) {
                    data[key] = localStorage.getItem(key);
                  }
                }
                const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `personal_hub_backup_${new Date().toISOString().split('T')[0]}.json`;
                document.body.appendChild(a);
                a.click();
                setTimeout(() => { document.body.removeChild(a); window.URL.revokeObjectURL(url); }, 100);
              });
            }
          }
        </script>

        <div class="grid grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-5">
          <div class="bg-white rounded-2xl border border-gray-200 p-4 sm:p-6 hover:shadow-md transition-shadow">
            <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-50 mb-3">
              <.icon name="hero-document-text" class="size-5 text-blue-600" />
            </span>
            <h2 class="text-2xl sm:text-3xl font-bold text-gray-900">{@posts_count}</h2>
            <p class="text-sm text-gray-500 mt-1">
              Posts <span class="text-green-600">({@published_posts_count})</span>
            </p>
            <.link
              navigate={~p"/posts"}
              class="inline-block mt-2 text-sm font-medium text-primary hover:underline"
            >
              View &rarr;
            </.link>
          </div>

          <div class="bg-white rounded-2xl border border-gray-200 p-4 sm:p-6 hover:shadow-md transition-shadow">
            <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-amber-50 mb-3">
              <.icon name="hero-pencil-square" class="size-5 text-amber-600" />
            </span>
            <h2 class="text-2xl sm:text-3xl font-bold text-gray-900">{@notes_count}</h2>
            <p class="text-sm text-gray-500 mt-1">Notes</p>
            <.link
              navigate={~p"/notes"}
              class="inline-block mt-2 text-sm font-medium text-primary hover:underline"
            >
              View &rarr;
            </.link>
          </div>

          <div class="bg-white rounded-2xl border border-gray-200 p-4 sm:p-6 hover:shadow-md transition-shadow">
            <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-teal-50 mb-3">
              <.icon name="hero-clipboard-document-list" class="size-5 text-teal-600" />
            </span>
            <h2 class="text-2xl sm:text-3xl font-bold text-gray-900">Tasks</h2>
            <p class="text-sm text-gray-500 mt-1">Task Manager</p>
            <.link
              navigate={~p"/tasks"}
              class="inline-block mt-2 text-sm font-medium text-primary hover:underline"
            >
              View &rarr;
            </.link>
          </div>
        </div>

        <%!-- Drop — Star Feature --%>
        <.link
          navigate={~p"/drop"}
          class="block bg-gradient-to-r from-violet-600 to-indigo-600 rounded-2xl p-5 sm:p-7 hover:shadow-lg hover:shadow-violet-200 transition-all group"
        >
          <div class="flex items-center gap-4 sm:gap-6">
            <span class="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-white/20 group-hover:bg-white/30 transition-colors">
              <.icon name="hero-paper-airplane" class="size-7 text-white -rotate-45" />
            </span>
            <div>
              <h3 class="text-xl sm:text-2xl font-bold text-white">Drop</h3>
              <p class="text-sm text-white/70 mt-0.5">
                Share text between devices instantly — no app, no signup, just a code
              </p>
            </div>
            <.icon
              name="hero-arrow-right"
              class="size-6 text-white/50 ml-auto group-hover:translate-x-1 transition-transform hidden sm:block"
            />
          </div>
        </.link>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-3 sm:gap-5">
          <.link
            navigate={~p"/kanban"}
            class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group"
          >
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

          <.link
            navigate={~p"/documents"}
            class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group"
          >
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

          <.link
            navigate={~p"/visualize"}
            class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group"
          >
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

          <.link
            navigate={~p"/chess"}
            class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group"
          >
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

          <.link
            navigate={~p"/typing"}
            class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-primary/30 transition-all group"
          >
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

          <.link
            navigate={~p"/social"}
            class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6 hover:shadow-md hover:border-teal-300 transition-all group"
          >
            <div class="flex items-center gap-4">
              <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-teal-50 group-hover:bg-teal-100 transition-colors">
                <.icon name="hero-megaphone" class="size-6 text-teal-600" />
              </span>
              <div>
                <h3 class="font-semibold text-gray-900">Social Composer</h3>
                <p class="text-xs text-gray-500 mt-0.5">Write once, post everywhere</p>
              </div>
            </div>
          </.link>
        </div>

        <div class="bg-white rounded-2xl border border-gray-200 p-5 sm:p-6">
          <h2 class="text-base sm:text-lg font-semibold text-gray-900 mb-3">Quick Actions</h2>
          <div class="flex flex-wrap gap-2 sm:gap-3">
            <.link
              navigate={~p"/posts/new"}
              class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors"
            >
              <.icon name="hero-document-plus" class="size-4 text-gray-400" /> New Post
            </.link>
            <.link
              navigate={~p"/notes/new"}
              class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors"
            >
              <.icon name="hero-pencil" class="size-4 text-gray-400" /> New Note
            </.link>
            <.link
              navigate={~p"/tasks/new"}
              class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors"
            >
              <.icon name="hero-clipboard-document-check" class="size-4 text-gray-400" /> New Task
            </.link>
            <.link
              navigate={~p"/documents"}
              class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors"
            >
              <.icon name="hero-document-arrow-up" class="size-4 text-gray-400" /> View Docs
            </.link>
            <.link
              navigate={~p"/visualize"}
              class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors"
            >
              <.icon name="hero-chart-bar" class="size-4 text-gray-400" /> Charts
            </.link>
            <.link
              navigate={~p"/chess"}
              class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors"
            >
              ♟ Play Chess
            </.link>
            <.link
              navigate={~p"/typing"}
              class="inline-flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors"
            >
              <.icon name="hero-command-line" class="size-4 text-gray-400" /> Typing Game
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
