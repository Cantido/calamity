# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Events.TransferInitiated do
  defstruct [
    :transfer_id,
    :from,
    :to,
    :amount
  ]
end
