# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Commands.RenameAccount do
  defstruct [
    :account_id,
    :name
  ]

  defimpl Calamity.Command do
    def aggregate(command) do
      {Calamity.BankAccount, command.account_id}
    end
  end
end
