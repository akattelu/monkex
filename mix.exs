defmodule Monkex.MixProject do
  use Mix.Project

  def project do
    [
      app: :monkex,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Monkex.CLI],
      deps: deps()
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev}
    ]
  end
end
