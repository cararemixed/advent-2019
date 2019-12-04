defmodule PasswordCracker do
  def stream_passwords(init, relaxed \\ true) do
    init_pass = number_to_password(init)
    next_fn = if relaxed, do: &next_relaxed/1, else: &next/1

    if monotone?(init_pass) do
      Stream.unfold(init_pass, next_fn)
      |> Stream.map(&password_to_number/1)
    else
      stream_passwords(init + 1, relaxed)
    end
  end

  defp next_relaxed(nil), do: nil

  defp next_relaxed(candidate) do
    if monotone?(candidate) and relaxed_repeated_digits?(candidate) do
      {candidate, incr(candidate)}
    else
      next_relaxed(incr(candidate))
    end
  end

  defp next(nil), do: nil

  defp next(candidate) do
    if monotone?(candidate) and repeated_digits?(candidate) do
      {candidate, incr(candidate)}
    else
      next(incr(candidate))
    end
  end

  defp incr(password) do
    # TODO: make this smarter? Still seems
    # fast enough for what we need for star
    # 7 & 8.
    n = password_to_number(password)

    if n < 999_999 do
      number_to_password(n + 1)
    else
      nil
    end
  end

  defp number_to_password(n) do
    {
      div(rem(n, 1_000_000), 100_000),
      div(rem(n, 100_000), 10_000),
      div(rem(n, 10_000), 1_000),
      div(rem(n, 1_000), 100),
      div(rem(n, 100), 10),
      rem(n, 10)
    }
  end

  defp password_to_number({a, b, c, d, e, f}) do
    100_000 * a + 10_000 * b + 1_000 * c + 100 * d + 10 * e + f
  end

  defp monotone?({a, b, c, d, e, f}) do
    a <= b and b <= c and c <= d and d <= e and e <= f
  end

  defp relaxed_repeated_digits?(digits) do
    Enum.any?(0..4, fn i -> elem(digits, i) == elem(digits, i + 1) end)
  end

  defp repeated_digits?(digits) do
    Enum.any?(0..4, fn
      0 ->
        elem(digits, 0) == elem(digits, 1) and
          elem(digits, 1) != elem(digits, 2)

      4 ->
        elem(digits, 3) != elem(digits, 4) and
          elem(digits, 4) == elem(digits, 5)

      i ->
        elem(digits, i - 1) != elem(digits, i) and
          elem(digits, i) == elem(digits, i + 1) and
          elem(digits, i + 1) != elem(digits, i + 2)
    end)
  end
end
