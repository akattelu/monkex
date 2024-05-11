defmodule Mix.Tasks.Mx do
  @moduledoc "Run the interpreter against a file\r\n "
  @shortdoc "Run the interpreter against a file"
  @requirements ["app.config"]

  use Mix.Task

  @impl Mix.Task
  def run([arg | _]) do
    Monkex.run(arg)
  end
end
