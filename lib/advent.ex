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
end
