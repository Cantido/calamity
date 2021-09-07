defmodule Calamity.Commands.CreateAccount do
  @derive {Calamity.Command, mod: Calamity.BankAccount, key: :account_id}
  defstruct [
    :account_id
  ]
end
