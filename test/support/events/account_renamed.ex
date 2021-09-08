# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Events.AccountRenamed do
  defstruct [
    :account_id,
    :name
  ]
end
