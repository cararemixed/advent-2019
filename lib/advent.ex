defmodule Advent do
  def star1 do
    {:ok, input} = File.read("priv/day1/masses.txt")
    input
    |> FuelCalculator.parse_module_masses()
    |> Enum.map(&FuelCalculator.naive_mass_to_fuel/1)
    |> FuelCalculator.total_fuel()
  end

  def star2 do
    {:ok, input} = File.read("priv/day1/masses.txt")
    input
    |> FuelCalculator.parse_module_masses()
    |> Enum.map(&FuelCalculator.mass_to_fuel/1)
    |> FuelCalculator.total_fuel()
  end

  def star3 do
    {:ok, input} = File.read("priv/day2/program1.txt")
    Intcode.load_program(input)
    |> Intcode.poke(1, 12)
    |> Intcode.poke(2, 2)
    |> Intcode.run()
    |> Intcode.peek(0)
  end

  def star4 do
    {:ok, input} = File.read("priv/day2/program1.txt")
    initial = Intcode.load_program(input)

    eval = fn intcode, operand, operator ->
      intcode
      |> Intcode.poke(1, operand)
      |> Intcode.poke(2, operator)
      |> Intcode.run()
      |> Intcode.peek(0)
    end

    try do
      for operand <- 0..99,
          operator <- 0..99,
          19_690_720 == eval.(initial, operand, operator),
          do: throw({operand, operator})

      raise "no answer found"
    catch
      {noun, verb} -> 100 * noun + verb
    end
  end

  def star5 do
    {:ok, input} = File.read("priv/day3/wires.txt")
    [wire1, wire2 | _] = String.split(input, "\n")
    grid1 = WireGrid.route_wire(wire1)
    grid2 = WireGrid.route_wire(wire2)
    WireGrid.closest_crossing(grid1, grid2)
  end

  def star6 do
    {:ok, input} = File.read("priv/day3/wires.txt")
    [wire1, wire2 | _] = String.split(input, "\n")
    grid1 = WireGrid.route_wire(wire1)
    grid2 = WireGrid.route_wire(wire2)
    WireGrid.steps_to_crossing(grid1, grid2)
  end

  def star7 do
    lower_bound = 359_282
    upper_bound = 820_401
    PasswordCracker.stream_passwords(lower_bound)
    |> Stream.take_while(&(&1 <= upper_bound))
    |> Enum.count()
  end

  def star8 do
    lower_bound = 359_282
    upper_bound = 820_401
    PasswordCracker.stream_passwords(lower_bound, false)
    |> Stream.take_while(&(&1 <= upper_bound))
    |> Enum.count()
  end

  def star9 do
    {:ok, input} = File.read("priv/day5/diag.txt")
    intcode = Intcode.load_program(input)

    intcode
    |> Intcode.attach(DiagnosticModule, user_input: 1)
    |> Intcode.run()
    |> DiagnosticModule.output()
    |> List.last()
  end

  def star10 do
    {:ok, input} = File.read("priv/day5/diag.txt")
    intcode = Intcode.load_program(input)

    intcode
    |> Intcode.attach(DiagnosticModule, user_input: 5)
    |> Intcode.run()
    |> DiagnosticModule.output()
    |> List.last()
  end

  def star11 do
    {:ok, input} = File.read("priv/day6/map.txt")
    input
    |> OrbitalMap.parse_chart()
    |> OrbitalMap.compute_transitive_orbits()
    |> MapSet.size()
  end

  def star12 do
    {:ok, input} = File.read("priv/day6/map.txt")
    input
    |> OrbitalMap.parse_chart()
    |> OrbitalMap.minimum_transfer_cost("YOU", "SAN")
  end
end
