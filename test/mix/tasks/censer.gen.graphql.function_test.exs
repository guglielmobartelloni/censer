defmodule Mix.Tasks.Censer.Gen.Graphql.FunctionTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  test "it warns when run" do
    # generate a test project
    test_project()
    # run our task
    |> Igniter.compose_task("Censer.Gen.Graphql.Function", [])
    # see tools in `Igniter.Test` for available assertions & helpers
    |> assert_has_warning("mix Censer.Gen.Graphql.Function is not yet implemented")
  end
end
