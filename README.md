# Calamity

An event-sourcing library with a focus on pure functions and protocols.

Calamity is structured similarly to Commanded,
and it is a goal of this project to support Commanded components via structs implementing Calamity protocols.

Useful implementations of these protocols are not currently provided.
Calamity only dispatches commands to the given aggregate and process manager stores,
and you must provide the stores yourself.

This project is in the experimental stage; do not use it in production.

## Usage

Using Calamity means implementing a few protocols and behaviors.
See `test/support` for an example.

### Event Stores

To create an event store, you must implement `Calamity.EventStore` and `Collectible`.
The `Calamity.EventStore` behavior defines the basics of subscribing to events,
and `Collectable` is used to insert new events into the store.

```elixir
defmodule Calamity.ListEventStore do
  defstruct [
    ...
  ]

  defimpl Calamity.EventStore do
    ...
  end

  defimpl Collectable do
    ...
  end
end
```
### Aggregates

To create an aggregate, `use` the `:aggregate` macro available in the main `Calamity` module,
then implement the `Calamity.Aggregate` protocol.

```elixir
defmodule MyApp.BankAccount do
  use Calamity, :aggregate

  defstruct [
    ...
  ]

  def new(id) do
    ...
  end

  defimpl Calamity.Aggregate do
    ...
  end
end
```

### Aggregate Stores

To update and store aggregates, the `Calamity.dispatch/5` function requires a struct implementing the `Access` protocol.
Aggregates must be accessed by ID and return a struct implementing the `Calamity.Aggregate` protocol.

Calamity uses `Access.get_and_update/3` to transactionally update the aggregate in the store and return events.
This means that Calamity supports aggregates stored in GenServers as well as simple maps.

### Events

Events need no protocol, so you can use plain structs.

```elixir
defmodule MyApp.Events.AccountCreated do
  defstruct [
    ...
  ]
end
```

### Commands

Commands must implement the `Calamity.Command` protocol.

```elixir
defmodule MyApp.Commands.DepositFunds do
  defstruct [
    ...
  ]

  defimpl Calamity.Command do
    ...
  end
end
```

### Process Managers

Process managers must `use` the `:process_manager` macro available in the main `Calamity` module,
then implement the `Calamity.ProcessManager` protocol.

```elixir
defmodule MyApp.ProcessManagers.Transfer do
  use Calamity, :process_manager

  defstruct [
    ...
  ]

  def new(pm_id) do
    ...
  end

  def interested?(event) do
    ...
  end
  
  defimpl Calamity.ProcessManager do
    ...
  end
end
```

### Process Manager Stores

Active process managers are stored in a multi-level data structure that must implement the `Access` protocol.
The first level maps modules to collections of process managers implementing that module,
and the second level maps IDs to specific process manager structs.
If you were to use `Map`s, the process manager store would look like this:

```elixir
%{
  MyApp.ProcessManagers.TransferFunds => %{
    "b0bda821-4bdd-4e27-ad95-f504b00a1282" => %MyApp.ProcessManagers.TransferFunds{id: ...}
  }
}
```

Calamity uses `Access.get_and_update/3` to transactionally update the process manager store and return commands.
This means that Calamity supports process managers stored in GenServers as well as simple maps.

### Dispatching Events

Events are dispatched using `Calamity.dispatch/5`.
Since Calamity uses pure functions and tries to minimize process count,
all components of the system must be passed to `dispatch/5`,
and it will return updated versions of those arguments.

The arguments to `dispatch/5` are:

1. The command (implementing the `Calamity.Command` protocol)
1. The aggregate store (implementing the `Access` protocol)
1. An enumerable of process manager modules (that `use Calamity, :process_manager`)
1. The process manager store (implementing `Access` at two levels, see above)
1. The event store (implementing the `Calamity.EventStore` and `Collectable` protocols)

This example is taken from Calamity's tests.
It is dispatching the `RequestTransfer` command to an aggregate store containing two aggregates.
The `Transfer` process manager is used, but there are currently no active process managers.
Last, the `ListEventStore` is used to store and publish events.

```elixir
Calamity.dispatch(
  %Calamity.Commands.RequestTransfer{from: "1", to: "2", amount: 100, transfer_id: "asdfasdfasdf"},
  %{
    "1" => %Calamity.BankAccount{account_id: "1", name: "From account", balance: 100},
    "2" => %Calamity.BankAccount{account_id: "2", name: "To account", balance: 0}
  },
  [Calamity.ProcessManagers.Transfer],
  %{},
  %Calamity.ListEventStore{}
)
```

This will return a tuple containing the updated aggregate store, the updated process manager store, and the updated event store.

```elixir
{new_aggregates, new_process_managers, event_store}
```

## Building on Calamity

Calamity delegates all impure functionality to its users.
This means that Calamity does not start its own processes, and does not take responsibility for protecting the aggregate store and process manager store from concurrent access.
The simplest solution to this problem is to use maps for these stores,
and to wrap calls to `Calamity.dispatch/5` in a `GenServer`.
More complicated setups can use individual GenServers for each aggregate and process manager,
with the stores being maps of process IDs,
and the store struct implementing `Access` to delegate calls to the respective GenServer.
