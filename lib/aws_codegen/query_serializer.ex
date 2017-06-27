defmodule AWS.CodeGen.QuerySerializer do


  @doc """
  Serialize a request into a query string

  ## Examples

  iex> AWS.CodeGen.QuerySerializer.serialize(%{"Attribute" => "Value"}, %{
  ...>  "type" => "structure",
  ...>  "members" => %{
  ...>    "Attribute" => %{"type" => "string"}
  ...>  }
  ...>})
  "Attribute=Value"
  """
  def serialize(params, rules) do
    serialize("", params, rules)
      |> Enum.join("&");
  end

  defp serialize(_, value, _) when is_nil(value) do
    []
  end

  defp serialize(name, value, %{"type" => "string"})   do
    ["#{name}=#{value}"]
  end

  defp serialize(name, value, rules) when rules == %{} do
    ["#{name}=#{value}"]
  end

  defp serialize(name, struct, %{"type" => "structure", "members" => members}) do

    Enum.flat_map(members, fn {member_key, member_rule} ->

      member_value = struct[member_key]

      if member_value == nil do
        []
      else
        member_name = member_rule["locationName"] || member_key
        member_name = if name != "" do "#{name}.#{member_name}" else member_name end;
        serialize(member_name, member_value, member_rule)
      end
    end)
  end


  defp serialize(name, map, rules = %{"type" => "map"}) do

    map
      |> Enum.with_index()
      |> Enum.flat_map(fn {{map_key, map_value}, index} ->

        prefix = if rules["flattened"], do: ".", else: ".entry."
        position = "#{prefix}#{index + 1}."
        key_name = "#{position}#{rules["key"]["locationName"] || "key"}";
        value_name = "#{position}#{rules["value"]["locationName"] || "value"}";

        serialize("#{name}#{key_name}", map_key, rules["key"])
        ++ serialize("#{name}#{value_name}", map_value, rules["value"])

    end)

  end

  defp serialize(name, list, rules = %{"type" => "list", "member" => member_rule}) do

    list
      |> Enum.with_index()
      |> Enum.flat_map(fn {value, index} ->

        suffix = ".#{index + 1}"

        name = case rules do

          %{"flattened" => true, "member" => %{"locationName" => location_name}} ->
            modified = name
              |> String.split(".")
              |> List.delete_at(-1)
              |> List.insert_at(-1, location_name)
              |> Enum.join(".")

            modified <> suffix
           %{"flattened" => true} -> name <> suffix
          _ ->
            "#{name}.#{member_rule["locationName"] || 'member'}#{suffix}"

        end

        serialize(name, value, member_rule)
      end)
  end

end