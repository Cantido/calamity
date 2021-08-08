defmodule Calamity.Aggregate.Base do
  @callback new(any()) :: Calamity.Aggregate.t()
end
