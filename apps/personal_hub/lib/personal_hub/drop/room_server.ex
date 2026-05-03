defmodule PersonalHub.Drop.RoomServer do
  use GenServer

  alias PersonalHub.Drop.Clip

  @timeout :timer.minutes(10)
  @max_clips 50

  defstruct [:room_id, clips: []]

  @type t :: %__MODULE__{
          room_id: String.t(),
          clips: [Clip.t()]
        }

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via(room_id))
  end

  @spec create_room(String.t()) :: DynamicSupervisor.on_start_child()
  def create_room(room_id) do
    DynamicSupervisor.start_child(
      PersonalHub.Drop.RoomSupervisor,
      {__MODULE__, room_id}
    )
  end

  @spec add_clip(String.t(), String.t()) :: :ok
  def add_clip(room_id, text) do
    GenServer.call(via(room_id), {:add_clip, text})
  end

  @spec get_clips(String.t()) :: [Clip.t()]
  def get_clips(room_id) do
    GenServer.call(via(room_id), :get_clips)
  end

  @spec delete_clip(String.t(), integer()) :: :ok
  def delete_clip(room_id, clip_id) do
    GenServer.call(via(room_id), {:delete_clip, clip_id})
  end

  @spec room_exists?(String.t()) :: boolean()
  def room_exists?(room_id) do
    case Registry.lookup(PersonalHub.Drop.Registry, room_id) do
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
    {:ok, %__MODULE__{room_id: room_id}, @timeout}
  end

  @impl true
  def handle_call({:add_clip, text}, _from, state) do
    clip = Clip.new(text)
    clips = [clip | state.clips] |> Enum.take(@max_clips)
    new_state = %{state | clips: clips}

    broadcast(state.room_id, {:clip_added, clip})
    {:reply, :ok, new_state, @timeout}
  end

  @impl true
  def handle_call(:get_clips, _from, state) do
    {:reply, state.clips, state, @timeout}
  end

  @impl true
  def handle_call({:delete_clip, clip_id}, _from, state) do
    clips = Enum.reject(state.clips, fn c -> c.id == clip_id end)
    new_state = %{state | clips: clips}

    broadcast(state.room_id, {:clip_deleted, clip_id})
    {:reply, :ok, new_state, @timeout}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  defp broadcast(room_id, message) do
    Phoenix.PubSub.broadcast(PersonalHub.PubSub, "drop:#{room_id}", message)
  end

  defp via(room_id) do
    {:via, Registry, {PersonalHub.Drop.Registry, room_id}}
  end
end
