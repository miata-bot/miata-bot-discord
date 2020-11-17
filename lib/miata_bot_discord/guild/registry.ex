defmodule MiataBotDiscord.Guild.Registry do
  @moduledoc "Wrapper around Elixir.Registry to track names of stages in a guild"

  @doc false
  def child_spec(%Nostrum.Struct.Guild{id: id}) do
    Registry.child_spec(name: Module.concat(__MODULE__, "#{id}"), keys: :unique, id: id)
  end

  @doc "Dynamic name generation"
  def via(%Nostrum.Struct.Guild{id: id}, module) do
    {:via, Registry, {Module.concat(__MODULE__, "#{id}"), module}}
  end

  def via(id, module) do
    {:via, Registry, {Module.concat(__MODULE__, "#{id}"), module}}
  end
end
