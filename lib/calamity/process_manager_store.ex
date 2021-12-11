# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defprotocol Calamity.ProcessManagerStore do
  @moduledoc """
  Stores `Calamity.ProcessManager` objects.
  """

  @doc """
  Update a process manager and produce new commands from the given event.

  Returns `{commands, store}`.
  """
  def handle_event(store, event, process_manager_modules)
end

defimpl Calamity.ProcessManagerStore, for: Map do
  def handle_event(store, event, process_manager_modules) do
    combinations([event], process_manager_modules)
    |> Enum.reduce({[], store}, fn {event, mod}, {commands, process_managers} ->
      {new_commands, new_process_managers} =
        Map.get_and_update(process_managers, mod, fn
          nil ->
            Calamity.ProcessManager.Base.handle_event(mod, %{}, event)

          pms_for_mod ->
            Calamity.ProcessManager.Base.handle_event(mod, pms_for_mod, event)
        end)

      {normalize_to_list(new_commands) ++ commands, new_process_managers}
    end)
  end

  defp combinations(a, b) do
    Enum.flat_map(a, fn a_elem ->
      Enum.map(b, fn b_elem ->
        {a_elem, b_elem}
      end)
    end)
  end

  defp normalize_to_list(nil), do: []
  defp normalize_to_list(items) when is_list(items), do: items
  defp normalize_to_list(item), do: [item]
end
