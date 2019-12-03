defmodule Advent do
  def star1 do
    {:ok, content} = File.read("priv/star1/masses.txt")
    star1(content)
  end

  def star1(input) do
    input
    |> FuelCalculator.parse_module_masses()
    |> Enum.map(&FuelCalculator.naive_mass_to_fuel/1)
    |> FuelCalculator.total_fuel()
    |> IO.puts()
  end

  def star2 do
    {:ok, content} = File.read("priv/star1/masses.txt")
    star2(content)
  end

  def star2(input) do
    input
    |> FuelCalculator.parse_module_masses()
    |> Enum.map(&FuelCalculator.mass_to_fuel/1)
    |> FuelCalculator.total_fuel()
    |> IO.puts()
  end
end
