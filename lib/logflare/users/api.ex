defmodule Logflare.Users.API do
  @type api_rates_quotas :: %{
          message: String.t(),
          metrics: %{
            user: %{
              remaining: integer(),
              limit: integer()
            },
            source: %{
              remaining: integer(),
              limit: integer()
            }
          }
        }

  @source_rate_message "Source rate is over the API quota. Email support@logflare.app to increase your rate limit."
  @user_rate_message "User rate is over the API quota. Email support@logflare.app to increase your rate limit."

  @type ok_err_tup :: {:ok, api_rates_quotas} | {:error, api_rates_quotas}

  @callback verify_api_rates_quotas(map) :: ok_err_tup

  alias Logflare.{Users, Sources}
  @api_call_logs {:api_call, :logs_post}

  @spec verify_api_rates_quotas(map) :: ok_err_tup
  def verify_api_rates_quotas(%{type: @api_call_logs} = action) do
    %{source_id: sid, user: user} = action

    source_bucket_metrics = Sources.get_metrics(sid, bucket: :default)
    user_sum_of_sources = get_total_user_api_rate(user.id)

    # possible error values are user.id is nil and source_id is nil which
    # should not ever happen here, raising on pattern match is acceptable
    {:ok, quotas} = Users.Cache.get_api_quotas(user.id, sid)

    source_limit = source_bucket_metrics.duration * quotas.source
    source_remaining = source_limit - source_bucket_metrics.sum

    user_limit = source_bucket_metrics.duration * quotas.user
    user_remaining = user_limit - user_sum_of_sources

    {status, message} =
      cond do
        source_remaining <= 0 ->
          {:error, @source_rate_message}

        user_remaining <= 0 ->
          {:error, @user_rate_message}

        source_remaining > 0 and user_remaining > 0 ->
          {:ok, nil}
      end

    metrics_message = %{
      message: message,
      metrics: %{
        user: %{
          remaining: user_remaining,
          limit: user_limit
        },
        source: %{
          remaining: source_remaining,
          limit: source_limit
        }
      }
    }

    {status, metrics_message}
  end

  def get_total_user_api_rate(user) do
    user
    |> Users.Cache.list_source_ids()
    |> Enum.map(&Sources.get_metrics(&1, bucket: :default))
    |> Enum.map(&Map.get(&1, :sum))
    |> Enum.sum()
  end
end
