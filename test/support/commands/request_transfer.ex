defmodule Calamity.Commands.RequestTransfer do
  defstruct [
    :transfer_id,
    :from,
    :to,
    :amount
  ]

  defimpl Calamity.Command do
    def aggregate(command) do
      {Calamity.BankAccount, command.from}
    end
  end
end
