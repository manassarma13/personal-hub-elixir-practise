defmodule PersonalHub.Analytics do
  use GenServer
  require Logger

  @name __MODULE__
  @max_history 1000

  defmodule Session do
    defstruct [:start_time, :browser_info]
  end

  defmodule CompletedSession do
    defstruct [:start_time, :end_time, :duration_seconds, :browser_info]
  end

  defstruct total_sessions: 0,
            active_sessions: %{},
            historical_sessions: []

  @type t :: %__MODULE__{
          total_sessions: non_neg_integer(),
          active_sessions: %{pid() => Session.t()},
          historical_sessions: [CompletedSession.t()]
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: @name)
  end

  @spec track_session(pid(), String.t()) :: :ok
  def track_session(pid, browser_info) do
    GenServer.cast(@name, {:track_session, pid, browser_info})
  end

  @spec get_stats() :: t()
  def get_stats do
    GenServer.call(@name, :get_stats)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_cast({:track_session, pid, browser_info}, state) do
    if Map.has_key?(state.active_sessions, pid) do
      {:noreply, state}
    else
      Process.monitor(pid)

      Logger.info("New session started. Browser: #{browser_info}")

      session = %Session{start_time: DateTime.utc_now(), browser_info: browser_info}
      new_active = Map.put(state.active_sessions, pid, session)

      new_state = %{state | total_sessions: state.total_sessions + 1, active_sessions: new_active}
      broadcast(new_state)
      {:noreply, new_state}
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

      {session, new_active} ->
        end_time = DateTime.utc_now()
        duration_seconds = DateTime.diff(end_time, session.start_time, :second)

        Logger.info("Session ended. Duration: #{duration_seconds}s. Browser: #{session.browser_info}")

        completed = %CompletedSession{
          start_time: session.start_time,
          end_time: end_time,
          duration_seconds: duration_seconds,
          browser_info: session.browser_info
        }

        new_history = [completed | state.historical_sessions] |> Enum.take(@max_history)
        new_state = %{state | active_sessions: new_active, historical_sessions: new_history}
        broadcast(new_state)
        {:noreply, new_state}
    end
  end

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(PersonalHub.PubSub, "analytics", {:updated, state})
  end
end
