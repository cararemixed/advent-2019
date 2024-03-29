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
    {:halt, intcode} =
      Intcode.load_program("self-check")
      |> Intcode.poke(1, 12)
      |> Intcode.poke(2, 2)
      |> Intcode.run()

    Intcode.peek(intcode, 0)
  end

  def star4 do
    initial = Intcode.load_program("self-check")

    eval = fn intcode, operand, operator ->
      {:halt, intcode} =
        intcode
        |> Intcode.poke(1, operand)
        |> Intcode.poke(2, operator)
        |> Intcode.run()

      Intcode.peek(intcode, 0)
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
    with(
      {:ok, diag} <- DiagnosticSystem.start(user_input: 1),
      :ok <- DiagnosticSystem.run(diag),
      output <- DiagnosticSystem.output(diag),
      do: output
    )
  end

  def star10 do
    with(
      {:ok, diag} <- DiagnosticSystem.start(user_input: 5),
      :ok <- DiagnosticSystem.run(diag),
      output <- DiagnosticSystem.output(diag),
      do: output
    )
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

  def star13 do
    ThrustAmplification.linear_phases()
    |> ThrustAmplification.permutations()
    |> Stream.map(fn envelope ->
      ThrustAmplification.series(envelope)
      |> ThrustAmplification.input(0)
      |> ThrustAmplification.run()
      |> ThrustAmplification.output()
    end)
    |> Enum.max()
  end

  def star14 do
    ThrustAmplification.feedback_phases()
    |> ThrustAmplification.permutations()
    |> Stream.map(fn envelope ->
      ThrustAmplification.series(envelope, true)
      |> ThrustAmplification.input(0)
      |> ThrustAmplification.run()
      |> ThrustAmplification.output()
    end)
    |> Enum.max()
  end

  def star15 do
    {:ok, data} = File.read("priv/day8/rover_password_image.txt")
    {:ok, image} = SpaceImageFormat.load_image(data, 25, 6)

    layer =
      image.layers
      |> Enum.min_by(fn layer ->
        layer |> Enum.filter(&(&1 == 0)) |> length
      end)

    ones = layer |> Enum.filter(&(&1 == 1)) |> length
    twos = layer |> Enum.filter(&(&1 == 2)) |> length
    ones * twos
  end

  def star16 do
    {:ok, data} = File.read("priv/day8/rover_password_image.txt")
    {:ok, image} = SpaceImageFormat.load_image(data, 25, 6)
    SpaceImageFormat.render(image)
  end

  def star17 do
    {:ok, diag} = DiagnosticSystem.start(user_input: 1, program: "boost", accumulate: true)
    :ok = DiagnosticSystem.run(diag)
    DiagnosticSystem.output(diag)
  end

  def star18 do
    {:ok, diag} = DiagnosticSystem.start(user_input: 2, program: "boost")
    :ok = DiagnosticSystem.run(diag)
    DiagnosticSystem.output(diag)
  end
end
