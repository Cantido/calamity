<!--
SPDX-FileCopyrightText: 2021 Rosa Richter

SPDX-License-Identifier: MIT
-->

# Plugins for Calamity

*WARNING*: These examples are subject to a lot of change while this library is under development.

## Building your own aggregate and process manager stores. 

Calamity delegates all impure functionality to its users.
This means that Calamity does not start its own processes,
and does not take responsibility for protecting the aggregate store and process manager store from concurrent access.

All updates to the aggregate store and process manager store use `Access.get_and_update/3`,
so the updates will happen atomically.

### With `GenServer`

The simplest solution to this problem is to use maps for these stores,
and to wrap calls to `Calamity.dispatch/5` in a `GenServer`.
Note that event stores can't be plain maps, see below.

```elixir
defmodule MyApp.CQRS do
  def dispatch(command) do
    GenServer.call(__MODULE__, {:dispatch, event})
  end

  def handle_call({:dispatch, command}, _from, state) do
    Calamity.dispatch(
      command,
      Map.get(state, :aggregates, %{}),
      [MyApp.MyProcessManager],
      Map.get(state, :process_managers, %{}),
      Map.get(state, :event_store, MyApp.EventStore.new()) 
    )
  end
end
```

Slightly more complex would be to use a single GenServer to store all of your aggregates.


```elixir
defmodule MyApp.Aggregate do

  # Normal `Calamity.Aggregate` implementation goes before this, see main docs.
  # `GenServer` boilerplate goes here, too.

  def handle_call({:get_and_update, aggregate_id, func}, _from, aggregates) do
    # Delegate to the existing `Access` implementation on maps
    {return_value, new_aggregates} = Access.get_and_update(aggregates, aggregate_id, func)

    {:reply, {return_value, new_aggregates}, new_aggregates}
  end

  defimpl Access do
    def get_and_update(aggregate_store_pid, aggregate_id, func) do
      GenServer.call(aggregate_store_pid, {:get_and_update, aggregate_id, func})
    end

    # Don't forget to implement `fetch/2` and `pop/2` as well.
  end
end
```

More complicated setups can use individual GenServers for each aggregate and process manager,
with the stores being maps of process IDs,
and the store struct implementing `Access` to delegate calls to the respective GenServer.

### With a Database

Create a struct that implements the `Access` protocol,
with `Access.get_and_update/3` performing the aggregate update inside a transaction.

```elixir
defmodule MyApp.Aggregate do
  
  # Normal `Calamity.Aggregate` implementation goes before this, see main docs.

  defimpl Access do
    def get_and_update(aggregate_store, aggregate_id, func) do
      MyApp.Repo.transaction(fn ->
        aggregate_from_db = MyApp.Repo.get(MyApp.Aggregate, aggregate_id)

        # `aggregate_from_db` can be `nil`, that's expected if the value does not exist yet.
        
        case func.(aggregate_from_db) do
          {func_return_value, new_aggregate} ->  
            
            # If `aggregate_from_db` is `nil`, then `func` would have created a new aggregate for us and we need to insert it.

            if is_nil(aggregate_from_db) do
              MyApp.Repo.insert!(new_aggregate)
            else
              MyApp.Repo.update!(new_aggregate)
            end

            {func_return_value, aggregate_store}

          :pop ->
            MyApp.Repo.delete!(aggregate_from_db)

            {func_return_value, aggregate_store}
        end
      end)
    end

    # Don't forget to implement `fetch/2` and `pop/2` as well.
  end
end
```
## Building your own event store

Event stores need to implement the `Calamity.EventStore` protocol, so they can't be plain data structures,
but they can still be very simple.
Check out this very basic event store that uses a list to store events:

```elixir
defmodule MyApp.ListEventStore do
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

```
