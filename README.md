<!--
SPDX-FileCopyrightText: 2021 Rosa Richter

SPDX-License-Identifier: MIT
-->

# Calamity

[![builds.sr.ht status](https://builds.sr.ht/~cosmicrose/calamity.svg)](https://builds.sr.ht/~cosmicrose/calamity)
[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg)](https://github.com/RichardLitt/standard-readme)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code_of_conduct.md)

An event-sourcing library with a focus on pure functions and protocols.

Calamity is structured similarly to Commanded,
and it is a goal of this project to support Commanded components via structs implementing Calamity protocols.

Useful implementations of these protocols are not currently provided.
Calamity only dispatches commands to the given aggregate and process manager stores,
and you must provide the stores yourself.

This project is in the experimental stage; do not use it in production.

## Usage

Using Calamity means implementing a few protocols and behaviors.
See `test/support` for a simplified example of how to use this library in a single process.

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

Read [`guides/plugins.md`](guides/plugins.md) for examples of aggregate and process manager stores,
as well as an over-simplified list store for events.


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

Read [`guides/plugins.md`](guides/plugins.md) for examples of aggregate and process manager stores,
as well as an over-simplified list store for events.

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

This library does not implement its own event store or aggregate store.
If you're just getting started, use maps like in the examples, and wrap calls in a `GenServer` to ensure sequential access.

Read [`guides/plugins.md`](guides/plugins.md) for examples of aggregate and process manager stores,
as well as an over-simplified list store for events.

## Maintainer

This project was developed by [Rosa Richter](https://about.me/rosa.richter).
You can get in touch with her on [Keybase.io](https://keybase.io/cantido).

## Contributing

Questions and pull requests are more than welcome.
I follow Elixir's tenet of bad documentation being a bug,
so if anything is unclear, please [file an issue](https://todo.sr.ht/~cosmicrose/calamity) or ask on the [mailing list]!
Ideally, my answer to your question will be in an update to the docs.

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for all the details you could ever want about helping me with this project.

Note that this project is released with a Contributor [Code of Conduct].
By participating in this project you agree to abide by its terms.

## License

MIT License

Copyright 2021 Rosa Richter

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[Code of Conduct]: code_of_conduct.md
[mailing list]: https://lists.sr.ht/~cosmicrose/calamity
