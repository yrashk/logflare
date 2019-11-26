defmodule Logflare.Sources.Buffers do
  @moduledoc false

  @cache __MODULE__

  require Logger

  def child_spec(_) do
    cachex_opts = []

    %{
      id: :cachex_buffers_state,
      start: {Cachex, :start_link, [@cache, cachex_opts]}
    }
  end

  def put_buffer_state(source_id, buffer) when is_atom(source_id) do
    Cachex.put(@cache, source_id, buffer)
  end

  def get_buffer_state(source_id) when is_atom(source_id) do
    Cachex.get(@cache, source_id)
  end

  def dirty_len(source_id) when is_atom(source_id) do
    case get_buffer_state(source_id) do
      {:ok, nil} ->
        0

      {:ok, state} ->
        :queue.len(state.buffer)

      {:error, _} ->
        0
    end
  end
end
