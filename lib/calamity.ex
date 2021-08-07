defmodule Calamity do
  @moduledoc """
  Documentation for `Calamity`.
  """

  alias Calamity.Aggregate
  alias Calamity.Command
  alias Calamity.EventStore

  require Logger

  def dispatch(command, aggregates, process_managers, event_store) do
    Logger.info("dispatching command #{inspect command}")
    {agg_mod, agg_id} = Command.aggregate(command)

    aggregate = Map.get(aggregates, agg_id, struct!(agg_mod))

    events =
      Aggregate.execute(aggregate, command)
      |> normalize_to_list()

    new_aggregate = Enum.reduce(events, aggregate, &Aggregate.apply(&2, &1))


    Logger.info("Resulting events: #{inspect events}")

    %{pm_map: new_process_managers, commands: new_commands} =
      Enum.reduce(events, %{pm_map: %{}, commands: []}, fn event, results_map ->
        Enum.reduce(process_managers, results_map, fn {mod, pms},  %{pm_map: pm_map, commands: commands} ->

          {pms, new_commands} = Calamity.ProcessManager.Base.handle_event(mod, pms, event)

          %{
            pm_map: Map.put(pm_map, mod, pms),
            commands: normalize_to_list(new_commands) ++ commands
          }
        end)
      end)

    Logger.info("Commands: #{inspect new_commands}")

    new_aggregates = Map.put(aggregates, agg_id, new_aggregate)
    event_store = Enum.reduce(events, event_store, &EventStore.append(&2, &1))

    Enum.reduce(new_commands, {new_aggregates, new_process_managers, event_store}, fn new_command, {aggs, pms, es} ->
      dispatch(new_command, aggs, pms, es)
    end)
  end

  defp normalize_to_list(nil), do: []
  defp normalize_to_list(items) when is_list(items), do: items
  defp normalize_to_list(item), do: [item]
end
