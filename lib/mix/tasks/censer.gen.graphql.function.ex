defmodule Mix.Tasks.Censer.Gen.Graphql.Function.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates an Elixir function with a pattern-matching head from a GraphQL query."
  end

  @spec example() :: String.t()
  def example do
    "mix censer.gen.graphql.function MyApp.UserContext priv/queries/get_user.graphql"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    This task parses a GraphQL `.graphql` file and injects a new function into the
    specified module. The function's name is derived from the GraphQL operation name,
    and its argument is a map pattern that matches the exact shape of the query's selection set.

    ## Usage

    Pass the target module name and the relative path to your GraphQL file:

    ```sh
    #{example()}
    ```

    ## Generated Code Shape

    Given a query:
    ```graphql
    query GetUser { user { id email } }
    ```

    Censer will generate:
    ```elixir
    def handle_get_user(%{"user" => %{"id" => id, "email" => email}}) do
      # ...
    end
    ```

    """
  end
end

defmodule Mix.Tasks.Censer.Gen.Graphql.Function do
  @shortdoc "#{__MODULE__.Docs.short_doc()}"

  @moduledoc __MODULE__.Docs.long_doc()

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _parent) do
    %Igniter.Mix.Task.Info{
      positional: [:module, :graphql_file_path]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    %{module: module, graphql_file_path: file_path} = igniter.args.positional
    target_module = Igniter.Project.Module.parse(module)

    if File.exists?(file_path) do
      query = File.read!(file_path)
      do_igniter(igniter, target_module, query)
    else
      Igniter.add_issue(igniter, "Query file not found at: #{file_path}")
    end
  end

  @spec do_igniter(Igniter.t(), module(), String.t()) :: Igniter.t()
  defp do_igniter(igniter, target_module, query) do
    {function_name, function_ast} =
      build_function_ast(query)

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
      {:error, igni} -> Igniter.add_issue(igni, "There was an error in the generation")
    end
  end

  defp ensure_module_exists(igniter, module) do
    case Igniter.Project.Module.find_module(igniter, module) do
      {:ok, {new_igniter, _, _zipper}} ->
        new_igniter

      {:error, new_igniter} ->
        Igniter.Project.Module.create_module(new_igniter, module, "")
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
