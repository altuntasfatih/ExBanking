defmodule ExBanking.Otp.RegistryTest do
  use ExUnit.Case
  alias ExBanking.Otp.UserRegistry

  @key "test_key"

  setup do
    pid = self()
    UserRegistry.register(pid, @key)
    on_exit(fn -> UserRegistry.unregister_records() end)
    %{pid: pid}
  end

  test "it should increase, decrease and look_up", %{pid: pid} do
    assert 3 = UserRegistry.increase_operation_count(@key, 3)
    assert 2 = UserRegistry.decrease_operation_count(@key, 1)
    assert {:ok, {@key, ^pid, 2}} = UserRegistry.look_up(@key)
  end
end
