defmodule Logflare.Lql.Utils do
  @moduledoc false
  alias Logflare.Logs.Validators.BigQuerySchemaChange
  alias Logflare.Lql.{FilterRule, ChartRule}

  def bq_schema_to_typemap(schema) do
    schema
    |> BigQuerySchemaChange.to_typemap()
    |> Iteraptor.to_flatmap()
    |> Enum.map(fn {k, v} -> {String.trim_trailing(k, ".t"), v} end)
    |> Enum.map(fn {k, v} -> {String.replace(k, ".fields.", "."), v} end)
    |> Enum.uniq()
    |> Enum.reject(fn {_k, v} -> v === :map end)
    |> Map.new()
  end

  def build_message_filter_rule_from_regex(regex) when is_binary(regex) do
    %FilterRule{
      operator: "~",
      path: "event_message",
      value: regex,
      modifiers: []
    }
  end

  def get_filter_rules(rules) do
    rules
    |> Enum.filter(&match?(%FilterRule{}, &1))
    |> Enum.sort()
  end

  def get_chart_rules(rules) do
    rules
    |> Enum.filter(&match?(%ChartRule{}, &1))
    |> Enum.sort()
  end
end
