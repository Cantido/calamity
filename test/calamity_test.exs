defmodule CalamityTest do
  use ExUnit.Case
  doctest Calamity

  test "dispatch with no matching aggregate" do
    store =
      %Calamity.ListEventStore{}
      |> Calamity.EventStore.subscribe(self())

    Calamity.dispatch(
      %Calamity.Commands.CreateAccount{account_id: "1"},
      %{},
      [],
      %{},
      store
    )

    assert_receive {:events, [event]}
    assert event == %Calamity.Events.AccountCreated{account_id: "1", balance: 0}
  end

  test "dispatch with matching aggregate" do
    store =
      %Calamity.ListEventStore{}
      |> Calamity.EventStore.subscribe(self())

    Calamity.dispatch(
      %Calamity.Commands.RenameAccount{account_id: "1", name: "New account name"},
      %{"1" => %Calamity.BankAccount{account_id: "1", name: "Old account name", balance: 100}},
      [],
      %{},
      store
    )

    assert_receive {:events, [event]}
    assert event == %Calamity.Events.AccountRenamed{account_id: "1", name: "New account name"}
  end

  test "dispatch with process manager" do
    store =
      %Calamity.ListEventStore{}
      |> Calamity.EventStore.subscribe(self())

    Calamity.dispatch(
      %Calamity.Commands.RequestTransfer{
        from: "1",
        to: "2",
        amount: 100,
        transfer_id: "asdfasdfasdf"
      },
      %{
        "1" => %Calamity.BankAccount{account_id: "1", name: "From account", balance: 100},
        "2" => %Calamity.BankAccount{account_id: "2", name: "To account", balance: 0}
      },
      [Calamity.ProcessManagers.Transfer],
      %{Calamity.ProcessManagers.Transfer => %{}},
      store
    )

    assert_receive {:events,
                    [%Calamity.Events.TransferInitiated{from: "1", to: "2", amount: 100}]}

    assert_receive {:events, [%Calamity.Events.FundsWithdrawn{account_id: "1", amount: 100}]}
    assert_receive {:events, [%Calamity.Events.FundsDeposited{account_id: "2", amount: 100}]}
  end
end
