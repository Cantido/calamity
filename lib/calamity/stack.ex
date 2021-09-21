# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Stack do
  @moduledoc """
  The state object of `Calamity`.
  This object contains all the stores and metadata necessary for command dispatch.
  """

  @enforce_keys [
    :aggregate_store,
    :aggregate_versions,
    :event_store,
    :process_manager_mods,
    :process_manager_store
  ]
  defstruct [
    aggregate_store: %{},
    aggregate_versions: %{},
    event_store: %Calamity.EventStore.ListEventStore{},
    process_manager_mods: [],
    process_manager_store: %{},
    process_manager_versions: %{}
  ]

  @doc """
  Use a certain aggregate store the stack.

  Aggregates will be caught up with the event store the first time a command is addressed to them.
  If your aggregates have a certain state, then you should pass in their versions as a second argument to make sure that the aggregate will not be sent events it has already seen before.
  """
  def put_aggregate_store(%__MODULE__{} = stack, aggregate_store, aggregate_versions \\ %{}),
    do: %{ stack | aggregate_store: aggregate_store, aggregate_versions: aggregate_versions }

  @doc """
  Use a certain event store in the stack.
  """
  def put_event_store(%__MODULE__{} = stack, event_store),
    do: %{ stack | event_store: event_store }

  @doc """
  Use a certain process manager store in the stack.

  Process managers will be caught up the first time they are interested in an event.
  If your process manage store contains process managers with a previous state,
  then you should pass in their versions as a second argument to make sure that the process manager will not see events that it has already seen before.
  """
  def put_process_manager_store(%__MODULE__{} = stack, process_manager_store, process_manager_versions \\ %{}),
    do: %{ stack | process_manager_store: process_manager_store, process_manager_versions: process_manager_versions }

  @doc """
  Add a process manager to the stack.
  """
  def add_process_manager_module(%__MODULE__{} = stack, process_manager_module),
    do: %{ stack | process_manager_mods: [process_manager_module | stack.process_manager_mods]}
end
