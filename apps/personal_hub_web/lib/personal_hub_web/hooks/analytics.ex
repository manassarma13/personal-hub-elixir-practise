defmodule PersonalHubWeb.Hooks.Analytics do
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      user_agent = get_connect_info(socket, :user_agent) || "Unknown Browser"
      PersonalHub.Analytics.track_session(self(), user_agent)
    end

    {:cont, socket}
  end
end
