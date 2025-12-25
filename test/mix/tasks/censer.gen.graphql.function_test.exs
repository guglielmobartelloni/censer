defmodule Mix.Tasks.Censer.Gen.Graphql.FunctionTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  test "it warns when run" do
    # generate a test project
    test_project()
    # run our task
    |> Igniter.compose_task("censer.gen.graphql.function", [])
  end
end
