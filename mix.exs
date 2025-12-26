defmodule Censer.MixProject do
  use Mix.Project

  def project do
    [
      app: :censer,
      version: "0.2.0",
      elixir: "~> 1.18",
      description: "Vaporize GraphQL queries into Elixir pattern matches.",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe, "~> 1.0"},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/guglielmobartelloni/censer"}
    ]
  end
end
