import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :med, MedWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "M8q/WfLu2RaTzCKnQuaZZl+ptCl/WKH3kYDPyoOhNdW87baBrbmMp2suLCEpynB0",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
