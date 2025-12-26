defmodule Mix.Tasks.Censer.Gen.Function.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates Elixir function clauses with pattern-matching heads from a GraphQL query."
  end

  @spec example() :: String.t()
  def example do
    "mix censer.gen.function MyApp.UserContext priv/queries/get_user.graphql"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    This task parses a `.graphql` file and uses `Igniter` to inject a corresponding
    function into the specified target module.

    The generated function's name is derived from the GraphQL operation name. The function
    arguments are map patterns that match the exact shape of the query's selection set.

    ## Behavior

    * **Module Creation:** If the target module does not exist, it will be created.
    * **Idempotency:** If a function with the same name and arity (1) already exists
        in the module, the task will skip injection to avoid overwriting existing logic.
    * **Multiple Clauses:** If the GraphQL query implies multiple resulting shapes,
        multiple function clauses will be generated.

    ## Usage

    Pass the target module name and the path to your GraphQL file:

    ```sh
    #{example()}
    ```

    ## Generated Code Shape

    Given a GraphQL query file containing:
    ```graphql
    query GetUser { user { id email } }
    ```

    Censer will generate code similar to the following:

    ```elixir
    defmodule MyApp.UserContext do
      # ...

      def handle_get_user(%{"user" => %{"id" => id, "email" => email}}) do
        :ok
      end
    end
    ```
    """
  end
end

defmodule Mix.Tasks.Censer.Gen.Function do
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

  defp do_igniter(igniter, target_module, query) do
    {function_name, function_ast} = build_function_ast(query)

    igniter
    |> ensure_module_exists(target_module)
    |> Igniter.Project.Module.find_and_update_module(target_module, fn zipper ->
      # We skip if function exists to avoid messing up existing logic
      case Igniter.Code.Function.move_to_def(zipper, function_name, 1) do
        {:ok, _zipper} -> {:ok, zipper}
        :error -> {:ok, Igniter.Code.Common.add_code(zipper, function_ast)}
      end
    end)
    |> case do
      {:ok, igni} -> igni
      {:error, igni} -> Igniter.add_issue(igni, "Error generating function")
    end
  end

  defp ensure_module_exists(igniter, module) do
    case Igniter.Project.Module.module_exists(igniter, module) do
      {true, new_igniter} ->
        new_igniter

      {false, new_igniter} ->
        Igniter.Project.Module.create_module(new_igniter, module, "")
    end
  end

  defp build_function_ast(query) do
    {function_name, patterns} = Censer.Graphql.parse_and_build(query)

    clauses =
      Enum.map(patterns, fn pattern ->
        quote do
          def unquote(function_name)(unquote(pattern) = args) do
            {:ok, args}
          end
        end
      end)

    fallback_clause =
      quote do
        def unquote(function_name)(unexpected_args) do
          IO.inspect(unexpected_args)
          {:error, :unexpected_match}
        end
      end

    {function_name, {:__block__, [], clauses ++ [fallback_clause]}}
  end
end
