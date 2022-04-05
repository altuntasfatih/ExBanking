defmodule ExBanking.Otp.BrokerTest do
  use ExUnit.Case
  alias ExBanking.Otp.Broker

  @key "test_key"

  setup do
    pid = self()
    Broker.register(pid, @key)
    on_exit(fn -> Broker.unregister_records() end)
    %{pid: pid}
  end

  test "it should increase, decrease and look_up", %{pid: pid} do
    assert 3 = Broker.increase(@key, 3)
    assert 2 = Broker.decrease(@key, 1)
    assert {:ok, {@key, ^pid, 2}} = Broker.look_up(@key)
  end
end
