<!--
SPDX-FileCopyrightText: 2021 Rosa Richter

SPDX-License-Identifier: MIT
-->

# Plugins for Calamity

*WARNING*: These examples are subject to a lot of change while this library is under development.

## Building your own aggregate and process manager stores. 

Calamity is built around structs implementing its core protocols.
The benefit of this approach is that an event-source system can be built up simply using in-memory data in a single process,
but protocol implementations can then be created that start new processes, wrap GenServers, etc.

All updates to the aggregate store and process manager store use a single function call,
either `Calamity.AggregateStore.dispatch/2` or `Calamity.ProcessManagerStore.handle_event/3`, respectively.
That way the updates can be performed atomically.

### With a single `GenServer`

The simplest solution to this problem is to use maps for these stores,
and to wrap calls to `Calamity.dispatch/2` in a `GenServer`.

```elixir
defmodule MyApp.CQRS do
  def dispatch(command) do
    GenServer.call(__MODULE__, {:dispatch, event})
  end

  def handle_call({:dispatch, command}, _from, stack) do
    updated_stack = Calamity.dispatch(stack, command)

    {:reply, :ok, updated_stack}
  end
end
```

Slightly more complex would be to use a single GenServer to store all of your aggregates.

```elixir
defmodule MyApp.AggregateStore do
  def handle_call({:dispatch, command}, _from, aggregates) do
    # Delegate to the existing `Calamity.AggregateStore` implementation on maps
    {return_value, new_aggregates} = Calamity.AggregateStore.dispatch(aggregates, command)

    {:reply, {return_value, new_aggregates}, new_aggregates}
  end

  defimpl Calamity.AggregateStore do
    def dispatch(%MyApp.Aggregate{pid: pid}, command) do
      GenServer.call(pid, {:dispatch, command})
    end
  end
end
```

More complicated setups can use individual GenServers for each aggregate and process manager,
with the stores being maps of process IDs,
and the store struct implementing `Calamity.AggregateStore` to delegate calls to the respective GenServer.

## Building your own event store

Event stores need to implement the `Calamity.EventStore` protocol, so they can't be plain data structures,
but they can still be very simple.
Check out `Calamity.EventStore.ListEventStore` for a basic in-memory event store.
