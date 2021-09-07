defmodule Calamity.ProcessManager.Base do
  @moduledoc """
  Base module for Calamity's process managers.

  Calamity needs to know if a process manager should be called for a given event,
  and which process manager to call.
  Pass a module implementing this behavior to `Calamity.dispatch/5`.
  """

  @doc """
  Control whether a process manager should be called for this event.
  """
  @callback interested?(any()) :: {:start, any()} | {:continue, any()} | {:stop, any()}

  @doc """
  Create a new process manager with the given ID.
  """
  @callback new(any()) :: Calamity.ProcessManager.t()

  def handle_event(mod, pms, event) do
    {interest, id} = mod.interested?(event)

    pms =
      case interest do
        :start -> Map.put_new_lazy(pms, id, fn -> mod.new(id) end)
        :continue -> pms
        :stop -> Map.delete(pms, id)
      end

    Access.get_and_update(pms, id, fn
      nil ->
        {[], :pop}

      pm ->
        pm = Calamity.ProcessManager.apply(pm, event)
        commands = Calamity.ProcessManager.handle(pm, event)
        {commands, pm}
    end)
  end
end
