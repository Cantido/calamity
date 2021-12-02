# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.EventMetadata do
  @moduledoc """
  Extra information about an event.
  """

  @enforce_keys [
    :created_at
  ]
  defstruct [
    :created_at
  ]
end
