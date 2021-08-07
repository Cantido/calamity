defmodule Calamity.Commands.DepositFunds do
  defstruct [
    :account_id,
    :transfer_id,
    :amount
  ]

  defimpl Calamity.Command do
    def aggregate(%{account_id: id}) do
      {Calamity.BankAccount, id}
    end
  end
end
