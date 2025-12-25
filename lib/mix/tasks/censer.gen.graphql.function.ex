defmodule Mix.Tasks.Censer.Gen.Graphql.Function.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "A short description of your task"
  end

  @spec example() :: String.t()
  def example do
    "mix censer.gen.graphql.function --example arg"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Longer explanation of your task

    ## Example

    ```sh
    #{example()}
    ```

    ## Options

    * `--example-option` or `-e` - Docs for your option
    """
  end
end

defmodule Mix.Tasks.Censer.Gen.Graphql.Function do
  @shortdoc "#{__MODULE__.Docs.short_doc()}"

  @moduledoc __MODULE__.Docs.long_doc()

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    target_module = Censer.Generation

    {function_name, function_ast} =
      build_function_ast("query GetUserContext { currentUser { id email settings { theme } } }")

    igniter
    |> ensure_module_exists(target_module)
    |> Igniter.Project.Module.find_and_update_module(target_module, fn zipper ->
      case Igniter.Code.Function.move_to_def(zipper, function_name, 1) do
        {:ok, _zipper} ->
          {:ok, zipper}

        :error ->
          {:ok, Igniter.Code.Common.add_code(zipper, function_ast)}
      end
    end)
    |> case do
      {:ok, igni} -> igni
    end
  end

  defp ensure_module_exists(igniter, module) do
    case Igniter.Project.Module.find_module(igniter, module) do
      {:ok, {new_igniter, _, _zipper}} ->
        # Module exists, continue with the current igniter
        new_igniter

      {:error, new_igniter} ->
        # Module missing. create_module returns {:ok, igniter}, so we must unwrap it!
        Igniter.Project.Module.create_module(new_igniter, module, """
        """)
    end
  end

  defp build_function_ast(query) do
    {function_name, pattern_ast} = Censer.Graphql.parse_and_build(query)

    ast =
      quote do
        def unquote(function_name)(unquote(pattern_ast)) do
          :ok
        end
      end

    {function_name, ast}
  end
end
