defmodule ExBanking.Otp.UserServerTest do
  use ExUnit.Case
  alias ExBanking.Otp.{UserServer, Registry, UserSupervisor}
  alias ExBanking.Model.User

  @user_name "test"
  @currency "TL"

  setup do
    on_exit(fn ->
      Registry.unregister_records()
    end)
  end

  describe "start_link/1" do
    test "it should create user" do
      assert {:ok, _} = User.new(@user_name) |> UserServer.start_link()
    end
  end

  describe "get_balance/2" do
    setup do
      {:ok, pid} = UserServer.start_link(%User{name: @user_name, accounts: %{"TL" => 35.0}})
      %{pid: pid}
    end

    test "it should get_balance", %{pid: pid} do
      assert {:ok, 35.0} = UserServer.get_balance(pid, @currency)
    end
  end

  describe "deposit/3" do
    setup do
      {:ok, pid} = User.new(@user_name) |> UserServer.start_link()
      %{pid: pid}
    end

    test "it should deposit", %{pid: pid} do
      currency = "TL"
      assert {:ok, 50.20} == UserServer.deposit(pid, 50.20, currency)
    end
  end

  describe "withdraw/3" do
    setup do
      {:ok, pid} = UserServer.start_link(%User{name: @user_name, accounts: %{"TL" => 35.00}})
      %{pid: pid}
    end

    test "it should withdraw", %{pid: pid} do
      assert {:ok, 1.60} = UserServer.withdraw(pid, 33.40, @currency)
    end

    test "it should return not_enough_money", %{pid: pid} do
      assert {:error, :not_enough_money} = UserServer.withdraw(pid, 50, @currency)
    end
  end

  describe "send/4" do
    setup do
      {:ok, from_pid} = UserServer.start_link(%User{name: "a", accounts: %{"TL" => 200.0}})
      {:ok, to_pid} = UserServer.start_link(%User{name: "b", accounts: %{}})
      %{from_pid: from_pid, to_user_pid: to_pid}
    end

    test "it should send money", %{from_pid: from, to_user_pid: to} do
      amount = 99.99
      assert {:ok, 100.01, 99.99} = UserServer.send_money(from, to, amount, @currency)
    end

    test "it should return not enough money", %{from_pid: from, to_user_pid: to} do
      assert {:error, :not_enough_money} = UserServer.send_money(from, to, 300.99, @currency)
    end
  end
end
