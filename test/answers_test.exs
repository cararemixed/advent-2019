defmodule AnswersTest do
  use ExUnit.Case

  test "star 1" do
    assert Advent.star1() == 3_412_207
  end

  test "star 2" do
    assert Advent.star2() == 5_115_436
  end

  test "star 3" do
    assert Advent.star3() == 3_058_646
  end

  test "star 4" do
    assert Advent.star4() == 8976
  end

  test "star 5" do
    assert Advent.star5() == 651
  end

  test "star 6" do
    assert Advent.star6() == 7534
  end
end
