defmodule Intcode do
  @moduledoc """
  A simple intcode interpreter.

  ## Example program and output:

    iex> vm = Intcode.load_code("1,9,10,3,2,3,11,0,99,30,40,50")
    iex> {:halt, vm} = vm |> Intcode.run
    iex> vm |> Intcode.peek(0)
    3500

  """

  @type t :: %Intcode{}

  defstruct memory: %{0 => 99}, counter: 0

  @spec load_program(binary | {:path, binary}) :: Intcode.t()
  def load_program(name) do
    {:ok, input} = File.read("priv/programs/#{name}.txt")
    load_code(input)
  end

  def load_code(input) do
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
      {:halt, intcode} -> {:halt, intcode}
      {:read, intcode, {:address, address}} -> {:read, intcode, address}
      {:write, intcode, output} -> {:write, intcode, input(intcode, output)}
    end
  end

  def peek(intcode, address) do
    case intcode.memory[address] do
      nil -> raise(ArgumentError, "tried to read uninitialized memory address: #{address}")
      value -> value
    end
  end

  def poke(intcode, address, value) do
    # Use put to allow any address to be used
    # even if it was beyond the program size.
    %{intcode | memory: Map.put(intcode.memory, address, value)}
  end

  defp step(intcode) do
    intcode |> step(decode_op(intcode))
  end

  # Op: add in in out
  defp step(intcode, {1, src1, src2, dest}) do
    sum = input(intcode, src1) + input(intcode, src2)
    {:continue, intcode |> output(dest, sum) |> advance_counter(4)}
  end

  # Op: multiply in in out
  defp step(intcode, {2, src1, src2, dest}) do
    product = input(intcode, src1) * input(intcode, src2)
    {:continue, intcode |> output(dest, product) |> advance_counter(4)}
  end

  # Op: read_port out
  defp step(intcode, {3, dest}) do
    {:read, intcode |> advance_counter(2), dest}
  end

  # Op: write_port in
  defp step(intcode, {4, src}) do
    {:write, intcode |> advance_counter(2), src}
  end

  # Op: jump_if_true in in
  defp step(intcode, {5, test, target}) do
    {:continue,
     case input(intcode, test) do
       0 -> intcode |> advance_counter(3)
       _ -> %{intcode | counter: input(intcode, target)}
     end}
  end

  # Op: jump_if_false in in
  defp step(intcode, {6, test, target}) do
    {:continue,
     case input(intcode, test) do
       0 -> %{intcode | counter: input(intcode, target)}
       _ -> intcode |> advance_counter(3)
     end}
  end

  # Op: less_than in in out
  defp step(intcode, {7, left, right, dest}) do
    bit = if input(intcode, left) < input(intcode, right), do: 1, else: 0
    {:continue, intcode |> output(dest, bit) |> advance_counter(4)}
  end

  # Op: equals in in out
  defp step(intcode, {8, left, right, dest}) do
    bit = if input(intcode, left) == input(intcode, right), do: 1, else: 0
    {:continue, intcode |> output(dest, bit) |> advance_counter(4)}
  end

  # Op: halt
  defp step(intcode, {99}) do
    {:halt, intcode}
  end

  defp input(intcode, {:address, addr}), do: peek(intcode, addr)
  defp input(_intocde, {:immediate, imm}), do: imm

  defp output(intcode, {:address, addr}, imm), do: poke(intcode, addr, imm)

  # Decode op integers. Each operation will include
  # the expected number of operands. It is assumed
  # that the program is well-formed as reads outside
  # of initialized memory will cause an error to be
  # raised.
  defp decode_op(intcode) do
    code = peek(intcode, intcode.counter)
    op = rem(code, 100)
    modes = div(code, 100)

    offsets =
      cond do
        op in [1, 2, 7, 8] -> 1..3
        op in [5, 6] -> 1..2
        op in [3, 4] -> [1]
        op == 99 -> []
        true -> raise(RuntimeError, "unknown operation: #{op}")
      end

    operands =
      for offset <- offsets do
        arg = peek(intcode, intcode.counter + offset)

        case decode_mode(modes, offset) do
          0 -> {:address, arg}
          1 -> {:immediate, arg}
        end
      end

    [op | operands] |> List.to_tuple()
  end

  defp decode_mode(modes, 1), do: rem(modes, 10)

  defp decode_mode(modes, offset) do
    rem(div(modes, 10 * (offset - 1)), 10 * offset)
  end

  defp advance_counter(intcode, n) do
    %{intcode | counter: intcode.counter + n}
  end
end
