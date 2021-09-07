defmodule Calamity.ListEventStore do
  defstruct events: [],
            subscribers: []

  defimpl Calamity.EventStore do
    def append(store, event) do
      Enum.each(store.subscribers, fn subscriber ->
        send(subscriber, {:events, [event]})
      end)

      %{store | events: store.events ++ [event]}
    end

    def all(store) do
      store.events
    end

    def subscribe(store, pid) do
      %{store | subscribers: [pid | store.subscribers]}
    end
  end

  defimpl Collectable do
    def into(event_store) do
      collector_fun = fn
        event_store_acc, {:cont, elem} ->
          Calamity.EventStore.append(event_store_acc, elem)

        event_store_acc, :done ->
          event_store_acc

        _event_store_acc, :halt ->
          :ok
      end

      {event_store, collector_fun}
    end
  end
end
