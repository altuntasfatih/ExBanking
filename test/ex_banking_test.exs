defmodule ExBankingTest do
  use ExUnit.Case
  require Logger

  alias ExBanking.Otp.{UserSupervisor, UserRegistry, UserServer}

  @currency_tl "TL"
  @currency_usd "USD"
  @waiting_operation_count 20

  setup do
    on_exit(fn -> UserSupervisor.termine_all() end)
  end

  describe "create_user/1" do
    test "it should create user" do
      assert :ok = ExBanking.create_user(random_user())
    end

    test "it should return user already exist user" do
      user = random_user()

      assert :ok = ExBanking.create_user(user)
      assert {:error, :user_already_exists} = ExBanking.create_user(user)
    end
  end

  describe "deposit/3" do
    setup do
      user = random_user()
      :ok = ExBanking.create_user(user)

      %{user: user}
    end

    test "it should deposit TL", %{user: user} do
      assert {:ok, 20.10} = ExBanking.deposit(user, 20.10, @currency_tl)
      assert {:ok, 30.30} = ExBanking.deposit(user, 10.20, @currency_tl)
    end

    test "it should deposit USD", %{user: user} do
      assert {:ok, 20.10} = ExBanking.deposit(user, 20.10, @currency_usd)
      assert {:ok, 30.30} = ExBanking.deposit(user, 10.20, @currency_usd)
    end

    test "it should return wrong arguments", %{user: user} do
      assert {:error, :wrong_arguments} = ExBanking.deposit(user, "a", 1)
    end

    test "it should return wrong arguments when amount is below than zero", %{
      user: user
    } do
      assert {:error, :wrong_arguments} = ExBanking.deposit(user, -20, @currency_tl)
    end

    test "it should return user does not exist", _ do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("fake", 50.20, "TL")
    end

    test "it should return to many request to user", %{user: user} do
      refute increase_load(user)

      assert {:error, :too_many_requests_to_user} = ExBanking.deposit(user, 50.20, "TL")
    end
  end

  describe "withdraw/3" do
    setup do
      user = random_user()
      :ok = ExBanking.create_user(user)
      {:ok, _} = ExBanking.deposit(user, 100, @currency_usd)

      %{user: user}
    end

    test "it should withdraw", %{user: user} do
      assert {:ok, 39.90} = ExBanking.withdraw(user, 60.10, @currency_usd)
      assert {:ok, 39.00} = ExBanking.withdraw(user, 0.90, @currency_usd)
    end

    test "it should return not enough money", %{user: user} do
      assert {:error, :not_enough_money} = ExBanking.withdraw(user, 250.10, @currency_usd)
    end

    test "it should return wrong arguments", %{user: user} do
      assert {:error, :wrong_arguments} = ExBanking.withdraw(user, "a", 1)
    end

    test "it should return wrong arguments when amount is below than zero", %{
      user: user
    } do
      assert {:error, :wrong_arguments} = ExBanking.withdraw(user, -10, @currency_usd)
    end

    test "it should return user does not exist", _ do
      assert {:error, :user_does_not_exist} = ExBanking.withdraw("fake", 50.20, "TL")
    end

    test "it should return to many request to user", %{user: user} do
      refute increase_load(user)

      assert {:error, :too_many_requests_to_user} = ExBanking.withdraw(user, 50.20, "TL")
    end
  end

  describe "get_balance/2" do
    setup do
      user = random_user()
      :ok = ExBanking.create_user(user)
      {:ok, _} = ExBanking.deposit(user, 100.05, @currency_tl)
      {:ok, _} = ExBanking.deposit(user, 39.99, @currency_usd)

      %{user: user}
    end

    test "it should get_balance TL", %{user: user} do
      assert {:ok, 100.05} = ExBanking.get_balance(user, @currency_tl)
    end

    test "it should get_balance USD", %{user: user} do
      assert {:ok, 39.99} = ExBanking.get_balance(user, @currency_usd)
    end

    test "it should return wrong arguments", %{user: user} do
      assert {:error, :wrong_arguments} = ExBanking.get_balance(user, 1)
    end

    test "it should return user does not exist", _ do
      assert {:error, :user_does_not_exist} = ExBanking.get_balance("fake", @currency_tl)
    end

    test "it should return zero when currency not exist", %{user: user} do
      assert {:ok, 0.0} = ExBanking.get_balance(user, "euro")
    end

    test "it should return to many request to user", %{user: user} do
      refute increase_load(user)

      assert {:error, :too_many_requests_to_user} = ExBanking.get_balance(user, @currency_tl)
    end
  end

  describe "send/4" do
    setup do
      from = random_user()
      to = random_user()
      :ok = ExBanking.create_user(from)
      :ok = ExBanking.create_user(to)
      {:ok, _} = ExBanking.deposit(from, 100.00, @currency_tl)
      %{from: from, to: to}
    end

    test "it should send money", %{from: from, to: to} do
      assert {:ok, 70.0, 30.0} = ExBanking.send(from, to, 30.0, @currency_tl)
    end

    test "it should return not enough money", %{from: from, to: to} do
      assert {:error, :not_enough_money} = ExBanking.send(from, to, 500.0, @currency_tl)
    end

    test "it should return sender does not exist", %{from: _, to: to} do
      assert {:error, :sender_does_not_exist} = ExBanking.send("fake", to, 30.0, @currency_tl)
    end

    test "it should return wrong arguments when amount is below than zero", %{from: from, to: to} do
      assert {:error, :wrong_arguments} = ExBanking.send(from, to, -30.0, @currency_tl)
    end

    test "it should return wrong arguments when sender and receiver is same", %{
      from: from
    } do
      assert {:error, :wrong_arguments} = ExBanking.send(from, from, 30.0, @currency_tl)
    end

    test "it should return receiver does not exist", %{from: from, to: _} do
      assert {:error, :receiver_does_not_exist} = ExBanking.send(from, "fake", 30.0, @currency_tl)
    end

    test "it should return to many request to sender", %{
      from: from,
      to: to
    } do
      refute increase_load(from)

      assert {:error, :too_many_requests_to_sender} = ExBanking.send(from, to, 30.0, @currency_tl)
    end

    test "it should return to many request to receiver", %{
      from: from,
      to: to
    } do
      refute increase_load(to)

      assert {:error, :too_many_requests_to_receiver} =
               ExBanking.send(from, to, 30.0, @currency_tl)
    end
  end

  describe "deadlock" do
    setup do
      from = random_user()
      to = random_user()
      :ok = ExBanking.create_user(from)
      :ok = ExBanking.create_user(to)
      {:ok, _} = ExBanking.deposit(from, 10.0, @currency_tl)
      {:ok, _} = ExBanking.deposit(to, 10.0, @currency_tl)
      %{from: from, to: to}
    end

    test "it should support when two users try send money each other at same time", %{
      from: from,
      to: to
    } do
      Enum.to_list(0..9)
      |> Enum.map(fn number ->
        Task.async(fn ->
          if rem(number, 2) == 0 do
            {number, ExBanking.send(from, to, 1.0, @currency_tl)}
          else
            {number, ExBanking.send(to, from, 1.0, @currency_tl)}
          end
        end)
      end)
      |> Enum.each(fn task ->
        assert {:ok, _result} = Task.yield(task)
      end)

      assert {:ok, 10.0} = ExBanking.get_balance(from, @currency_tl)
      assert {:ok, 10.0} = ExBanking.get_balance(to, @currency_tl)
    end
  end

  defp increase_load(user_name, count \\ @waiting_operation_count) do
    {:ok, pid} = UserRegistry.where_is({UserServer, user_name})

    :ok !=
      Enum.each(1..count, fn _ -> Process.send(pid, {:sleep, 2000}, []) end)
  end

  defp random_user(), do: "user_" <> UUID.uuid4()
end
