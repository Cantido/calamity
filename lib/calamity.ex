defmodule Calamity do
  @moduledoc """
  Documentation for `Calamity`.
  """

  alias Calamity.Aggregate
  alias Calamity.Command

  def dispatch(command, aggregates, listeners) do
    {agg_mod, agg_id} = Command.aggregate(command)

    aggregate = Map.get_lazy(aggregates, agg_id, fn ->
      apply(agg_mod, :new, [agg_id])
    end)

    events =
      Aggregate.execute(aggregate, command)
      |> normalize_events()

    new_aggregate = Enum.reduce(events, aggregate, &Aggregate.apply(&2, &1))

    Enum.each(events, fn event ->
      Enum.each(listeners,
        fn
          {mod, fun, args} -> apply(mod, fun, args ++ [event])
          fun when is_function(fun) -> fun.(event)
        end)
    end)

    Map.put(aggregates, agg_id, new_aggregate)
  end

  defp normalize_events(nil), do: []
  defp normalize_events(events) when is_list(events), do: events
  defp normalize_events(event), do: [event]
end
