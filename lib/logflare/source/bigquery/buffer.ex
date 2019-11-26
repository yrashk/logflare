defmodule Logflare.Source.BigQuery.Buffer do
  @moduledoc false
  use GenServer
  alias Logflare.LogEvent, as: LE
  alias Logflare.Source.RecentLogsServer, as: RLS
  alias Logflare.Source
  alias Logflare.Sources
  alias Logflare.Tracker

  require Logger

  @broadcast_every 1_000

  def start_link(%RLS{source_id: source_id}) when is_atom(source_id) do
    GenServer.start_link(
      __MODULE__,
      %{
        source_id: source_id,
        buffer: :queue.new(),
        read_receipts: %{}
      },
      name: name(source_id)
    )
  end

  def init(state) do
    Process.flag(:trap_exit, true)

    Sources.Buffers.put_buffer_state(state.source_id, state)

    {:ok, state, {:continue, :boot}}
  end

  def handle_continue(:boot, state) do
    check_buffer()

    {:noreply, state}
  end

  def push(source_id, %LE{} = log_event) do
    GenServer.cast(name(source_id), {:push, log_event})
  end

  def pop(source_id) do
    GenServer.call(name(source_id), :pop)
  end

  def ack(source_id, log_event_id) do
    GenServer.call(name(source_id), {:ack, log_event_id})
  end

  def get_count(source_id) do
    GenServer.call(name(source_id), :get_count)
  end

  def dirty_len(source_id) do
    Sources.Buffers.dirty_len(source_id)
  end

  def handle_cast({:push, %LE{} = event}, state) do
    {:ok, ets_state} = Sources.Buffers.get_buffer_state(state.source_id)
    new_buffer = :queue.in(event, ets_state.buffer)
    ets_new_state = %{ets_state | buffer: new_buffer}
    Sources.Buffers.put_buffer_state(state.source_id, ets_new_state)
    {:noreply, state}
  end

  def handle_call(:pop, _from, state) do
    {:ok, ets_state} = Sources.Buffers.get_buffer_state(state.source_id)

    case :queue.is_empty(ets_state.buffer) do
      true ->
        {:reply, :empty, state}

      false ->
        {{:value, %LE{} = log_event}, new_buffer} = :queue.out(ets_state.buffer)
        new_read_receipts = Map.put(ets_state.read_receipts, log_event.id, log_event)

        ets_new_state = %{ets_state | buffer: new_buffer, read_receipts: new_read_receipts}

        Sources.Buffers.put_buffer_state(state.source_id, ets_new_state)

        {:reply, log_event, state}
    end
  end

  def handle_call({:ack, log_event_id}, _from, state) do
    {:ok, ets_state} = Sources.Buffers.get_buffer_state(state.source_id)

    case ets_state.read_receipts == %{} do
      true ->
        {:reply, :empty, state}

      false ->
        {%LE{} = log_event, new_read_receipts} = Map.pop(ets_state.read_receipts, log_event_id)
        ets_new_state = %{ets_state | read_receipts: new_read_receipts}

        Sources.Buffers.put_buffer_state(state.source_id, ets_new_state)

        {:reply, log_event, state}
    end
  end

  def handle_call(:get_count, _from, state) do
    {:ok, ets_state} = Sources.Buffers.get_buffer_state(state.source_id)
    count = :queue.len(ets_state.buffer)
    {:reply, count, state}
  end

  def handle_info(:check_buffer, state) do
    if Source.Data.get_ets_count(state.source_id) > 0 do
      broadcast_buffer(state)
    end

    check_buffer()

    {:noreply, state}
  end

  def terminate(reason, _state) do
    # Do Shutdown Stuff
    Logger.info("Going Down: #{__MODULE__}")
    reason
  end

  defp broadcast_buffer(state) do
    buffer = Tracker.Cache.get_cluster_buffer(state.source_id)

    payload = %{
      buffer: buffer,
      source_token: state.source_id
    }

    Source.ChannelTopics.broadcast_buffer(payload)
  end

  defp check_buffer() do
    Process.send_after(self(), :check_buffer, @broadcast_every)
  end

  def name(source_id) do
    String.to_atom("#{source_id}" <> "-buffer")
  end
end
