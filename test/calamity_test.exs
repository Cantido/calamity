defmodule CalamityTest do
  use ExUnit.Case
  doctest Calamity

  test "greets the world" do
    assert Calamity.hello() == :world
  end
end
