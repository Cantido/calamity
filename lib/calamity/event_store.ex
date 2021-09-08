# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defprotocol Calamity.EventStore do
  @moduledoc """
  Publishes events.
  """

  @doc """
  Push a new event into the event store.
  """
  def append(store, event)

  @doc """
  Returns an enumerable of all events in the store.
  """
  def all(store)

  @doc """
  Subscribes the given process to be sent events when new events are appended.
  """
  def subscribe(store, pid)
end
