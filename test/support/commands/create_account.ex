defmodule Calamity.Commands.CreateAccount do
  defstruct [
    :account_id
  ]

  defimpl Calamity.Command do
    def aggregate(command) do
      {Calamity.BankAccount, command.account_id}
    end
  end
end
