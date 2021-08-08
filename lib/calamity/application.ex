defmodule Calamity.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Calamity.ProcessManager.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Calamity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
