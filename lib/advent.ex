defmodule Advent do
  def star1 do
    {:ok, content} = File.read("priv/day1/masses.txt")
    star1(content)
  end

  def star1(input) do
    input
    |> FuelCalculator.parse_module_masses()
    |> Enum.map(&FuelCalculator.naive_mass_to_fuel/1)
    |> FuelCalculator.total_fuel()
  end

  def star2 do
    {:ok, content} = File.read("priv/day1/masses.txt")
    star2(content)
  end

  def star2(input) do
    input
    |> FuelCalculator.parse_module_masses()
    |> Enum.map(&FuelCalculator.mass_to_fuel/1)
    |> FuelCalculator.total_fuel()
  end

  def star3 do
    {:ok, content} = File.read("priv/day2/program1.txt")
    star3(content)
  end

  def star3(input) do
    Intcode.load_program(input)
    |> Intcode.poke(1, 12)
    |> Intcode.poke(2, 2)
    |> Intcode.run()
    |> Intcode.peek(0)
  end

  def star4 do
    {:ok, content} = File.read("priv/day2/program1.txt")
    star4(content)
  end

  def star4(input) do
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
    {:ok, content} = File.read("priv/day3/wires.txt")
    star5(content)
  end

  def star5(input) do
    [wire1, wire2 | _] = String.split(input, "\n")
    grid1 = WireGrid.route_wire(wire1)
    grid2 = WireGrid.route_wire(wire2)
    WireGrid.closest_crossing(grid1, grid2)
  end

  def star6 do
    {:ok, content} = File.read("priv/day3/wires.txt")
    star6(content)
  end

  def star6(input) do
    [wire1, wire2 | _] = String.split(input, "\n")
    grid1 = WireGrid.route_wire(wire1)
    grid2 = WireGrid.route_wire(wire2)
    WireGrid.steps_to_crossing(grid1, grid2)
  end

  def star7 do
    star7(359_282, 820_401)
  end

  def star7(lower_bound, upper_bound) do
    PasswordCracker.stream_passwords(lower_bound)
    |> Stream.take_while(&(&1 <= upper_bound))
    |> Enum.count()
  end

  def star8 do
    star8(359_282, 820_401)
  end

  def star8(lower_bound, upper_bound) do
    PasswordCracker.stream_passwords(lower_bound, false)
    |> Stream.take_while(&(&1 <= upper_bound))
    |> Enum.count()
  end

  def star9 do
    {:ok, content} = File.read("priv/day5/diag.txt")
    star9(content)
  end

  def star9(input) do
    intcode = Intcode.load_program(input)

    intcode
    |> Intcode.attach(DiagnosticModule, user_input: 1)
    |> Intcode.run()
    |> DiagnosticModule.output()
    |> List.last()
  end

  def star10 do
    {:ok, content} = File.read("priv/day5/diag.txt")
    star10(content)
  end

  def star10(input) do
    intcode = Intcode.load_program(input)

    intcode
    |> Intcode.attach(DiagnosticModule, user_input: 5)
    |> Intcode.run()
    |> DiagnosticModule.output()
    |> List.last()
  end

  def star11 do
    {:ok, content} = File.read("priv/day6/map.txt")
    star11(content)
  end

  def star11(input) do
    input
    |> OrbitalMap.parse_chart()
    |> OrbitalMap.compute_transitive_orbits()
    |> MapSet.size()
  end

  def star12 do
    {:ok, content} = File.read("priv/day6/map.txt")
    star12(content)
  end

  def star12(input) do
    input
    |> OrbitalMap.parse_chart()
    |> OrbitalMap.minimum_transfer_cost("YOU", "SAN")
  end
end
