defmodule Intcode do
  @moduledoc """
  A simple intcode interpreter.

  ## Example program and output:

    iex> vm = Intcode.load_program("1,9,10,3,2,3,11,0,99,30,40,50")
    iex> vm |> Intcode.run |> Intcode.peek(0)
    3500

  """

  defstruct memory: %{0 => 99},
            counter: 0

  def load_program(input) do
    program =
      input
      |> String.split(",")
      |> Enum.map(&(String.trim(&1) |> String.to_integer()))
      |> Stream.with_index()
      |> Enum.reduce(%{}, fn {int, idx}, program ->
        Map.put(program, idx, int)
      end)

    %Intcode{memory: program}
  end

  def run(intcode) do
    case step(intcode) do
      {:continue, intcode} -> run(intcode)
      {:halt, intcode} -> intcode
    end
  end

  def peek(intcode, address) do
    intcode.memory[address]
  end

  def poke(intcode, address, value) do
    # Use put to allow any address to be used
    # even if it was beyond the program size.
    %{intcode | memory: Map.put(intcode.memory, address, value)}
  end

  defp step(intcode) do
    step(decode_op(intcode), intcode)
  end

  # Op: add in in out
  defp step({1, src1, src2, dest}, intcode) do
    sum = peek(intcode, src1) + peek(intcode, src2)

    intcode =
      intcode
      |> poke(dest, sum)
      |> advance_counter()

    {:continue, intcode}
  end

  # Op: multiply in in out
  defp step({2, src1, src2, dest}, intcode) do
    product = peek(intcode, src1) * peek(intcode, src2)

    intcode =
      intcode
      |> poke(dest, product)
      |> advance_counter()

    {:continue, intcode}
  end

  # Op: halt
  defp step({99, _, _, _}, intcode) do
    {:halt, intcode}
  end

  # Decode 4 integers at a time as a tuple. If
  # we are out of range of our program memory,
  # we will get nil values back.
  defp decode_op(intcode) do
    for offset <- 0..3 do
      peek(intcode, intcode.counter + offset)
    end
    |> List.to_tuple()
  end

  defp advance_counter(intcode) do
    %{intcode | counter: intcode.counter + 4}
  end
end
