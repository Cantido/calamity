# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

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

  defmacro __using__(_opts) do
    quote do
      @behaviour Calamity.Aggregate.Base
      @after_compile __MODULE__

      defmacro __after_compile__(_env, _bytecode) do
        Protocol.assert_impl!(Calamity.Aggregate, __MODULE__)
      end
    end
  end
end
