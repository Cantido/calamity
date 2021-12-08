defprotocol Calamity.AggregateStore do
  def dispatch(store, command)
end

defimpl Calamity.AggregateStore, for: Map do
  alias Calamity.{Aggregate, Command}

  def dispatch(store, command) do
    {agg_mod, agg_id} = Command.aggregate(command)

    Access.get_and_update(store, agg_id, fn
      nil ->
        aggregate = agg_mod.new(agg_id)
        events =
          Aggregate.execute(aggregate, command)
          |> normalize_to_list()

        new_aggregate = Enum.reduce(events, aggregate, &Aggregate.apply(&2, &1))

        {events, new_aggregate}

      aggregate ->
        events =
          Aggregate.execute(aggregate, command)
          |> normalize_to_list()

        new_aggregate = Enum.reduce(events, aggregate, &Aggregate.apply(&2, &1))

        {events, new_aggregate}
    end)
  end

  defp normalize_to_list(nil), do: []
  defp normalize_to_list(items) when is_list(items), do: items
  defp normalize_to_list(item), do: [item]
end
