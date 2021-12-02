# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.EventStore.ListEventStore do
  @moduledoc """
  A simple in-memory event store.
  """

  alias Calamity.EventMetadata

  defstruct streams: %{},
            subscribers: %{}

  defimpl Calamity.EventStore do
    def append(store, stream_id, events, _opts) do
      Map.get(store.subscribers, stream_id, [])
      |> Enum.each(fn subscriber ->
        Process.send(subscriber, {:events, events}, [])
      end)

      new_events =
        Enum.map(events, fn event ->
          {event, %EventMetadata{created_at: DateTime.utc_now()}}
        end)

      updated_streams =
        store.streams
        |> Map.put_new(stream_id, [])
        |> Map.update!(stream_id, fn previous_events -> previous_events ++ new_events end)

      %{store | streams: updated_streams}
    end

    def stream(store, :all, _opts) do
      Map.values(store.streams)
      |> Enum.concat()
      |> Enum.sort_by(fn {_event, metadata} ->
        metadata.created_at
      end,
      DateTime)
    end

    def stream(store, stream_id, _opts) do
      Map.get(store.streams, stream_id, [])
    end

    def subscribe(store, stream_id, pid) do
      new_subscribers =
        Map.update(store.subscribers, stream_id, [pid], &[pid | &1])

      %{store | subscribers: new_subscribers}
    end
  end
end
