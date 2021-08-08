defmodule Calamity do
  @moduledoc """
  Documentation for `Calamity`.
  """

  alias Calamity.Aggregate
  alias Calamity.Command
  alias Calamity.EventStore

  def dispatch(command, aggregates, process_managers, event_store) do
    {agg_mod, agg_id} = Command.aggregate(command)

    aggregate = Map.get(aggregates, agg_id, agg_mod.new(agg_id))

    events =
      Aggregate.execute(aggregate, command)
      |> normalize_to_list()

    new_aggregate = Enum.reduce(events, aggregate, &Aggregate.apply(&2, &1))


    %{pm_map: new_process_managers, commands: new_commands} =
      combinations(events, process_managers)
      |> Enum.map(fn {event, {mod, pms}} ->
        Task.Supervisor.async(Calamity.ProcessManager.TaskSupervisor, fn ->
          {pms, new_commands} = Calamity.ProcessManager.Base.handle_event(mod, pms, event)
          {mod, pms, new_commands}
        end)
      end)
      |> Task.await_many()
      |> Enum.reduce(%{pm_map: %{}, commands: []}, fn {mod, pms, new_commands}, %{pm_map: pm_map, commands: commands} ->
        %{
          pm_map: Map.put(pm_map, mod, pms),
          commands: normalize_to_list(new_commands) ++ commands
        }
      end)

    new_aggregates = Map.put(aggregates, agg_id, new_aggregate)
    event_store = Enum.reduce(events, event_store, &EventStore.append(&2, &1))

    Enum.reduce(new_commands, {new_aggregates, new_process_managers, event_store}, fn new_command, {aggs, pms, es} ->
      dispatch(new_command, aggs, pms, es)
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
      @behaviour Calamity.Aggregate.Base
    end
  end

  def process_manager do
    quote do
      @behaviour Calamity.ProcessManager.Base
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
