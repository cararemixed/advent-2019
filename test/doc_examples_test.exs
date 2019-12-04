defmodule DocExamplesTest do
  use ExUnit.Case
  doctest FuelCalculator
  doctest Intcode
  doctest WireGrid
  doctest PasswordCracker
end
