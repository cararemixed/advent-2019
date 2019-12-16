defmodule ThrustAmplification.Amplifier do
  alias ThrustAmplification.Amplifier

  @type t :: %Amplifier{}
  @type event :: :run | {:chain, pid} | {:input, integer} | :final_output
  @type state :: :startup | :running | :awaiting_input | :halted
  @type event_type :: :gen_statem.event_type()
  @type result :: :gen_statem.event_handler_result(atom())

  defstruct [:phase, :intcode, :output, :address, :next]

  @spec start(integer) :: :gen_statem.start_ret()
  def start(phase) do
    :gen_statem.start_link(__MODULE__, phase, [])
  end

  @spec chain(pid, pid) :: :ok
  def chain(amp, into) do
    :gen_statem.cast(amp, {:chain, into})
  end

  @spec run(pid) :: :ok
  def run(amp) do
    :gen_statem.cast(amp, :run)
  end

  @spec send_input(pid, integer) :: :ok
  def send_input(amp, value) do
    :gen_statem.cast(amp, {:input, value})
  end

  @spec output(pid) :: integer
  def output(amp) do
    :gen_statem.call(amp, :final_output)
  end

  @behaviour :gen_statem

  @impl :gen_statem
  def callback_mode, do: :state_functions

  @impl :gen_statem
  @spec init(non_neg_integer) :: {:ok, :startup, t}
  def init(phase) do
    data = %Amplifier{
      intcode: Intcode.load_program("amplifier"),
      phase: phase
    }

    {:ok, :startup, data}
  end

  @spec startup(event_type, event, t) :: result
  def startup(:cast, {:chain, next}, data) do
    {:keep_state, %{data | next: next}}
  end

  def startup(:cast, :run, data) do
    with {:read, intcode, address} <- Intcode.run(data.intcode) do
      {:next_state, :running, %{data | intcode: intcode |> Intcode.poke(address, data.phase)},
       [
         {:next_event, :internal, :run}
       ]}
    else
      {:halt, _} -> raise("failed to start")
      {:write, _, _} -> raise("unexpected output")
    end
  end

  def startup(event_type, event_content, data) do
    handle_event(event_type, event_content, data)
  end

  @spec running(event_type, event, t) :: result
  def running(:internal, :run, data) do
    case data.intcode |> Intcode.run() do
      {:read, intcode, address} ->
        {:next_state, :awaiting_input, %{data | intcode: intcode, address: address}}

      {:write, intcode, output} ->
        if data.next, do: send_input(data.next, output)

        {:keep_state, %{data | intcode: intcode, output: output},
         [
           {:next_event, :internal, :run}
         ]}

      {:halt, intcode} ->
        {:next_state, :halted, %{data | intcode: intcode}}
    end
  end

  def running(event_type, event_content, data) do
    handle_event(event_type, event_content, data)
  end

  @spec awaiting_input(event_type, event, t) :: result
  def awaiting_input(:cast, {:input, value}, data) do
    intcode = Intcode.poke(data.intcode, data.address, value)

    {:next_state, :running, %{data | intcode: intcode},
     [
       {:next_event, :internal, :run}
     ]}
  end

  def awaiting_input(event_type, event_content, data) do
    handle_event(event_type, event_content, data)
  end

  @spec halted(event_type, event, t) :: result
  def halted({:call, from}, :final_output, data) do
    {:keep_state, data, [{:reply, from, data.output}]}
  end

  def halted(event_type, event_content, data) do
    handle_event(event_type, event_content, data)
  end

  defp handle_event(_, :final_output, data) do
    {:keep_state, data, [:postpone]}
  end

  defp handle_event(_, {:input, _}, data) do
    {:keep_state, data, [:postpone]}
  end
end
