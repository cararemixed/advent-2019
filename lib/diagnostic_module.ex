defmodule DiagnosticModule do
  @behaviour Intcode.IOModule

  defstruct [:user_input, :output]

  def boot(intcode, props) do
    {:ok, intcode, DiagnosticModule.new(props[:user_input])}
  end

  def read(intcode, module) do
    {:ok, module.user_input, intcode, module}
  end

  def write(intcode, module, data) do
    {:ok, intcode, %{module | output: [data | module.output]}}
  end

  def new(user_input) do
    %DiagnosticModule{user_input: user_input, output: []}
  end

  def output(intcode) do
    intcode.expansion[DiagnosticModule].output |> Enum.reverse()
  end
end
