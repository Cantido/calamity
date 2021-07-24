defprotocol Calamity.ProcessManager do
  @moduledoc """
  Coordinates aggregates by emitting commands based on events.
  """

  @doc """
  Update the process manager's state based on the event.
  """
  def apply(pm, event)

  @doc """
  Emits commands in response to events.
  """
  def handle(pm, event)
end
