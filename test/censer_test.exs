defmodule CenserTest do
  use ExUnit.Case
  doctest Censer

  test "greets the world" do
    assert Censer.hello() == :world
  end
end
