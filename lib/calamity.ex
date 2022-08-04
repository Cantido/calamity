# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity do
  @moduledoc """
  Documentation for `Calamity`.
  """

  alias Calamity.Command
  alias Calamity.Stack
  alias Calamity.AggregateStore
  alias Calamity.ProcessManagerStore
  alias Calamity.VersionStore

  require Logger

  @doc """
  Executes a command, and return the updated aggregates, process managers, and event store.

  Calamity is protocol-driven, which means that all arguments to this function only need to implement the correct protocols.

  - `command` must implement `Calamity.Command`
  - `aggregates` must implement `Calamity.AggregateStore`, and contain structs implementing `Calamity.Aggregate`
  - `process_manager_modules` must implement `Enumerable` and contain modules
  - `process_managers` must implement `Calamity.ProcessManagerStore`.
  - `event_store` must implement `Calamity.EventStore`
  """
  def dispatch(stack, command) do
    Logger.debug("Processing command #{inspect(command, pretty: true)}")

    {stack, events} = execute(stack, command)

    Logger.debug("Aggregate emitted events #{inspect(events, pretty: true)}")

    {new_commands, new_process_managers} =
      Enum.reduce(events, {[], stack.process_manager_store}, fn event, {commands, store} ->
        {new_commands, store} = ProcessManagerStore.handle_event(store, event, stack.process_manager_mods)
        {new_commands ++ commands, store}
      end)

    Logger.debug("Process managers emitted commands #{inspect(new_commands, pretty: true)}")

    stack = %Stack{stack |
      process_manager_store: new_process_managers
    }

    Enum.reduce(new_commands, stack, fn new_command, stack ->
      dispatch(stack, new_command)
    end)
  end

  defp execute(stack, command) do
    {events, aggregate_store} = Calamity.AggregateStore.dispatch(stack.aggregate_store, command)

    {agg_mod, agg_id} = Command.aggregate(command)
    agg_version = Access.get(stack.aggregate_versions, agg_id, 0)
    expected_version = if agg_version == 0, do: :no_stream, else: agg_version

    Calamity.EventStore.append(stack.event_store, agg_id, events, expected_version: expected_version)
    |> case do
      {:ok, event_store} ->
        stack =
          %Stack{stack |
            event_store: event_store,
            aggregate_store: aggregate_store,
            aggregate_versions: VersionStore.increment_version(stack.aggregate_versions, agg_id, Enum.count(events))
          }
        {stack, events}
      {:error, :stream_exists} ->
        stack
        |> sync_aggregate(agg_mod, agg_id)
        |> execute(command)
    end
  end

  defp sync_aggregate(stack, agg_mod, agg_id) do
    agg_version = Access.get(stack.aggregate_versions, agg_id, 0)
    missed_events =
      Calamity.EventStore.stream(stack.event_store, agg_id, start_version: agg_version)

    if Enum.count(missed_events) > 0 do
      Logger.debug("Catching up aggregate #{inspect agg_id} with #{Enum.count(missed_events)} new events")
    end

    apply_events(stack, agg_mod, agg_id, missed_events)
  end

  defp apply_events(stack, agg_mod, agg_id, events) do
    agg_store =
      AggregateStore.apply(stack.aggregate_store, agg_mod, agg_id, events)

    new_version_store =
      VersionStore.increment_version(stack.aggregate_versions, agg_id, Enum.count(events))

    %Stack{stack | aggregate_store: agg_store, aggregate_versions: new_version_store}
  end

  def aggregate do
    quote do
      use Calamity.Aggregate.Base
    end
  end

  def process_manager do
    quote do
      use Calamity.ProcessManager.Base
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
