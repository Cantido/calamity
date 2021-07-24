defmodule Calamity.BankAccount do
  defstruct [
    :account_id,
    :balance,
    :name
  ]

  def new(id) do
    %Calamity.BankAccount{
      account_id: id
    }
  end

  defimpl Calamity.Aggregate  do
    def id(account) do
      account.account_id
    end

    def execute(account, %Calamity.Commands.CreateAccount{}) do
      %Calamity.Events.AccountCreated{account_id: account.account_id, balance: 0}
    end

    def execute(account, %Calamity.Commands.RenameAccount{name: name}) do
      %Calamity.Events.AccountRenamed{account_id: account.account_id, name: name}
    end

    def apply(account, %Calamity.Events.AccountCreated{balance: balance}) do
      %{account | balance: balance}
    end

    def apply(account, %Calamity.Events.AccountRenamed{name: name}) do
      %{account | name: name}
    end
  end
end
