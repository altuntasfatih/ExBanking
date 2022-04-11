defmodule ExBanking.Otp.UserServerTest do
  use ExUnit.Case
  alias ExBanking.{Otp.UserServer, Model.User}

  @user_name "test"
  @currency "TL"

  describe "start_link/1" do
    test "it should create user" do
      assert {:ok, _} = User.new(@user_name) |> UserServer.start_link()
    end
  end

  describe "get_balance/2" do
    setup do
      {:ok, pid} = create_user(@user_name, @currency, 35.0) |> UserServer.start_link()
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
      assert {:ok, 50.20} == UserServer.deposit(pid, 50.20, @currency)
    end

    test "it should deposit only two decimal precision", %{pid: pid} do
      assert {:ok, 33.33} == UserServer.deposit(pid, 33.33456, @currency)
    end
  end

  describe "withdraw/3" do
    setup do
      {:ok, pid} = create_user(@user_name, @currency, 100.0) |> UserServer.start_link()
      %{pid: pid}
    end

    test "it should withdraw", %{pid: pid} do
      assert {:ok, 68.00} = UserServer.withdraw(pid, 32, @currency)
    end

    test "it should withdraw only two decimal precision", %{pid: pid} do
      assert {:ok, 66.67} == UserServer.withdraw(pid, 33.33456, @currency)
    end

    test "it should return not_enough_money", %{pid: pid} do
      assert {:error, :not_enough_money} = UserServer.withdraw(pid, 150.00, @currency)
    end
  end

  describe "send/4" do
    setup do
      {:ok, from_pid} = create_user("a", @currency, 200.0) |> UserServer.start_link()
      {:ok, to_pid} = create_user("b") |> UserServer.start_link()
      %{from_pid: from_pid, to_user_pid: to_pid}
    end

    test "it should send money", %{from_pid: from, to_user_pid: to} do
      amount = 99.99

      assert {:ok, 100.01, ^amount} = UserServer.send_money(from, to, amount, @currency)
    end

    test "it should return not enough money", %{from_pid: from, to_user_pid: to} do
      assert {:error, :not_enough_money} = UserServer.send_money(from, to, 300.99, @currency)
    end
  end

  defp create_user(name), do: %User{name: name}

  defp create_user(name, currency, amount),
    do: %User{name: name, accounts: %{String.to_atom(currency) => amount}}
end
