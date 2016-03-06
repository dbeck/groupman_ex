defmodule GroupManager.Mixfile do
  use Mix.Project

  def project do
    [
      app: :group_manager,
      version: "0.0.8",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description,
      package: package,
      deps: deps
    ]
  end

  def application do
    [
      applications: [:logger, :xxhash, :ranch, :chatter],
      mod: {GroupManager, []}
    ]
  end

  defp deps do
    [
      {:xxhash, git: "https://github.com/pierresforge/erlang-xxhash"},
      {:chatter, "~> 0.0.14"}
    ]
  end

  defp description do
    """
    GroupManager is extracted from the ScaleSmall project as a standalone piece.
    This can be used independently to manage a set of nodes and coordinate a
    common goal expressed as integer ranges.
    """
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["David Beck"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/dbeck/groupman_ex/",
              "Docs" => "http://dbeck.github.io/groupman_ex/"}]
  end
end
