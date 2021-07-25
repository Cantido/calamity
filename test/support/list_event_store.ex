defmodule Calamity.ListEventStore do
  defstruct [
    events: [],
    subscribers: []
  ]

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
end
