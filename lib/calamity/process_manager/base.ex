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

    if pm = Map.get(pms, id) do
      pm = Calamity.ProcessManager.apply(pm, event)
      commands = Calamity.ProcessManager.handle(pm, event)

      {Map.put(pms, id, pm), commands}
    else
      {pms, []}
    end
  end
end
