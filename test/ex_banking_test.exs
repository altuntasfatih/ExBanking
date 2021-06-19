defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking
  alias ExBanking.Otp.UserSupervisor

  @test_user "test"

  setup do
    on_exit(fn -> UserSupervisor.termine_all() end)
  end

  describe "create_user/1" do
    test "it should create user" do
      assert :ok = ExBanking.create_user(@test_user)
    end

    test "it should return user already exist user" do
      :ok = ExBanking.create_user(@test_user)
      assert {:error, :user_already_exists} = ExBanking.create_user(@test_user)
    end
  end

  describe "deposit/3" do
    setup do
      :ok = ExBanking.create_user(@test_user)
      {:ok, pid} = ExBanking.Otp.UserServer.look_up(@test_user)
      %{user_name: @test_user, pid: pid}
    end

    test "it should deposit", %{user_name: user_name} do
      assert {:ok, 50.20} = ExBanking.deposit(user_name, 50.20, "TL")
    end

    test "it should return wrong arguments", %{user_name: user_name} do
      assert {:error, :wrong_arguments} = ExBanking.deposit(user_name, "a", 1)
    end

    test "it should return user does not exist", _ do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("fake", 50.20, "TL")
    end

    test "it should return to many request to user", %{user_name: user_name, pid: pid} do
      create_load(pid, 20)
      assert {:error, :too_many_requests_to_user} = ExBanking.deposit(user_name, 50.20, "TL")
    end
  end

  describe "withdraw/3" do
    setup do
      :ok = ExBanking.create_user(@test_user)
      {:ok, _} = ExBanking.deposit(@test_user, 100, "TL")
      {:ok, pid} = ExBanking.Otp.UserServer.look_up(@test_user)
      %{user_name: @test_user, pid: pid}
    end

    test "it should withdraw", %{user_name: user_name} do
      assert {:ok, 39.90} = ExBanking.withdraw(user_name, 60.10, "TL")
    end

    test "it should return not enough money", %{user_name: user_name} do
      assert {:error, :not_enough_money} = ExBanking.withdraw(user_name, 250.10, "TL")
    end

    test "it should return wrong arguments", %{user_name: user_name} do
      assert {:error, :wrong_arguments} = ExBanking.withdraw(user_name, "a", 1)
    end

    test "it should return user does not exist", _ do
      assert {:error, :user_does_not_exist} = ExBanking.withdraw("fake", 50.20, "TL")
    end

    test "it should return to many request to user", %{user_name: user_name, pid: pid} do
      create_load(pid, 20)
      assert {:error, :too_many_requests_to_user} = ExBanking.withdraw(user_name, 50.20, "TL")
    end
  end

  describe "get_balance/2" do
    setup do
      :ok = ExBanking.create_user(@test_user)
      {:ok, _} = ExBanking.deposit(@test_user, 100.05, "TL")
      {:ok, pid} = ExBanking.Otp.UserServer.look_up(@test_user)
      %{user_name: @test_user, pid: pid}
    end

    test "it should get_balance", %{user_name: user_name} do
      assert {:ok, 100.05} = ExBanking.get_balance(user_name, "TL")
    end

    test "it should return wrong arguments", %{user_name: user_name} do
      assert {:error, :wrong_arguments} = ExBanking.get_balance(user_name, 1)
    end

    test "it should return user does not exist", _ do
      assert {:error, :user_does_not_exist} = ExBanking.get_balance("fake", "TL")
    end

    test "it should return zero when currency not exist", %{user_name: user_name} do
      assert {:ok, 0.0} = ExBanking.get_balance(user_name, "euro")
    end

    test "it should return to many request to user", %{user_name: user_name, pid: pid} do
      create_load(pid, 20)
      assert {:error, :too_many_requests_to_user} = ExBanking.get_balance(user_name, "TL")
    end
  end

  describe "send/4" do
    setup do
      currency = "TL"
      to = "to_user"
      :ok = ExBanking.create_user(@test_user)
      :ok = ExBanking.create_user(to)
      {:ok, _} = ExBanking.deposit(@test_user, 100.00, currency)
      {:ok, from_pid} = ExBanking.Otp.UserServer.look_up(@test_user)
      {:ok, to_pid} = ExBanking.Otp.UserServer.look_up(to)

      %{from: @test_user, to: to, currency: currency, from_pid: from_pid, to_pid: to_pid}
    end

    test "it should send money", %{from: from, to: to, currency: currency} do
      assert {:ok, 70.0, 30.0} = ExBanking.send(from, to, 30.0, currency)
    end

    test "it should return not enough money", %{from: from, to: to, currency: currency} do
      assert {:error, :not_enough_money} = ExBanking.send(from, to, 500.0, currency)
    end

    test "it should return sender does not exist", %{from: _, to: to, currency: currency} do
      assert {:error, :sender_does_not_exist} = ExBanking.send("fake", to, 30.0, currency)
    end

    test "it should return receiver does not exist", %{from: from, to: _, currency: currency} do
      assert {:error, :receiver_does_not_exist} = ExBanking.send(from, "fake", 30.0, currency)
    end

    test "it should return to many request to sender", %{
      from: from,
      to: to,
      currency: currency,
      from_pid: from_pid
    } do
      create_load(from_pid, 20)
      assert {:error, :too_many_requests_to_sender} = ExBanking.send(from, to, 30.0, currency)
    end

    test "it should return to many request to receiver", %{
      from: from,
      to: to,
      currency: currency,
      to_pid: to_pid
    } do
      create_load(to_pid, 20)
      assert {:error, :too_many_requests_to_receiver} = ExBanking.send(from, to, 30.0, currency)
    end
  end

  defp create_load(pid, message_count) do
    Enum.each(1..message_count, fn _ -> Process.send(pid, {:sleep, 2000}, []) end)
  end
end
