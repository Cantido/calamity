defmodule Calamity.Events.AccountCreated do
  defstruct [
    :account_id,
    :balance
  ]

  defimpl Calamity.Event do

  end
end
