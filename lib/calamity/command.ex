defprotocol Calamity.Command do
  @moduledoc """
  A request for change in your system.

  Commands are issued outside of your CQRS system, and instruct an aggregate to update.
  """

  @doc """
  Returns a tuple of the aggregate module and aggregate ID that this command should act upon.
  """
  def aggregate(command)
end
