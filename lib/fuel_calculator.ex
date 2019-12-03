defmodule FuelCalculator do
  def parse_module_masses(input) do
    input
    |> String.split()
    |> Enum.map(&String.to_integer/1)
  end

  def total_fuel(fuel) do
    Enum.sum(fuel)
  end

  @doc """
  Convert mass to fuel.

  ## Examples

    iex> FuelCalculator.mass_to_fuel(12)
    2
    iex> FuelCalculator.mass_to_fuel(14)
    2
    iex> FuelCalculator.mass_to_fuel(1969)
    966
    iex> FuelCalculator.mass_to_fuel(100756)
    50346
    iex> FuelCalculator.mass_to_fuel(2)
    0

  """
  def mass_to_fuel(mass, total_fuel \\ 0)
  def mass_to_fuel(0, total_fuel), do: total_fuel

  def mass_to_fuel(mass, total_fuel) do
    added_fuel = max(naive_mass_to_fuel(mass), 0)
    mass_to_fuel(added_fuel, total_fuel + added_fuel)
  end

  def naive_mass_to_fuel(mass) do
    div(mass, 3) - 2
  end
end
