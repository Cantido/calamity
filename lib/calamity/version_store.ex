# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defprotocol Calamity.VersionStore do
  @moduledoc """
  Stores version numbers for aggreagtes and process managers.
  """

  @doc """
  Increase a version number.
  """
  def increment_version(store, id, amount)
end

defimpl Calamity.VersionStore, for: Map do
  def increment_version(store, id, count) do
    Map.update(store, id, count, fn version -> version + count end)
  end
end
