defmodule DiagnosticSystem do
  @moduledoc """
  This serves as a simple diagnostic system for basic intcode programs.

  ## Example: output 1 if input is 8 and 0 otherwise

    iex> code = "3,9,8,9,10,9,4,9,99,-1,8"
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 8, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    1
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 10, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    0

  ## Example: output 1 if input is less than 8 and 0 otherwise

    iex> code = "3,9,7,9,10,9,4,9,99,-1,8"
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 2, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    1
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 10, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    0

  ## Example: immediate mode, check if input equals 8

    iex> code = "3,3,1108,-1,8,3,4,3,99"
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 8, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    1
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: -8, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    0

  ## Example: immediate mode, check if input is less than 8

    iex> code = "3,3,1107,-1,8,3,4,3,99"
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: -1, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    1
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 9, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    0

  ## Example: jump tests, position mode

    iex> code = "3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9"
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 0, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    0
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 10, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    1

  ## Example: jump tests, immediate mode

    iex> code = "3,3,1105,-1,9,1101,0,0,12,4,12,99,1"
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 0, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    0
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: -2, code: code)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    1

  ## Example: compare to 8

    iex> prg = <<
    iex>   "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,",
    iex>   "1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,",
    iex>   "999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99"
    iex> >>
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 7, code: prg)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    999
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 8, code: prg)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    1000
    iex> {:ok, diag} = DiagnosticSystem.start(user_input: 9, code: prg)
    iex> DiagnosticSystem.run(diag)
    iex> DiagnosticSystem.output(diag)
    1001
  """

  defstruct [:intcode, :user_input, :output, :accumulate]

  def start(opts) do
    :gen_statem.start_link(DiagnosticSystem, opts, [])
  end

  def run(diag) do
    :gen_statem.call(diag, :run)
  end

  def output(diag) do
    :gen_statem.call(diag, :output)
  end

  @behaviour :gen_statem

  @impl :gen_statem
  def callback_mode, do: :handle_event_function

  @impl :gen_statem
  def init(opts) do
    intcode =
      case opts[:code] do
        nil -> Intcode.load_program(opts[:program] || "diagnose")
        code -> Intcode.load_code(code)
      end

    data = %DiagnosticSystem{
      intcode: intcode,
      user_input: opts[:user_input],
      output: if(opts[:accumulate], do: [], else: nil),
      accumulate: opts[:accumulate]
    }

    {:ok, :running, data}
  end

  @impl :gen_statem
  def handle_event({:call, from}, :run, :running, data) do
    {:ok, data} = run_until_halt(data)
    {:keep_state, data, [{:reply, from, :ok}]}
  end

  def handle_event({:call, from}, :output, :running, data) do
    if data.accumulate do
      {:keep_state, data, [{:reply, from, Enum.reverse(data.output)}]}
    else
      {:keep_state, data, [{:reply, from, data.output}]}
    end
  end

  defp run_until_halt(data) do
    case data.intcode |> Intcode.run() do
      {:read, intcode, address} ->
        intcode = Intcode.poke(intcode, address, data.user_input)
        run_until_halt(%{data | intcode: intcode})

      {:write, intcode, output} ->
        if data.accumulate do
          run_until_halt(%{data | intcode: intcode, output: [output | data.output]})
        else
          run_until_halt(%{data | intcode: intcode, output: output})
        end

      {:halt, intcode} ->
        {:ok, %{data | intcode: intcode}}
    end
  end
end
