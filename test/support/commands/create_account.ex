# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Commands.CreateAccount do
  @derive {Calamity.Command, mod: Calamity.BankAccount, key: :account_id}
  defstruct [
    :account_id
  ]
end
