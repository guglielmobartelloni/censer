defmodule Censer.Graphql do
  alias Absinthe.Language.Field

  @spec parse_and_build(String.t()) :: {any(), any()}
  def parse_and_build(query_string) do
    {:ok, %{input: ast}} = Absinthe.Phase.Parse.run(query_string)

    op = List.first(ast.definitions)

    fn_name = derive_function_name(op.name)

    pattern = build_ast_pattern(op.selection_set.selections)

    {fn_name, pattern}
  end

  defp derive_function_name(nil), do: raise(ArgumentError, "Query/Mutation name not found")

  defp derive_function_name(name) do
    snake_name = Macro.underscore(name)
    String.to_atom("handle_#{snake_name}")
  end

  defp build_ast_pattern(selections) do
    {:%{}, [], Enum.map(selections, &build_field/1)}
  end

  # Leaf Node: "email" => email
  defp build_field(%Field{name: name, selection_set: nil}) do
    var_name = String.to_atom(name)
    {name, {var_name, [], nil}}
  end

  # Nested Node: "profile" => %{...}
  defp build_field(%Field{name: name, selection_set: %{selections: sub_fields}}) do
    {name, build_ast_pattern(sub_fields)}
  end
end
