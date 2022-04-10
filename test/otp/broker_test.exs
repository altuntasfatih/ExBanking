defmodule ExBanking.Otp.RegistryTest do
  use ExUnit.Case
  alias ExBanking.Otp.Registry

  @key "test_key"

  setup do
    pid = self()
    Registry.register(pid, @key)
    on_exit(fn -> Registry.unregister_records() end)
    %{pid: pid}
  end

  test "it should increase, decrease and look_up", %{pid: pid} do
    assert 3 = Registry.increase_operation_count(@key, 3)
    assert 2 = Registry.decrease_operation_count(@key, 1)
    assert {:ok, {@key, ^pid, 2}} = Registry.look_up(@key)
  end
end
