defmodule Intcode do
  @moduledoc """
  A simple intcode interpreter.

  ## Example program and output:

    iex> vm = Intcode.load_program("1,9,10,3,2,3,11,0,99,30,40,50")
    iex> vm |> Intcode.run |> Intcode.peek(0)
    3500

  ## Example: output 1 if input is 8 and 0 otherwise

    iex> vm = Intcode.load_program("3,9,8,9,10,9,4,9,99,-1,8")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 8)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [1]

    iex> vm = Intcode.load_program("3,9,8,9,10,9,4,9,99,-1,8")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 2)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [0]

  ## Example: output 1 if input is less than 8 and 0 otherwise

    iex> vm = Intcode.load_program("3,9,7,9,10,9,4,9,99,-1,8")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 2)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [1]


    iex> vm = Intcode.load_program("3,9,7,9,10,9,4,9,99,-1,8")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 10)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [0]


  ## Example: immediate mode, check if input equals 8

    iex> vm = Intcode.load_program("3,3,1108,-1,8,3,4,3,99")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 8)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [1]

    iex> vm = Intcode.load_program("3,3,1108,-1,8,3,4,3,99")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: -8)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [0]

  ## Example: immediate mode, check if input is less than 8

    iex> vm = Intcode.load_program("3,3,1107,-1,8,3,4,3,99")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: -1)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [1]

    iex> vm = Intcode.load_program("3,3,1107,-1,8,3,4,3,99")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 9)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [0]

  ## Example: jump tests, position mode

    iex> vm = Intcode.load_program("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 0)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [0]

    iex> vm = Intcode.load_program("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 10)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [1]

  ## Example: jump tests, immediate mode

    iex> vm = Intcode.load_program("3,3,1105,-1,9,1101,0,0,12,4,12,99,1")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 0)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [0]

    iex> vm = Intcode.load_program("3,3,1105,-1,9,1101,0,0,12,4,12,99,1")
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: -2)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [1]

  ## Example: compare to 8

    iex> prg = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,"
    iex> prg = prg <> "1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,"
    iex> prg = prg <> "999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99"
    iex> vm = Intcode.load_program(prg)
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 7)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [999]
    iex> vm = Intcode.load_program(prg)
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 8)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [1000]
    iex> vm = Intcode.load_program(prg)
    iex> vm = vm |> Intcode.attach(DiagnosticModule, user_input: 9)
    iex> vm |> Intcode.run |> DiagnosticModule.output
    [1001]

  """

  @type t :: %Intcode{}

  defstruct memory: %{0 => 99},
            counter: 0,
            expansion: %{},
            io_module: nil

  def load_program(input, io_module \\ nil) do
    program =
      input
      |> String.split(",")
      |> Enum.map(&(String.trim(&1) |> String.to_integer()))
      |> Stream.with_index()
      |> Enum.reduce(%{}, fn {int, idx}, program ->
        Map.put(program, idx, int)
      end)

    %Intcode{memory: program, io_module: io_module}
  end

  def attach(intcode, io_module, props \\ []) do
    {:ok, intcode, mod_state} = io_module.boot(intcode, props)

    %{
      intcode
      | io_module: io_module,
        expansion: intcode.expansion |> Map.put(io_module, mod_state)
    }
  end

  def run(intcode) do
    case step(intcode) do
      {:continue, intcode} -> run(intcode)
      {:halt, intcode} -> intcode
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

  def read(intcode) do
    io_module = intcode.io_module
    state = intcode.expansion[io_module]
    {:ok, data, intcode, state} = io_module.read(intcode, state)
    {data, put_in(intcode, [Access.key(:expansion), io_module], state)}
  end

  def write(intcode, data) do
    io_module = intcode.io_module
    state = intcode.expansion[io_module]
    {:ok, intcode, state} = io_module.write(intcode, state, data)
    intcode |> put_in([Access.key(:expansion), io_module], state)
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
    {input, intcode} = read(intcode)
    {:continue, intcode |> output(dest, input) |> advance_counter(2)}
  end

  # Op: write_port in
  defp step(intcode, {4, src}) do
    {:continue, intcode |> write(input(intcode, src)) |> advance_counter(2)}
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
