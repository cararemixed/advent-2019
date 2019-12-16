defmodule ThrustAmplification do
  alias ThrustAmplification.Amplifier

  @linear_phases 0..4 |> Enum.to_list()
  @feedback_phases 5..9 |> Enum.to_list()

  def series(envelope, feedback \\ false) do
    amps =
      envelope
      |> Enum.map(fn phase ->
        {:ok, amp} = Amplifier.start(phase)
        amp
      end)

    [first | rest] = amps

    rest
    |> Enum.reduce(first, fn next_amp, amp ->
      :ok = Amplifier.chain(amp, next_amp)
      next_amp
    end)

    if feedback do
      amps |> List.last() |> Amplifier.chain(first)
    end

    {:series, amps}
  end

  def input({:series, [first | _]} = series, value) do
    :ok = Amplifier.send_input(first, value)
    series
  end

  def run({:series, amps} = series) do
    amps |> Enum.each(&Amplifier.run/1)
    series
  end

  def output({:series, amps}) do
    amps |> List.last() |> Amplifier.output()
  end

  @spec permutations([any]) :: Stream.t([any])
  def permutations(elements) do
    total = factorial(length(@linear_phases))

    0..(total - 1)
    |> Stream.map(fn permutation ->
      permute(elements, permutation)
    end)
  end

  def linear_phases do
    @linear_phases
  end

  def feedback_phases do
    @feedback_phases
  end

  @doc """
  Generate a unique permutation of elements given an integer that
  is between 0 and less than the factorial of the number of elements
  being permuted.

  This approach isn't necessarily needed but it was fun to write.
  ¯\_(ツ)_/¯

  ## Examples:

    Permutations are deterministic:

    iex> perm_1 = ThrustAmplification.permute([1,2,3,4], 7)
    iex> perm_2 = ThrustAmplification.permute([1,2,3,4], 7)
    iex> perm_1 == perm_2
    true

    All permutations are generated:

    iex> perms = 0..5 |> Enum.map(fn p ->
    iex>   ThrustAmplification.permute([1,2,3], p)
    iex> end)
    iex> set = perms |> MapSet.new
    iex> MapSet.size(set)
    6
    iex> MapSet.member?(set, [2,1,3])
    true

  """
  @spec permute([term], non_neg_integer) :: [term]
  def permute(elements, permutation) do
    (length(elements) - 1)..0
    |> Enum.reduce({[], elements, permutation}, fn place, {envelope, elems, perm} ->
      radix = factorial(place)
      index = div(perm, radix)
      {elem, remaining_elems} = List.pop_at(elems, index - 1)
      {[elem | envelope], remaining_elems, perm - index * radix}
    end)
    |> elem(0)
  end

  @spec factorial(non_neg_integer) :: non_neg_integer
  defp factorial(n) when n <= 1, do: 1
  defp factorial(n), do: n * factorial(n - 1)
end
