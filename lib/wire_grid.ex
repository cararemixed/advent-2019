defmodule WireGrid do
  defmodule Tracer do
    defstruct grid: %{},
              position: {0, 0},
              delay: 1

    def mark(tracer, {_, 0}), do: tracer

    def mark(tracer, {dir, n}) do
      new_pos = move_one(dir, tracer.position)

      %{
        tracer
        | delay: tracer.delay + 1,
          position: new_pos,
          grid: tracer.grid |> Map.put_new(new_pos, tracer.delay)
      }
      |> mark({dir, n - 1})
    end

    defp move_one(:right, {x, y}), do: {x + 1, y}
    defp move_one(:left, {x, y}), do: {x - 1, y}
    defp move_one(:up, {x, y}), do: {x, y + 1}
    defp move_one(:down, {x, y}), do: {x, y - 1}
  end

  def route_wire(input) do
    tracer =
      input
      |> String.split(",")
      |> Stream.map(&to_vector/1)
      |> Enum.reduce(%Tracer{}, fn vector, tracer ->
        Tracer.mark(tracer, vector)
      end)

    tracer.grid
  end

  @doc """
  Find the distance of the nearest crossing of the
  wires from the same origin.

  ## Example

    iex> grid1 = WireGrid.route_wire("R75,D30,R83,U83,L12,D49,R71,U7,L72")
    iex> grid2 = WireGrid.route_wire("U62,R66,U55,R34,D71,R55,D58,R83")
    iex> WireGrid.closest_crossing(grid1, grid2)
    159

    iex> grid1 = WireGrid.route_wire("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51")
    iex> grid2 = WireGrid.route_wire("U98,R91,D20,R16,D67,R40,U7,R15,U6,R7")
    iex> WireGrid.closest_crossing(grid1, grid2)
    135

  """
  def closest_crossing(grid1, grid2) do
    for pos <- Map.keys(grid1), Map.has_key?(grid2, pos) do
      {x, y} = pos
      abs(x) + abs(y)
    end
    |> Enum.min()
  end

  @doc """
  Find the number of steps both wires must take to
  reach their first crossing.

  ## Example

    iex> grid1 = WireGrid.route_wire("R75,D30,R83,U83,L12,D49,R71,U7,L72")
    iex> grid2 = WireGrid.route_wire("U62,R66,U55,R34,D71,R55,D58,R83")
    iex> WireGrid.steps_to_crossing(grid1, grid2)
    610

    iex> grid1 = WireGrid.route_wire("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51")
    iex> grid2 = WireGrid.route_wire("U98,R91,D20,R16,D67,R40,U7,R15,U6,R7")
    iex> WireGrid.steps_to_crossing(grid1, grid2)
    410

  """
  def steps_to_crossing(grid1, grid2) do
    for {pos, steps1} <- grid1, Map.has_key?(grid2, pos) do
      steps1 + Map.get(grid2, pos)
    end
    |> Enum.min()
  end

  defp to_vector(<<"R", magnitude::binary>>) do
    {:right, String.to_integer(magnitude)}
  end

  defp to_vector(<<"L", magnitude::binary>>) do
    {:left, String.to_integer(magnitude)}
  end

  defp to_vector(<<"U", magnitude::binary>>) do
    {:up, String.to_integer(magnitude)}
  end

  defp to_vector(<<"D", magnitude::binary>>) do
    {:down, String.to_integer(magnitude)}
  end
end
