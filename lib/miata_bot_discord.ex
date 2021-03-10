defmodule MiataBotDiscord do
  if Mix.env() == :prod do
    @api Nostrum.Api
  else
    @api MiataBotDiscord.FakeAPI
  end

  @doc "returns the module implementing all of Nostrums functions"
  def api, do: @api
end
