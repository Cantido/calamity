defmodule Calamity.Events.FundsWithdrawn do
  defstruct [
    :account_id,
    :transfer_id,
    :amount,
    :balance
  ]
end
