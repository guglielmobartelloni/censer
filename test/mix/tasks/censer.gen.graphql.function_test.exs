defmodule Mix.Tasks.Censer.Gen.FunctionTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  test "it warns when run" do
    test_project()
    |> Igniter.compose_task("censer.gen.function", [])
  end
end
