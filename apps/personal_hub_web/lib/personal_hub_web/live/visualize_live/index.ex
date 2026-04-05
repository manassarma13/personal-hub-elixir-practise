defmodule PersonalHubWeb.VisualizeLive.Index do
  use PersonalHubWeb, :live_view

  @demo_datasets %{
    "sales" => %{
      name: "Quarterly Sales",
      type: "bar",
      data: %{
        labels: ["Q1 2024", "Q2 2024", "Q3 2024", "Q4 2024", "Q1 2025", "Q2 2025"],
        datasets: [
          %{label: "Revenue ($K)", data: [120, 190, 170, 240, 210, 280], backgroundColor: "rgba(255, 56, 92, 0.6)"},
          %{label: "Expenses ($K)", data: [80, 110, 130, 150, 120, 160], backgroundColor: "rgba(100, 116, 139, 0.4)"}
        ]
      }
    },
    "market" => %{
      name: "Market Share",
      type: "pie",
      data: %{
        labels: ["Product A", "Product B", "Product C", "Product D", "Others"],
        datasets: [
          %{
            data: [35, 25, 20, 12, 8],
            backgroundColor: [
              "rgba(255, 56, 92, 0.7)",
              "rgba(59, 130, 246, 0.7)",
              "rgba(16, 185, 129, 0.7)",
              "rgba(245, 158, 11, 0.7)",
              "rgba(148, 163, 184, 0.5)"
            ]
          }
        ]
      }
    },
    "temperature" => %{
      name: "Temperature Trends",
      type: "line",
      data: %{
        labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        datasets: [
          %{label: "New York (°C)", data: [-1, 0, 5, 12, 18, 23, 26, 25, 21, 14, 8, 2], borderColor: "rgba(255, 56, 92, 0.8)", fill: false, tension: 0.3},
          %{label: "London (°C)", data: [5, 5, 7, 10, 13, 16, 18, 18, 15, 11, 8, 5], borderColor: "rgba(59, 130, 246, 0.8)", fill: false, tension: 0.3},
          %{label: "Tokyo (°C)", data: [6, 6, 10, 15, 20, 23, 27, 28, 24, 18, 13, 8], borderColor: "rgba(16, 185, 129, 0.8)", fill: false, tension: 0.3}
        ]
      }
    },
    "population" => %{
      name: "Population by Region",
      type: "doughnut",
      data: %{
        labels: ["Asia", "Africa", "Europe", "Americas", "Oceania"],
        datasets: [
          %{
            data: [4700, 1400, 750, 1030, 45],
            backgroundColor: [
              "rgba(255, 56, 92, 0.7)",
              "rgba(245, 158, 11, 0.7)",
              "rgba(59, 130, 246, 0.7)",
              "rgba(16, 185, 129, 0.7)",
              "rgba(139, 92, 246, 0.7)"
            ]
          }
        ]
      }
    },
    "performance" => %{
      name: "Team Performance",
      type: "radar",
      data: %{
        labels: ["Speed", "Quality", "Communication", "Innovation", "Reliability", "Teamwork"],
        datasets: [
          %{label: "Team Alpha", data: [90, 85, 78, 92, 88, 95], borderColor: "rgba(255, 56, 92, 0.8)", backgroundColor: "rgba(255, 56, 92, 0.1)"},
          %{label: "Team Beta", data: [75, 92, 88, 70, 95, 80], borderColor: "rgba(59, 130, 246, 0.8)", backgroundColor: "rgba(59, 130, 246, 0.1)"}
        ]
      }
    },
    "scatter" => %{
      name: "Height vs Weight",
      type: "scatter",
      data: %{
        datasets: [
          %{
            label: "Participants",
            data: [
              %{x: 160, y: 55}, %{x: 165, y: 62}, %{x: 170, y: 68}, %{x: 175, y: 72},
              %{x: 180, y: 80}, %{x: 155, y: 50}, %{x: 168, y: 65}, %{x: 172, y: 70},
              %{x: 178, y: 78}, %{x: 182, y: 85}, %{x: 162, y: 58}, %{x: 174, y: 74},
              %{x: 169, y: 67}, %{x: 176, y: 76}, %{x: 185, y: 90}
            ],
            backgroundColor: "rgba(255, 56, 92, 0.6)"
          }
        ]
      }
    },
    "heatmap" => %{
      name: "Weekly Activity Heatmap",
      type: "heatmap",
      data: %{
        rows: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        cols: ["6am", "8am", "10am", "12pm", "2pm", "4pm", "6pm", "8pm", "10pm"],
        values: [
          [2, 5, 8, 6, 7, 4, 3, 2, 1],
          [3, 6, 9, 7, 8, 5, 4, 3, 2],
          [1, 4, 7, 8, 9, 6, 5, 4, 2],
          [2, 5, 8, 7, 6, 5, 3, 2, 1],
          [4, 7, 9, 8, 7, 3, 2, 1, 1],
          [1, 2, 3, 4, 3, 5, 7, 8, 6],
          [1, 1, 2, 3, 2, 4, 6, 7, 5]
        ]
      }
    }
  }

  @chart_types [
    {"bar", "Bar Chart"},
    {"line", "Line Chart"},
    {"pie", "Pie Chart"},
    {"doughnut", "Doughnut Chart"},
    {"radar", "Radar Chart"},
    {"scatter", "Scatter Plot"},
    {"heatmap", "Heatmap"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Data Visualization")
     |> assign(chart_types: @chart_types)
     |> assign(demo_keys: Map.keys(@demo_datasets) |> Enum.sort())
     |> assign(selected_demo: nil)
     |> assign(selected_type: nil)
     |> assign(chart_data: nil)
     |> assign(json_input: "")
     |> assign(json_error: nil)
     |> assign(source: nil)}
  end

  @impl true
  def handle_event("load_demo", %{"key" => key}, socket) do
    dataset = Map.fetch!(@demo_datasets, key)

    {:noreply,
     socket
     |> assign(selected_demo: key)
     |> assign(selected_type: dataset.type)
     |> assign(chart_data: dataset.data)
     |> assign(source: :demo)
     |> assign(json_error: nil)
     |> push_chart(dataset.type, dataset.data)}
  end

  @impl true
  def handle_event("change_type", %{"type" => type}, socket) do
    if socket.assigns.chart_data && type != "heatmap" do
      {:noreply,
       socket
       |> assign(selected_type: type)
       |> push_chart(type, socket.assigns.chart_data)}
    else
      {:noreply, assign(socket, selected_type: type)}
    end
  end

  @impl true
  def handle_event("update_json", %{"json" => json}, socket) do
    {:noreply, assign(socket, json_input: json)}
  end

  @impl true
  def handle_event("parse_json", %{"json" => json}, socket) do
    case Jason.decode(json) do
      {:ok, parsed} when is_map(parsed) ->
        type = socket.assigns.selected_type || "bar"
        chart_data = normalize_chart_data(parsed)

        if type == "heatmap" do
          {:noreply,
           socket
           |> assign(chart_data: chart_data)
           |> assign(source: :json)
           |> assign(json_error: nil)
           |> assign(selected_type: "heatmap")}
        else
          {:noreply,
           socket
           |> assign(chart_data: chart_data)
           |> assign(source: :json)
           |> assign(json_error: nil)
           |> assign(selected_type: type)
           |> push_chart(type, chart_data)}
        end

      {:ok, _} ->
        {:noreply, assign(socket, json_error: "JSON must be an object with labels and datasets")}

      {:error, _} ->
        {:noreply, assign(socket, json_error: "Invalid JSON format")}
    end
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply,
     socket
     |> assign(selected_demo: nil)
     |> assign(selected_type: nil)
     |> assign(chart_data: nil)
     |> assign(json_input: "")
     |> assign(json_error: nil)
     |> assign(source: nil)
     |> push_event("destroy-chart", %{})}
  end

  defp push_chart(socket, _type, nil), do: socket

  defp push_chart(socket, type, data) do
    push_event(socket, "render-chart", %{type: type, data: data})
  end

  defp normalize_chart_data(parsed) do
    keys = Map.keys(parsed)
    str_keys = for key <- keys, into: %{}, do: {key, parsed[key]}
    atom_keys = for {k, v} <- str_keys, into: %{}, do: {String.to_atom(k), v}

    cond do
      Map.has_key?(atom_keys, :labels) and Map.has_key?(atom_keys, :datasets) ->
        atom_keys

      Map.has_key?(atom_keys, :rows) and Map.has_key?(atom_keys, :cols) and Map.has_key?(atom_keys, :values) ->
        atom_keys

      true ->
        atom_keys
    end
  end

  defp demo_info(key), do: Map.get(@demo_datasets, key)

  defp heatmap_color(value, max_val) do
    intensity = if max_val > 0, do: value / max_val, else: 0

    cond do
      intensity < 0.2 -> "bg-green-100 text-green-800"
      intensity < 0.4 -> "bg-green-200 text-green-900"
      intensity < 0.6 -> "bg-yellow-200 text-yellow-900"
      intensity < 0.8 -> "bg-orange-300 text-orange-900"
      true -> "bg-red-400 text-white"
    end
  end

  defp max_heatmap_value(%{values: values}) do
    values |> List.flatten() |> Enum.max(fn -> 1 end)
  end

  defp max_heatmap_value(_), do: 1

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
    <div class="max-w-5xl mx-auto space-y-6">
      <.link navigate={~p"/"} class="inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-900 transition-colors">
        <.icon name="hero-arrow-left" class="size-4" />
        Dashboard
      </.link>

      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-semibold text-gray-900">Data Visualization</h1>
        <%= if @chart_data do %>
          <button phx-click="clear" class="px-4 py-2 rounded-xl text-sm font-medium text-gray-600 border border-gray-200 hover:bg-gray-50 transition-colors">
            Clear
          </button>
        <% end %>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="lg:col-span-1 space-y-4">
          <div class="bg-white border border-gray-200 rounded-2xl p-5">
            <h3 class="text-sm font-semibold text-gray-900 mb-3">Demo Datasets</h3>
            <div class="space-y-2">
              <%= for key <- @demo_keys do %>
                <% info = demo_info(key) %>
                <button
                  phx-click="load_demo"
                  phx-value-key={key}
                  class={[
                    "w-full text-left px-3 py-2.5 rounded-xl text-sm font-medium transition-colors",
                    if(@selected_demo == key,
                      do: "bg-primary/10 text-primary",
                      else: "text-gray-700 hover:bg-gray-50")
                  ]}
                >
                  <div class="flex justify-between items-center">
                    <span>{info.name}</span>
                    <span class="text-xs text-gray-400 uppercase">{info.type}</span>
                  </div>
                </button>
              <% end %>
            </div>
          </div>

          <div class="bg-white border border-gray-200 rounded-2xl p-5">
            <h3 class="text-sm font-semibold text-gray-900 mb-3">Chart Type</h3>
            <div class="grid grid-cols-2 gap-2">
              <%= for {type, label} <- @chart_types do %>
                <button
                  phx-click="change_type"
                  phx-value-type={type}
                  class={[
                    "px-3 py-2 rounded-lg text-xs font-medium transition-colors",
                    if(@selected_type == type,
                      do: "bg-primary text-white",
                      else: "bg-gray-50 text-gray-600 hover:bg-gray-100")
                  ]}
                >
                  {label}
                </button>
              <% end %>
            </div>
          </div>

          <div class="bg-white border border-gray-200 rounded-2xl p-5">
            <h3 class="text-sm font-semibold text-gray-900 mb-3">Upload JSON Data</h3>
            <form phx-submit="parse_json" class="space-y-3">
              <textarea
                name="json"
                rows="6"
                value={@json_input}
                phx-keyup="update_json"
                phx-value-json=""
                placeholder={"{\n  \"labels\": [\"A\", \"B\", \"C\"],\n  \"datasets\": [{\n    \"label\": \"My Data\",\n    \"data\": [10, 20, 30]\n  }]\n}"}
                class="w-full px-3 py-2 bg-white border border-gray-300 rounded-lg text-gray-900 text-xs font-mono placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary resize-y"
              ></textarea>
              <%= if @json_error do %>
                <p class="text-xs text-red-600">{@json_error}</p>
              <% end %>
              <button type="submit" class="w-full px-3 py-2 rounded-xl text-xs font-medium text-white bg-primary hover:bg-primary/90 transition-colors">
                Render JSON
              </button>
            </form>
          </div>
        </div>

        <div class="lg:col-span-2">
          <div class="bg-white border border-gray-200 rounded-2xl p-6 min-h-[400px] flex items-center justify-center">
            <%= if @chart_data == nil do %>
              <div class="text-center space-y-3">
                <div class="mx-auto w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center">
                  <.icon name="hero-chart-bar" class="size-8 text-gray-400" />
                </div>
                <p class="text-sm text-gray-500">Select a demo dataset or upload JSON to get started</p>
              </div>
            <% else %>
              <%= if @selected_type == "heatmap" do %>
                <div class="w-full">
                  <h3 class="text-sm font-semibold text-gray-900 mb-4">
                    <%= if @selected_demo do %>
                      {demo_info(@selected_demo).name}
                    <% else %>
                      Heatmap
                    <% end %>
                  </h3>
                  <div class="overflow-x-auto">
                    <table class="w-full">
                      <thead>
                        <tr>
                          <th class="p-2"></th>
                          <%= for col <- Map.get(@chart_data, :cols, []) do %>
                            <th class="p-2 text-xs text-gray-500 font-medium">{col}</th>
                          <% end %>
                        </tr>
                      </thead>
                      <tbody>
                        <%= for {row_label, row_idx} <- Enum.with_index(Map.get(@chart_data, :rows, [])) do %>
                          <tr>
                            <td class="p-2 text-xs text-gray-500 font-medium text-right">{row_label}</td>
                            <%= for {val, _col_idx} <- Enum.with_index(Enum.at(Map.get(@chart_data, :values, []), row_idx, [])) do %>
                              <td class={["p-2 text-center text-xs font-semibold rounded-md", heatmap_color(val, max_heatmap_value(@chart_data))]}>
                                {val}
                              </td>
                            <% end %>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                  <div class="flex items-center justify-center gap-2 mt-4 text-xs text-gray-500">
                    <span>Low</span>
                    <div class="flex gap-0.5">
                      <div class="w-6 h-3 bg-green-100 rounded-sm"></div>
                      <div class="w-6 h-3 bg-green-200 rounded-sm"></div>
                      <div class="w-6 h-3 bg-yellow-200 rounded-sm"></div>
                      <div class="w-6 h-3 bg-orange-300 rounded-sm"></div>
                      <div class="w-6 h-3 bg-red-400 rounded-sm"></div>
                    </div>
                    <span>High</span>
                  </div>
                </div>
              <% else %>
                <div class="w-full">
                  <canvas id="chart-canvas" phx-hook="ChartJS" phx-update="ignore" class="w-full"></canvas>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    </Layouts.app>
    """
  end
end
