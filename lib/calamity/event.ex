# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defprotocol Calamity.Event do
  @moduledoc """
  An artifact of change.

  An Event describes a change in your system.
  It is created by an aggregate in response to a command.
  """
end
