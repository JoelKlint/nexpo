defmodule Nexpo.CompanyView do
  use Nexpo.Web, :view

  def render("index.json", %{companies: companies}) do
      %{data: render_many(companies, Nexpo.CompanyView, "company.json")}
    end

    def render("show.json", %{company: company}) do
      %{data: render_one(company, Nexpo.CompanyView, "company.json")}
    end

    def render("company.json", %{company: company}) do
      base = %{
        id: company.id,
        name: company.name
      }

      if (not ListCheck.is_empty(company.entries)) do
          result = company.entries
          |> Enum.map(fn e ->
            Map.put(%{}, e.attribute.title, e.value)
          end)
          |> Enum.reduce(fn o, acc -> Map.merge(acc, o) end)

          Map.merge(result, base)
      else
          base
      end

    end


end

defmodule ListCheck do
  def is_empty([]), do: true
  def is_empty(list) when is_list(list) do
    false
  end
end