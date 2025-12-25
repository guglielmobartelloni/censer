defmodule Censer.Generation do
  def handle_create_post(%{
        "createPost" => %{
          "id" => id,
          "status" => status,
          "result" => %{"title" => title, "body" => body, "publishedAt" => published_at},
          "author" => %{"name" => name, "roles" => roles},
          "errors" => %{"field" => field, "message" => message}
        }
      }) do
    :ok
  end
end
