defmodule PersonalHub.Focus.RoomServer do
  use GenServer

  @timeout :timer.minutes(120) # Auto-close room after 2 hours
  @focus_duration :timer.minutes(25)
  @break_duration :timer.minutes(5)

  defstruct [
    :room_id,
    :status, # :idle, :focus, :break
    :time_left,
    :participants,
    timer_ref: nil
  ]

  @type t :: %__MODULE__{
          room_id: String.t(),
          status: :idle | :focus | :break,
          time_left: integer(),
          participants: map(),
          timer_ref: reference() | nil
        }

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via(room_id))
  end

  @spec create_room(String.t()) :: DynamicSupervisor.on_start_child()
  def create_room(room_id) do
    DynamicSupervisor.start_child(
      PersonalHub.Focus.RoomSupervisor,
      {__MODULE__, room_id}
    )
  end

  @spec join(String.t(), String.t(), String.t()) :: :ok
  def join(room_id, user_id, name) do
    GenServer.call(via(room_id), {:join, user_id, name})
  end

  @spec start_timer(String.t(), :focus | :break) :: :ok
  def start_timer(room_id, type) do
    GenServer.cast(via(room_id), {:start_timer, type})
  end

  @spec stop_timer(String.t()) :: :ok
  def stop_timer(room_id) do
    GenServer.cast(via(room_id), :stop_timer)
  end

  @spec get_state(String.t()) :: map()
  def get_state(room_id) do
    GenServer.call(via(room_id), :get_state)
  end

  @spec room_exists?(String.t()) :: boolean()
  def room_exists?(room_id) do
    case Registry.lookup(PersonalHub.Focus.Registry, room_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  @spec generate_code() :: String.t()
  def generate_code do
    :rand.uniform(999_999)
    |> Integer.to_string()
    |> String.pad_leading(6, "0")
  end

  @impl true
  def init(room_id) do
    state = %__MODULE__{
      room_id: room_id,
      status: :idle,
      time_left: div(@focus_duration, 1000),
      participants: %{}
    }
    {:ok, state, @timeout}
  end

  @impl true
  def handle_call({:join, user_id, name}, _from, state) do
    new_participants = Map.put(state.participants, user_id, name)
    new_state = %{state | participants: new_participants}
    broadcast(state.room_id, {:state_updated, serialize(new_state)})
    {:reply, :ok, new_state, @timeout}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, serialize(state), state, @timeout}
  end

  @impl true
  def handle_cast({:start_timer, type}, state) do
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    
    duration = if type == :focus, do: div(@focus_duration, 1000), else: div(@break_duration, 1000)
    ref = Process.send_after(self(), :tick, 1000)

    new_state = %{state | status: type, time_left: duration, timer_ref: ref}
    broadcast(state.room_id, {:state_updated, serialize(new_state)})
    {:noreply, new_state, @timeout}
  end

  @impl true
  def handle_cast(:stop_timer, state) do
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    
    new_state = %{state | status: :idle, time_left: div(@focus_duration, 1000), timer_ref: nil}
    broadcast(state.room_id, {:state_updated, serialize(new_state)})
    {:noreply, new_state, @timeout}
  end

  @impl true
  def handle_info(:tick, state) do
    if state.time_left > 0 do
      ref = Process.send_after(self(), :tick, 1000)
      new_state = %{state | time_left: state.time_left - 1, timer_ref: ref}
      broadcast(state.room_id, {:tick, state.time_left - 1})
      {:noreply, new_state, @timeout}
    else
      new_state = %{state | status: :idle, timer_ref: nil}
      broadcast(state.room_id, {:timer_finished, state.status})
      broadcast(state.room_id, {:state_updated, serialize(new_state)})
      {:noreply, new_state, @timeout}
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  defp broadcast(room_id, message) do
    Phoenix.PubSub.broadcast(PersonalHub.PubSub, "focus:#{room_id}", message)
  end

  defp serialize(state) do
    %{
      room_id: state.room_id,
      status: state.status,
      time_left: state.time_left,
      participants: state.participants
    }
  end

  defp via(room_id) do
    {:via, Registry, {PersonalHub.Focus.Registry, room_id}}
  end
end
