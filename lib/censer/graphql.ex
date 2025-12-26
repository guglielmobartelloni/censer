defmodule Censer.Graphql do
  alias Absinthe.Language.{Field, InlineFragment}

  @type function_name :: atom()
  @type pattern_ast :: Macro.t()

  @spec parse_and_build(String.t()) :: {function_name(), [pattern_ast()]}
  def parse_and_build(query_string) do
    {:ok, %{input: ast}} = Absinthe.Phase.Parse.run(query_string)
    op = List.first(ast.definitions)
    fn_name = derive_function_name(op.name)

    patterns = expand_selections(op.selection_set.selections)
    {fn_name, patterns}
  end

  defp derive_function_name(nil), do: raise(ArgumentError, "Query/Mutation name not found")

  defp derive_function_name(name) do
    name |> Macro.underscore() |> then(&"handle_#{&1}") |> String.to_atom()
  end

  defp expand_selections(selections) do
    {fragments, common} = Enum.split_with(selections, &match?(%InlineFragment{}, &1))

    case fragments do
      [] ->
        combine_fields(common)

      _ ->
        Enum.flat_map(fragments, fn fragment ->
          type_name = fragment.type_condition.name
          combined_selections = common ++ fragment.selection_set.selections

          # Expand the combined fields into possible map ASTs
          expanded_maps = expand_selections(combined_selections)

          # Now safely inject the concrete Typename into those map ASTs
          Enum.map(expanded_maps, &inject_typename(&1, type_name))
        end)
    end
  end

  defp combine_fields(fields) do
    fields
    |> Enum.map(&build_field_variants/1)
    |> cartesian_product()
    |> Enum.map(fn kv_list -> {:%{}, [], kv_list} end)
  end

  defp build_field_variants(%Field{name: name, selection_set: nil}) do
    var_name = name |> Macro.underscore() |> String.to_atom()
    [{name, {var_name, [], nil}}]
  end

  defp build_field_variants(%Field{name: name, selection_set: %{selections: sub}}) do
    possible_child_maps = expand_selections(sub)
    Enum.map(possible_child_maps, fn child_map -> {name, child_map} end)
  end

  # --- Helpers ---

  # This now strictly matches the Map AST tuple {:%{}, context, fields}
  defp inject_typename({:%{}, context, fields}, type_name) do
    # Remove the variable matcher if the user explicitly requested __typename in the query
    # e.g. remove {"__typename", {:__typename, [], nil}}
    filtered = Enum.reject(fields, fn {k, _v} -> k == "__typename" end)

    # Add the hardcoded string match for the fragment type
    {:%{}, context, [{"__typename", type_name} | filtered]}
  end

  defp cartesian_product([]), do: [[]]

  defp cartesian_product([head | tail]) do
    for item <- head, rest <- cartesian_product(tail), do: [item | rest]
  end
end
