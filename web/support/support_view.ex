defmodule Nexpo.Support.View do
  @moduledoc """
  A module that can render all models

  The helper makes sure to render all preloaded associations and ignores
  all relations which are not preloaded
  """
  use Nexpo.Web, :view

  @doc """
  Creates a Map that can be converted to JSON
  """
  def render_object(object, base_params) do
    # Build base object
    base = Map.take(object, base_params)

    # Construct an array with all relations that should get rendered
    # TODO: Redo how relations array are created
    relations = []
    relations = relations ++ case Map.get(object, :entries) do
      %Ecto.Association.NotLoaded{} -> []
      _ -> [:entries]
    end
    relations = relations ++ case Map.get(object, :company) do
      %Ecto.Association.NotLoaded{} -> []
      _ -> [:company]
    end
    relations = relations ++ case Map.get(object, :attribute) do
      %Ecto.Association.NotLoaded{} -> []
      _ -> [:attribute]
    end
    relations = relations ++ case Map.get(object, :attributes) do
      %Ecto.Association.NotLoaded{} -> []
      _ -> [:attributes]
    end
    relations = relations ++ case Map.get(object, :category) do
      %Ecto.Association.NotLoaded{} -> []
      _ -> [:category]
    end

    # Render all relations
    relations = relations
    |> Enum.filter(fn r -> Map.has_key?(object, r) && is_loaded(Map.get(object, r)) end)
    |> Enum.map(fn r -> render_relation(r, object) end)

    # Return base if there are no relations
    if(Enum.empty?(relations)) do
      base
    # Return base with relations if there are relations
    else
      relations
      |> Enum.reduce(fn (x, acc) -> Map.merge(acc, x) end)
      |> Map.merge(base)
    end
  end

  # Defines how to render all possible relations in database
  # Both in plural and singular
  defp render_relation(relation, object) do
    case relation do
      :entries ->
        %{:entries => render_many(object.entries, Nexpo.CompanyEntryView, "company_entry.json")}
      :company ->
        %{:company => render_one(object.company, Nexpo.CompanyView, "company.json")}
      :attribute ->
        %{:attribute => render_one(object.attribute, Nexpo.CompanyAttributeView, "company_attribute.json")}
      :attributes ->
        %{:attributes => render_many(object.attributes, Nexpo.CompanyAttributeView, "company_attribute.json")}
      :category ->
        %{:category => render_one(object.category, Nexpo.CompanyCategoryView, "company_category.json")}
      _ ->
        %{}
    end
  end

  # Checks wheter association has been loaded
  defp is_loaded(object) do
    case object do
      %Ecto.Association.NotLoaded{} -> false
      _ -> true
    end
  end

end
