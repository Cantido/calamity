defmodule Calamity.Events.FundsDeposited do
  defstruct [
    :account_id,
    :transfer_id,
    :amount,
    :balance
  ]
end
