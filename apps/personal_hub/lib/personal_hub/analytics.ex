defmodule PersonalHub.Analytics do
  use GenServer
  require Logger

  @name __MODULE__
  @max_history 1000

  defstruct total_sessions: 0,
            active_sessions: %{},
            historical_sessions: []

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: @name)
  end

  @doc """
  Tracks a new session for the given process PID.
  The `browser_info` typically contains the user agent.
  """
  def track_session(pid, browser_info) do
    GenServer.cast(@name, {:track_session, pid, browser_info})
  end

  @doc """
  Returns the current analytics data.
  """
  def get_stats do
    GenServer.call(@name, :get_stats)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:track_session, pid, browser_info}, state) do
    if Map.has_key?(state.active_sessions, pid) do
      {:noreply, state}
    else
      Process.monitor(pid)
      start_time = DateTime.utc_now()

      Logger.info("New session started. Browser: #{browser_info}")

      new_active =
        Map.put(state.active_sessions, pid, %{
          start_time: start_time,
          browser_info: browser_info
        })

      {:noreply, %{state | total_sessions: state.total_sessions + 1, active_sessions: new_active}}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    case Map.pop(state.active_sessions, pid) do
      {nil, _} ->
        {:noreply, state}

      {session_info, new_active} ->
        end_time = DateTime.utc_now()
        duration_seconds = DateTime.diff(end_time, session_info.start_time, :second)

        Logger.info(
          "Session ended. Duration: #{duration_seconds}s. Browser: #{session_info.browser_info}"
        )

        completed_session = %{
          start_time: session_info.start_time,
          end_time: end_time,
          duration_seconds: duration_seconds,
          browser_info: session_info.browser_info
        }

        new_history = [completed_session | state.historical_sessions] |> Enum.take(@max_history)

        {:noreply, %{state | active_sessions: new_active, historical_sessions: new_history}}
    end
  end
end
