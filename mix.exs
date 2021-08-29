defmodule MiataBot.MixProject do
  use Mix.Project

  @app :miata_bot

  defp commit do
    System.get_env("COMMIT") ||
      System.cmd("git", ~w"rev-parse --verify HEAD", [])
      |> elem(0)
      |> String.trim()
  end

  def project do
    [
      app: @app,
      commit: commit(),
      version: "0.2.1",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [{@app, release()}]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MiataBot.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:cowlib, "~> 2.11", override: true},
      {:gun, "~> 1.3", override: true},
      {:ecto_sql, "~> 3.7"},
      {:postgrex, "~> 0.15"},
      {:hackney, "~> 1.17"},
      {:jason, "~> 1.0"},
      {:ring_logger, "~> 0.8"},
      {:tesla, "~> 1.4"},
      {:timex, "~> 3.7"},
      {:phoenix_pubsub, "~> 2.0"},
      {:nostrum,
       github: "kraigie/nostrum", ref: "c0c872e880f3af360167179f66df72695c1f051e", override: true},
      # {:quarrel, path: "../quarrel"}
      {:quarrel, "~> 0.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp release do
    [
      include_executables_for: [:unix],
      applications: [runtime_tools: :permanent],
      steps: [:assemble],
      strip_beams: [keep: ["Docs"]],
      cookie: "aHR0cHM6Ly9kaXNjb3JkLmdnL25tOENFVDJNc1A="
    ]
  end
end
