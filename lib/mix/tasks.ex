defmodule Mix.Tasks.Whiteboard.Digest do
  use Mix.Task

  def run(args) do
    Mix.Shell.IO.cmd "cd assets && npm run build"
    Mix.Shell.IO.cmd "rm -rf priv/static"
    Mix.Shell.IO.cmd "cp -r assets/build/static priv"
    :ok = Mix.Tasks.Phx.Digest.run(args)
  end
end
