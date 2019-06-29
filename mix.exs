defmodule MiataBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :miata_bot,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssl, :inets],
      mod: {MiataBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.1"},
      {:postgrex, "~> 0.14.3"},
      {:plug_cowboy, "~> 2.0"},
      {:ring_logger, "~> 0.7.0"},
      # {:nostrum, "~> 0.3.2"},
      {:qr_code, "~> 2.0.1"},
      {:mogrify, "~> 0.7.2"},
      {:timex, "~> 3.5"},
      {:nostrum, github: "Kraigie/nostrum"}
    ]
  end
end
