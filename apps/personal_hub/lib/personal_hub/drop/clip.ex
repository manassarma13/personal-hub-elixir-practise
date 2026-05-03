defmodule PersonalHub.Drop.Clip do
  @enforce_keys [:id, :text, :timestamp]
  defstruct [:id, :text, :timestamp]

  @type t :: %__MODULE__{
          id: integer(),
          text: String.t(),
          timestamp: String.t()
        }

  @spec new(String.t()) :: t()
  def new(text) do
    %__MODULE__{
      id: System.unique_integer([:positive, :monotonic]),
      text: text,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
