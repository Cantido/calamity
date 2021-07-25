defmodule Calamity do
  @moduledoc """
  Documentation for `Calamity`.
  """

  alias Calamity.Aggregate
  alias Calamity.Command
  alias Calamity.EventStore

  def dispatch(command, aggregates, event_store) do
    {agg_mod, agg_id} = Command.aggregate(command)

    aggregate = Map.get_lazy(aggregates, agg_id, fn ->
      apply(agg_mod, :new, [agg_id])
    end)

    events =
      Aggregate.execute(aggregate, command)
      |> normalize_events()

    new_aggregate = Enum.reduce(events, aggregate, &Aggregate.apply(&2, &1))
    event_store = Enum.reduce(events, event_store, &EventStore.append(&2, &1))

    new_aggregates = Map.put(aggregates, agg_id, new_aggregate)

    {new_aggregates, event_store}
  end

  defp normalize_events(nil), do: []
  defp normalize_events(events) when is_list(events), do: events
  defp normalize_events(event), do: [event]
end
