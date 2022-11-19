defmodule Boxen.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/aayushmau5/boxen_ex"

  def project do
    [
      app: :boxen,
      description: "Boxify your texts for CLIs. Port of boxen library for elixir.",
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      source_url: @source_url,
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs() do
    [
      main: "Boxen",
      source_ref: "v#{@version}",
      source_url: @source_url
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
      licenses: ["MIT"]
    ]
  end
end
