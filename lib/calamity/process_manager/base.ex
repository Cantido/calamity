defmodule Calamity.ProcessManager.Base do
  @callback interested?(any()) :: {:start, any()} | {:continue, any()} | {:stop, any()}
  @callback new(any()) :: Calamity.ProcessManager.t()

  def handle_event(mod, pms, event) do
    {interest, id} = mod.interested?(event)

    pms =
      case interest do
        :start -> Map.put_new_lazy(pms, id, fn -> mod.new(id) end)
        :continue -> pms
        :stop -> Map.delete(pms, id)
      end

    {commands, pms} =
      Access.get_and_update(pms, id,
      fn
        nil ->
          {[], :pop}
        pm ->
          pm = Calamity.ProcessManager.apply(pm, event)
          commands = Calamity.ProcessManager.handle(pm, event)
          {commands, pm}
      end)

    {pms, commands}
  end
end
