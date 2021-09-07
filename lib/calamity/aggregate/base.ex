defmodule Calamity.Aggregate.Base do
  @moduledoc """
  The base module for any aggregate.
  Calamity needs a factory function to build new aggregates when one does not exist.
  This module provides a behaviour to make sure it will work as expected when you hand it to `Calamity`.

  Do not use this module directly, import it with `use Calamity, :aggregate`.
  """

  @doc """
  Build a new aggregate struct.

  This function will be called with the ID result of `Calamity.Command.aggregate/1`.
  """
  @callback new(any()) :: Calamity.Aggregate.t()
end
