defmodule ExBanking.Otp.UserServerTest do
  use ExUnit.Case
  alias ExBanking.Otp.{UserServer, Registry, UserSupervisor}
  alias ExBanking.Model.User

  @user_name "test"

  setup do
    on_exit(fn ->
      Registry.unregister_records()
      UserSupervisor.termine_all()
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

    test "it should get_balance" do
      currency = "TL"
      assert UserServer.get_balance(@user_name, currency) == {:ok, 35.0}
    end
  end

  describe "deposit/3" do
    setup do
      {:ok, pid} = User.new(@user_name) |> UserServer.start_link()
      %{pid: pid}
    end

    test "it should deposit" do
      currency = "TL"
      assert UserServer.deposit(@user_name, 50.20, currency) == {:ok, 50.20}
    end
  end

  describe "withdraw/3" do
    setup do
      {:ok, pid} = UserServer.start_link(%User{name: @user_name, accounts: %{"TL" => 35.0}})
      %{pid: pid}
    end

    test "it should withdraw" do
      currency = "TL"
      assert UserServer.withdraw(@user_name, 30, currency) == {:ok, 5.0}
    end

    test "it should return not_enough_money" do
      currency = "TL"
      assert UserServer.withdraw(@user_name, 50, currency) == {:error, :not_enough_money}
    end
  end

  describe "send/4" do
    setup do
      from = "a_user"
      to = "b_user"
      {:ok, _} = UserServer.start_link(%User{name: from, accounts: %{"TL" => 200.0}})
      {:ok, _} = UserServer.start_link(%User{name: to, accounts: %{}})
      %{from_user: from, to_user: to}
    end

    test "it should send money", %{from_user: from, to_user: to} do
      amount = 99.99
      currency = "TL"
      assert UserServer.send(from, to, amount, currency) == {:ok, 100.01, 99.99}
    end

    test "it should return not enough money", %{from_user: from, to_user: to} do
      amount = 300.99
      currency = "TL"
      assert UserServer.send(from, to, amount, currency) == {:error, :not_enough_money}
    end
  end
end
