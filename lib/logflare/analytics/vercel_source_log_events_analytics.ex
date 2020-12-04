defmodule Logflare.CustomAnalytics.Vercel do
  import Ecto.Query
  alias Logflare.Lql.EctoHelpers
  alias Logflare.BqRepo
  @project_id Application.get_env(:logflare, Logflare.Google)[:project_id]

  def list_datasets(token \\ nil) do
    project_id = Application.get_env(:logflare, Logflare.Google)[:project_id]
    {:ok, goth} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    conn = GoogleApi.BigQuery.V2.Connection.new(goth.token)

    {:ok, dataset_response} =
      GoogleApi.BigQuery.V2.Api.Datasets.bigquery_datasets_list(
        conn,
        project_id,
        pageToken: token,
        maxResults: 100
      )

    datasets = dataset_response.datasets

    if dataset_response.nextPageToken do
      list_datasets(dataset_response.nextPageToken) ++ datasets
    else
      Enum.flatten(datasets)
    end
  end

  def generate_all_datasets_and_tables() do
    datasets = list_datasets()
    {:ok, goth} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    conn = GoogleApi.BigQuery.V2.Connection.new(goth.token)

    datasets_tables =
      for %{datasetReference: %{datasetId: dataset_id}} <- datasets do
        with {:ok, tablelist_response} <-
               GoogleApi.BigQuery.V2.Api.Tables.bigquery_tables_list(
                 conn,
                 @project_id,
                 dataset_id
               ) do
          for %{tableReference: %{tableId: table_id}} <- tablelist_response.tables || [] do
            {dataset_id, table_id}
          end
        end
      end
      |> List.flatten()
  end

  def table_name(dataset_id, table_id) do
    "`#{dataset_id}.#{table_id}`"
  end

  def durations_sums_query(dataset_id, table_id) do
    table_name(dataset_id, table_id)
    |> from()
    |> EctoHelpers.unnest_and_join_nested_columns(
      :inner,
      "metadata.parsedLambdaMessage.report.billed_duration_ms"
    )
    |> EctoHelpers.unnest_and_join_nested_columns(
      :inner,
      "metadata.parsedLambdaMessage.report.duration_ms"
    )
    |> select([le, ..., t], %{
      dataset: fragment("? as dataset_id", ^dataset_id),
      table_id: fragment("? as table_id", ^table_id),
      billed_duration_ms: fragment("sum(?) as billed_duration_ms", t.billed_duration_ms),
      duration_ms: fragment("sum(?) as duration_ms", t.duration_ms),
      date: fragment("CAST(? as DATE) as date", le.timestamp)
    })
    |> EctoHelpers.unnest_and_join_nested_columns(
      :inner,
      "metadata.source"
    )
    |> select_merge([le, ..., t], %{
      count: fragment("count(?) as count", t.source)
    })
    |> where([le, ...], fragment("_PARTITIONTIME >= TIMESTAMP('2020-11-27')"))
    |> where([le, ...], fragment("_PARTITIONTIME <= TIMESTAMP('2020-12-03')"))
    |> group_by([t, ...], fragment("CAST(? as DATE)", t.timestamp))
  end

  def source_type_count_query(dataset_id, table_id) do
    table_name(dataset_id, table_id)
    |> from()
    |> EctoHelpers.unnest_and_join_nested_columns(
      :inner,
      "metadata.source"
    )
    |> select([le, ..., t], %{
      source_type: fragment("? as source", t.source),
      count: fragment("count(?) as count", t.source),
      date: fragment("CAST(? as DATE) as date", le.timestamp)
    })
    |> where([le, ...], fragment("_PARTITIONTIME >= TIMESTAMP('2020-11-27')"))
    |> where([le, ...], fragment("_PARTITIONTIME <= TIMESTAMP('2020-12-03')"))
    |> where([le, ..., t], not is_nil(t.source))
    |> group_by([le, ..., t], [fragment("CAST(? as DATE)", le.timestamp), t.source])
  end

  def extract_data_to_file(query_id, query, file_name) do
    file = File.open!(file_name, [:write, :utf8])

    {build_query, headers, group_by, mapper} =
      case query_id do
        :vercel_event_count ->
          {
            &durations_sums_query/2,
            [:date, :billed_duration_ms, :duration_ms, :count],
            &{&1.date, &1.source},
            fn {date, values} ->
              %{
                date: date,
                count: Enum.sum(Enum.map(values, & &1.count)),
                billed_duration_ms: Enum.sum(Enum.map(values, & &1.billed_duration_ms)),
                duration_ms: Enum.sum(Enum.map(values, & &1.duration_ms))
              }
            end
          }

        :vercel_event_ms_stats ->
          {&source_type_count_query/2, [:date, :source, :count], & &1.date,
           fn {{date, source}, values} ->
             %{
               date: date,
               count: Enum.sum(Enum.map(values, & &1.count)),
               source_type: source
             }
           end}
      end

    Scratch.Data.vercel_datasets_tables()
    |> Flow.from_enumerable(max_demand: 10)
    |> Flow.map(fn {dataset_id, table_id} ->
      IO.puts("Extracting data from #{dataset_id} table #{table_id}")

      BqRepo.query(@project_id, query.(dataset_id, table_id))
    end)
    |> reject_errors()
    |> Flow.map(fn {:ok, %{rows: rows}} -> rows end)
    |> Enum.to_list()
    |> List.flatten()
    |> Enum.group_by(group_by)
    |> Enum.map(mapper)
    |> CSV.encode(headers: headers)
    |> Enum.each(&IO.write(file, &1))
  end

  def reject_errors(results) when is_list(results) do
    Enum.reject(results, &rejector/1)
  end

  def reject_errors(%Flow{} = f) do
    Flow.reject(f, &rejector/1)
  end

  defp rejector(v) do
    case v do
      {:error, _} -> true
      {:ok, _} -> false
      nil -> true
    end
  end
end
