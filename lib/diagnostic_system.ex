defmodule DiagnosticSystem do
  defstruct [:intcode, :user_input, :output]

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
    data = %DiagnosticSystem{
      intcode: Intcode.load_program("diagnose"),
      user_input: opts[:user_input]
    }

    {:ok, :running, data}
  end

  @impl :gen_statem
  def handle_event({:call, from}, :run, :running, data) do
    {:ok, data} = run_until_halt(data)
    {:keep_state, data, [{:reply, from, :ok}]}
  end

  def handle_event({:call, from}, :output, :running, data) do
    {:keep_state, data, [{:reply, from, data.output}]}
  end

  defp run_until_halt(data) do
    case data.intcode |> Intcode.run() do
      {:read, intcode, address} ->
        intcode = Intcode.poke(intcode, address, data.user_input)
        run_until_halt(%{data | intcode: intcode})

      {:write, intcode, output} ->
        run_until_halt(%{data | intcode: intcode, output: output})

      {:halt, intcode} ->
        {:ok, %{data | intcode: intcode}}
    end
  end
end
