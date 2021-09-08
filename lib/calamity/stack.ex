# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Stack do
  defstruct [
    aggregate_store: %{},
    aggregate_versions: %{},
    event_store: %{},
    process_manager_mods: [],
    process_manager_store: %{}
  ]
end
