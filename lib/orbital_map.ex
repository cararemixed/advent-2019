defmodule OrbitalMap do
  @moduledoc """
  Parse and manipulate relations of orbital bodies.

  ## Example: transitive orbits

    iex> orbits = "COM)B\\nB)C\\nC)D\\nD)E\\nE)F\\nB)G\\nG)H\\nD)I\\nE)J\\nJ)K\\nK)L"
    iex> map = OrbitalMap.parse_chart(orbits)
    iex> map |> OrbitalMap.compute_transitive_orbits |> MapSet.size
    42

  ## Example: path finding

    iex> orbits = "COM)B\\nB)C\\nC)D\\nD)E\\nE)F\\nB)G\\nG)H\\nD)I\\nE)J\\nJ)K\\nK)L\\nK)YOU\\nI)SAN"
    iex> map = OrbitalMap.parse_chart(orbits)
    iex> map |> OrbitalMap.minimum_transfer_cost("YOU", "SAN")
    4

  """

  def parse_chart(input) do
    input
    |> String.split()
    |> Enum.map(&(String.split(&1, ")") |> List.to_tuple()))
    |> Enum.reduce(%{}, fn {body, satellite}, orbits ->
      orbits
      |> Map.update(body, MapSet.new([satellite]), &MapSet.put(&1, satellite))
    end)
  end

  def minimum_transfer_cost(orbital_map, start, target) do
    current_orbit = find_orbit(orbital_map, start)
    target_orbit = find_orbit(orbital_map, target)
    costs = count_transfers(%{}, orbital_map, current_orbit, 0)
    costs[target_orbit]
  end

  def compute_transitive_orbits(orbital_map) do
    transitive_orbits(orbital_map, ["COM"], MapSet.new())
  end

  defp find_orbit(orbital_map, object) do
    orbit =
      orbital_map
      |> Enum.find(fn {_, objects} ->
        MapSet.member?(objects, object)
      end)

    case orbit do
      nil -> nil
      {object, _} -> object
    end
  end

  defp count_transfers(costs, orbital_map, current, cost) do
    if cost < costs[current] do
      local_transfers(orbital_map, current)
      |> Enum.reduce(Map.put(costs, current, cost), fn transfer, costs ->
        count_transfers(costs, orbital_map, transfer, cost + 1)
      end)
    else
      costs
    end
  end

  defp local_transfers(orbital_map, object) do
    satellites = Map.get(orbital_map, object, []) |> Enum.to_list()

    case find_orbit(orbital_map, object) do
      nil -> satellites
      object -> [object | satellites]
    end
  end

  defp transitive_orbits(orbital_map, [current | _] = bodies, orbits) do
    satellites = Map.get(orbital_map, current, [])

    orbits =
      for satellite <- satellites, body <- bodies, into: orbits do
        {body, satellite}
      end

    satellites
    |> Enum.reduce(orbits, fn next_body, orbits ->
      transitive_orbits(orbital_map, [next_body | bodies], orbits)
    end)
  end
end
