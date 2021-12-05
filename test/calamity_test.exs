# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule CalamityTest do
  use ExUnit.Case, async: true
  doctest Calamity

  test "dispatch with no matching aggregate" do
    store =
      %Calamity.EventStore.ListEventStore{}
      |> Calamity.EventStore.subscribe(:all, self())

    stack = %Calamity.Stack{
      event_store: store
    }

    Calamity.dispatch(
      stack,
      %Calamity.Commands.CreateAccount{account_id: "1"}
    )

    assert_receive {:events, [event]}
    assert event == %Calamity.Events.AccountCreated{account_id: "1", balance: 0}
  end

  test "dispatch with matching aggregate" do
    store =
      %Calamity.EventStore.ListEventStore{}
      |> Calamity.EventStore.subscribe(:all, self())

    stack = %Calamity.Stack{
      event_store: store,
      aggregate_store: %{"1" => %Calamity.BankAccount{account_id: "1", name: "Old account name", balance: 100}}
    }

    Calamity.dispatch(
      stack,
      %Calamity.Commands.RenameAccount{account_id: "1", name: "New account name"}
    )

    assert_receive {:events, [event]}
    assert event == %Calamity.Events.AccountRenamed{account_id: "1", name: "New account name"}
  end

  test "dispatch with process manager" do
    store =
      %Calamity.EventStore.ListEventStore{}
      |> Calamity.EventStore.subscribe(:all, self())

    stack = %Calamity.Stack{
      event_store: store,
      aggregate_store: %{
        "1" => %Calamity.BankAccount{account_id: "1", name: "From account", balance: 100},
        "2" => %Calamity.BankAccount{account_id: "2", name: "To account", balance: 0}
      },
      process_manager_mods: [Calamity.ProcessManagers.Transfer],
      process_manager_store: %{Calamity.ProcessManagers.Transfer => %{}}
    }

    Calamity.dispatch(
      stack,
      %Calamity.Commands.RequestTransfer{
        from: "1",
        to: "2",
        amount: 100,
        transfer_id: "asdfasdfasdf"
      }
    )

    assert_receive {:events,
                    [%Calamity.Events.TransferInitiated{from: "1", to: "2", amount: 100}]}

    assert_receive {:events, [%Calamity.Events.FundsWithdrawn{account_id: "1", amount: 100}]}
    assert_receive {:events, [%Calamity.Events.FundsDeposited{account_id: "2", amount: 100}]}
  end

  test "catches up with the event store" do
    first = %Calamity.Events.AccountCreated{account_id: "1", balance: 100}

    store =
      %Calamity.EventStore.ListEventStore{}
      |> Calamity.EventStore.append("1", [first])
      |> Calamity.EventStore.subscribe(:all, self())

    stack = %Calamity.Stack{event_store: store}

    stack = Calamity.dispatch(
      stack,
      %Calamity.Commands.DepositFunds{account_id: "1", amount: 100}
    )

    assert stack.aggregate_store["1"].balance == 200
  end
end
