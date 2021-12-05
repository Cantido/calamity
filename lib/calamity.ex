# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity do
  @moduledoc """
  Documentation for `Calamity`.
  """

  alias Calamity.Aggregate
  alias Calamity.Command
  alias Calamity.Stack

  require Logger

  @doc """
  Executes a command, and return the updated aggregates, process managers, and event store.

  Calamity is protocol-driven, which means that all arguments to this function only need to implement the correct protocols.

  - `command` must implement `Calamity.Command`
  - `aggregates` must implement `Access`, and contain structs implementing `Calamity.Aggregate`
  - `process_manager_modules` must implement `Enumerable` and contain modules
  - `process_managers` must implement `Access` at two levels
  - `event_store` must implement `Calamity.EventStore` and `Collectable`
  """
  def dispatch(stack, command) do
    Logger.debug("Processing command #{inspect(command, pretty: true)}")

    {agg_mod, agg_id} = Command.aggregate(command)

    agg_version = Access.get(stack.aggregate_versions, agg_id, 0)
    missed_events =
      Calamity.EventStore.stream(stack.event_store, agg_id, start_version: agg_version)
      |> Enum.map(&elem(&1, 0))

    if Enum.count(missed_events) > 0 do
      Logger.info("Catching up aggregate #{inspect agg_id} with #{Enum.count(missed_events)} new events")
    end

    {events, new_aggregates} =
      Access.get_and_update(stack.aggregate_store, agg_id, fn
        nil ->
          aggregate = Enum.reduce(missed_events, agg_mod.new(agg_id), &Aggregate.apply(&2, &1))

          events =
            Aggregate.execute(aggregate, command)
            |> normalize_to_list()

          new_aggregate = Enum.reduce(events, aggregate, &Aggregate.apply(&2, &1))

          {events, new_aggregate}

        aggregate ->
          aggregate = Enum.reduce(missed_events, aggregate, &Aggregate.apply(&2, &1))

          events =
            Aggregate.execute(aggregate, command)
            |> normalize_to_list()

          new_aggregate = Enum.reduce(events, aggregate, &Aggregate.apply(&2, &1))

          {events, new_aggregate}
      end)

    Logger.debug("Aggregate emitted events #{inspect(events, pretty: true)}")

    {new_commands, new_process_managers} =
      combinations(events, stack.process_manager_mods)
      |> Enum.reduce({[], stack.process_manager_store}, fn {event, mod}, {commands, process_managers} ->
        {new_commands, new_process_managers} =
          Access.get_and_update(process_managers, mod, fn
            nil ->
              Calamity.ProcessManager.Base.handle_event(mod, %{}, event)

            pms_for_mod ->
              Calamity.ProcessManager.Base.handle_event(mod, pms_for_mod, event)
          end)

        {normalize_to_list(new_commands) ++ commands, new_process_managers}
      end)

    Logger.debug("Process managers emitted commands #{inspect(new_commands, pretty: true)}")

    event_store = Calamity.EventStore.append(stack.event_store, agg_id, events)

    stack = %Stack{ stack |
      aggregate_store: new_aggregates,
      process_manager_store: new_process_managers,
      event_store: event_store
    }

    Enum.reduce(new_commands, stack, fn new_command, stack ->
      dispatch(stack, new_command)
    end)
  end

  defp combinations(a, b) do
    Enum.flat_map(a, fn a_elem ->
      Enum.map(b, fn b_elem ->
        {a_elem, b_elem}
      end)
    end)
  end

  defp normalize_to_list(nil), do: []
  defp normalize_to_list(items) when is_list(items), do: items
  defp normalize_to_list(item), do: [item]

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
