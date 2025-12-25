# Censer 🏺

**Vaporize GraphQL queries into elegant Elixir patterns.**

`Censer` is a development-time toolkit that bridges the gap between **Absinthe** and **Igniter**. It parses GraphQL query strings and automatically generates Elixir function heads with deep pattern-matching structures, ensuring your handlers match your data requirements exactly.



## Why Censer?

When working with GraphQL in Elixir, you often find yourself manually writing nested map patterns to destructure API responses. This is error-prone and tedious. `Censer` automates this by:

1.  **Parsing** your `.graphql` files using the robust Absinthe parser.
2.  **Generating** idiomatic Elixir AST patterns, respecting aliases and nested structures.
3.  **Injecting** code directly into your modules using Igniter's safe code-patching engine.

## Installation

Add `censer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:censer, "~> 0.1.0", only: [:dev, :test]}
  ]
end
