defmodule Mix.Tasks.BakedBot do
  use Mix.Task

  def run(["export_version"]) do
    version = Mix.Project.config()[:version]
    File.write("VERSION", version)
  end
end
