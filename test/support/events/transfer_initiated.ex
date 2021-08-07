defmodule Calamity.Events.TransferInitiated do
  defstruct [
    :transfer_id,
    :from,
    :to,
    :amount
  ]
end
