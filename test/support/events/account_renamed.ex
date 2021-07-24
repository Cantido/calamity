defmodule Calamity.Events.AccountRenamed do
  defstruct [
    :account_id,
    :name
  ]

  defimpl Calamity.Event do

  end
end
