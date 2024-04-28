defmodule Mix.Tasks.Repl do
  @moduledoc "Start the Monkex REPL"
  @shortdoc "Start the Monkex REPL"
  @requirements ["app.config"]

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    {name, _} = System.cmd("whoami", [])
    IO.puts("Hello #{name |> String.trim()}, this is MonkEx")
    IO.puts("Feel free to type in some commands!")

    Monkex.REPL.start()

    IO.puts("Bye!")
     end
end
