defmodule Nexpo.CategoriesAcceptanceTest do
  use Nexpo.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "GET /categories returns all categories that exist", %{conn: conn} do
    company_categories = Factory.insert_list(3, :company_category)
    conn = conn |> get("/api/categories")

    assert json_response(conn, 200)
    response = Poison.decode!(conn.resp_body)["data"]
    assert length(response) == length(company_categories)
  end

  test "GET /categories is empty if no categories exist", %{conn: conn} do
    conn = conn |> get("/api/categories")
    assert json_response(conn, 200)
    respose = Poison.decode!(conn.resp_body)["data"]
    assert length(respose) == 0
  end

  test "GET /categories/:id returns an empty attributes list if no exist", %{conn: conn} do
    category = Factory.insert(:company_category)

    conn = conn |> get("/api/categories/#{category.id}")
    assert json_response(conn, 200)
    response = Poison.decode!(conn.resp_body)["data"]

    schema = %{
      "type" => "object",
      "additionalProperties" => false,
      "properties" => %{
        "id" => %{"type" => "number"},
        "title" => %{"type" => "string"},
        "attributes" => %{
          "type" => "array",
          "maxItems" => 0
        }
      }
    } |> ExJsonSchema.Schema.resolve

    assert ExJsonSchema.Validator.validate(schema, response) == :ok
  end

  test "GET /categories returns data on the right format", %{conn: conn} do
    Factory.insert(:company_category) |> Factory.with_attributes(3)
    Factory.insert(:company_category) |> Factory.with_attributes(3)
    conn = conn |> get("/api/categories")

    assert json_response(conn, 200)
    response = Poison.decode!(conn.resp_body)["data"]

    schema = %{
      "type" => "array",
      "minItems" => 2,
      "items" => %{
        "type" => "object",
        "additionalProperties" => false,
        "properties" => %{
          "id" => %{"type" => "number"},
          "title" => %{"type" => "string"},
          "attributes" => %{
            "type" => "array",
            "minItems" => 3
          }
        }
      }
    } |> ExJsonSchema.Schema.resolve

    assert ExJsonSchema.Validator.validate(schema, response) == :ok
  end

  test "GET /categories/:id returns data on the right format", %{conn: conn} do
    category = Factory.insert(:company_category) |> Factory.with_attributes(3)
    conn = conn |> get("/api/categories/#{category.id}")

    assert json_response(conn, 200)
    response = Poison.decode!(conn.resp_body)["data"]

    schema = %{
      "type" => "object",
      "additionalProperties" => false,
      "properties" => %{
        "id" => %{"type" => "number"},
        "title" => %{"type" => "string"},
        "attributes" => %{
          "type" => "array",
          "minItems" => 3
        }
      }
    } |> ExJsonSchema.Schema.resolve

    assert ExJsonSchema.Validator.validate(schema, response) == :ok
  end

end
