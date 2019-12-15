defmodule DiagnosticModule do
  alias Intcode.IOModule

  @behaviour IOModule
  @type t :: %DiagnosticModule{}

  defstruct [:user_input, :output]

  @spec boot(Intcode.t, keyword) :: IOModule.boot_result(t)
  def boot(intcode, props) do
    {:ok, intcode, DiagnosticModule.new(props[:user_input])}
  end

  @spec read(Intcode.t, t) :: IOModule.read_result(t, term)
  def read(intcode, module) do
    {:ok, module.user_input, intcode, module}
  end

  @spec write(Intcode.t, t, term) :: IOModule.write_result(t)
  def write(intcode, module, data) do
    {:ok, intcode, %{module | output: [data | module.output]}}
  end

  @spec new(term) :: DiagnosticModule.t()
  def new(user_input) do
    %DiagnosticModule{user_input: user_input, output: []}
  end

  @spec output(Intcode.t) :: [term]
  def output(intcode) do
    intcode.expansion[DiagnosticModule].output |> Enum.reverse()
  end
end
