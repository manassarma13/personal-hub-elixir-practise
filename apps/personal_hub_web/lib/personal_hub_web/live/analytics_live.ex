defmodule PersonalHubWeb.AnalyticsLive do
  use PersonalHubWeb, :live_view
  alias PersonalHub.Analytics

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PersonalHub.PubSub, "analytics")
    end

    stats = Analytics.get_stats()
    {:ok, assign(socket, stats: stats, page_title: "Analytics Dashboard")}
  end

  @impl true
  def handle_info({:updated, stats}, socket) do
    {:noreply, assign(socket, stats: stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-8">
        <div class="flex items-end justify-between">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 tracking-tight">Analytics</h1>
            <p class="text-gray-500 mt-1">Real-time visitor insights from your home server</p>
          </div>
          <div class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-50 text-emerald-700 text-sm font-medium border border-emerald-100">
            <span class="relative flex h-2 w-2">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
            Live Monitoring Active
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="bg-white rounded-3xl border border-gray-100 p-8 shadow-sm">
            <p class="text-sm font-medium text-gray-500 uppercase tracking-wider">Active Sessions</p>
            <h2 class="text-5xl font-bold text-gray-900 mt-2">{map_size(@stats.active_sessions)}</h2>
            <p class="text-sm text-emerald-600 mt-2 font-medium">Currently connected via WebSocket</p>
          </div>

          <div class="bg-white rounded-3xl border border-gray-100 p-8 shadow-sm">
            <p class="text-sm font-medium text-gray-500 uppercase tracking-wider">Total Sessions</p>
            <h2 class="text-5xl font-bold text-gray-900 mt-2">{@stats.total_sessions}</h2>
            <p class="text-sm text-gray-400 mt-2">Since server start</p>
          </div>

          <div class="bg-white rounded-3xl border border-gray-100 p-8 shadow-sm">
            <p class="text-sm font-medium text-gray-500 uppercase tracking-wider">Average Duration</p>
            <h2 class="text-5xl font-bold text-gray-900 mt-2">
              {calculate_avg_duration(@stats.historical_sessions)}s
            </h2>
            <p class="text-sm text-gray-400 mt-2">Based on {@stats.historical_sessions |> length()} exits</p>
          </div>
        </div>

        <div class="bg-white rounded-3xl border border-gray-100 shadow-sm overflow-hidden">
          <div class="px-8 py-6 border-b border-gray-50 bg-gray-50/50">
            <h3 class="text-lg font-bold text-gray-900">Recent Historical Sessions</h3>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-xs font-semibold text-gray-400 uppercase tracking-wider">
                  <th class="px-8 py-4">Start Time</th>
                  <th class="px-8 py-4">Duration</th>
                  <th class="px-8 py-4">Browser Info</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-50">
                <%= if @stats.historical_sessions == [] do %>
                  <tr>
                    <td colspan="3" class="px-8 py-12 text-center text-gray-400 italic">
                      No completed sessions recorded yet.
                    </td>
                  </tr>
                <% end %>
                <%= for session <- @stats.historical_sessions do %>
                  <tr class="hover:bg-gray-50/50 transition-colors">
                    <td class="px-8 py-4 text-sm text-gray-600">
                      {format_time(session.start_time)}
                    </td>
                    <td class="px-8 py-4">
                      <span class="px-2.5 py-1 rounded-lg bg-gray-100 text-gray-700 text-xs font-bold font-mono">
                        {session.duration_seconds}s
                      </span>
                    </td>
                    <td class="px-8 py-4 text-xs text-gray-400 font-mono truncate max-w-md" title={session.browser_info}>
                      {session.browser_info}
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp format_time(dt) do
    Calendar.strftime(dt, "%b %d, %H:%M:%S")
  end

  defp calculate_avg_duration([]), do: 0
  defp calculate_avg_duration(history) do
    total = Enum.reduce(history, 0, fn s, acc -> acc + s.duration_seconds end)
    round(total / length(history))
  end
end
