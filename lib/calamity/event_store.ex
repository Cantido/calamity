# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defprotocol Calamity.EventStore do
  @moduledoc """
  Publishes events.
  """

  @doc """
  Push new events into an event stream.

  ## Options

  - `expected_version` - used for optimistic concurrency checks. The value can be:
    - a non-negative integer - only append an event if the current version of the stream is this value
    - `:any` (default) - don't check the version of the stream, just append the event
    - `:no_stream` - assert that the stream does not exist before appending

  ## Return values

  - `{:ok, store}` if the append was successful
  - `{:error, :stream_exists}` if a stream exists while the `expected_version: :no_stream` option is set
  """
  def append(store, stream_id, events, opts \\ [])

  @doc """
  Returns a `Stream` of events in the store.

  The `stream_id` can be a string stream ID or `:all` to return all events.

  ## Options

  - `direction` - the direction in time that the events should be ordered.
    - `:forwards` (default) - first element of the enumerable is the earliest recorded event.
    - `:backwards` - the first element of the enumerable is the latest recorded event.
  - `start_version` - the version number of the first event to return.
  """
  def stream(store, stream_id, opts \\ [])

  @doc """
  Subscribes the given PID to be sent events when new events are appended.
  """
  def subscribe(store, stream_id, pid)
end
