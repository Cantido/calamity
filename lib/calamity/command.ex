# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defprotocol Calamity.Command do
  @moduledoc """
  A request for change in your system.

  Commands are issued outside of your CQRS system, and instruct an aggregate to update.

  You can either implement this protocol directly:

      defimpl Calamity.Command, for: MyCommand do
        def aggregate(command), do: {MyAggregate, command.id}
      end

  Or take a shortcut with `@derive`:

      @derive {Calamity.Command, mod: MyAggregate, key: :id}

  """

  @doc """
  Returns a tuple of the aggregate module and aggregate ID that this command should act upon.
  """
  def aggregate(command)

end

defimpl Calamity.Command, for: Any do
  defmacro __deriving__(module, _struct, options) do
    quote do
      defimpl Calamity.Command, for: unquote(module) do
        def aggregate(command) do
          aggregate_id_key = Keyword.fetch!(unquote(options), :key)
          aggregate_id = Map.get(command, aggregate_id_key)
          aggregate_module = Keyword.fetch!(unquote(options), :mod)

          {aggregate_module, aggregate_id}
        end
      end
    end
  end

  def aggregate(_command) do
    raise ArgumentError, "@derive for CalamityCommand must be {module, struct_key}"
  end
end
