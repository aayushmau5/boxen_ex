defmodule Boxen.MixProject do
  use Mix.Project
  
  @source_url "https://github.com/aayushmau5/boxen_ex"
  def project do
    [
      app: :boxen,
      description: "Boxify your texts for CLIs. Port of boxen library for elixir.",
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @source_url,
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
  
  defp package do
    [
      links: %{"Github" => @source_url}, 
      licenses: ["MIT"],
    ]
  end
end
