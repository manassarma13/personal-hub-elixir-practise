import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

config :personal_hub_web, PersonalHubWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    case System.get_env("SECRET_KEY_BASE") do
      nil ->
        raise """
        environment variable SECRET_KEY_BASE is missing.
        Generate one: mix phx.gen.secret
        """

      key when byte_size(key) < 64 ->
        raise """
        SECRET_KEY_BASE must be at least 64 bytes (Plug cookie sessions). Got #{byte_size(key)} bytes.
        Generate a valid secret: mix phx.gen.secret
        """

      key ->
        key
    end

  # Public browser URL (scheme/host/port). Used for URL generation and
  # WebSocket/LiveView check_origin. Must match how users open the app.
  #
  # Real deploy (TLS at proxy): defaults — PHX_SCHEME=https, PHX_PUBLIC_PORT=443
  # Local Docker / plain HTTP: PHX_SCHEME=http PHX_PUBLIC_PORT=4000 PHX_HOST=localhost
  phx_host = System.get_env("PHX_HOST") || "example.com"
  phx_scheme = System.get_env("PHX_SCHEME") || "https"

  phx_public_port =
    case System.get_env("PHX_PUBLIC_PORT") do
      nil -> if(phx_scheme == "https", do: 443, else: 80)
      p -> String.to_integer(p)
    end

  check_origin =
    cond do
      System.get_env("ALLOW_ALL_ORIGINS") == "true" ->
        false

      phx_host == "localhost" ->
        # Allow random Cloudflare/Ngrok tunnels during local hosting
        false

      phx_scheme == "http" and phx_host == "127.0.0.1" ->
        ["http://127.0.0.1:#{phx_public_port}"]

      true ->
        true
    end

  config :personal_hub_web, PersonalHubWeb.Endpoint,
    url: [host: phx_host, scheme: phx_scheme, port: phx_public_port],
    check_origin: check_origin,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base,
    server: true

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :personal_hub_web, PersonalHubWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :personal_hub_web, PersonalHubWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  config :personal_hub, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")
end
