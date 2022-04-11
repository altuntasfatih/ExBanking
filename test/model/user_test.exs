defmodule ExBanking.Model.UserTest do
  use ExUnit.Case
  alias ExBanking.Model.User

  @user_name "Test"

  test "it should create user" do
    assert %User{accounts: %{}, name: @user_name} = User.new(@user_name)
  end

  test "it should deposit" do
    amount = 101.10

    user = User.new(@user_name)

    assert {:ok,
            %User{
              accounts: %{tl: 101.1},
              name: "Test"
            }} = User.deposit(user, amount, "tl")
  end

  describe "withdraw/3" do
    setup do
      %{
        user: %User{
          accounts: %{:tl => 250.1, :usd => 95.02},
          name: "Test"
        }
      }
    end

    test "it should withdraw", %{user: user} do
      amount = 101.10

      assert {:ok,
              %User{
                accounts: %{:tl => 149.0, :usd => 95.02},
                name: "Test"
              }} = User.withdraw(user, amount, "tl")
    end

    test "it should return not enough money when account does not exist", %{user: user} do
      assert {:error, :not_enough_money} = User.withdraw(user, 101.10, "euro")
    end

    test "it should return not_enough_money ", %{user: user} do
      assert {:error, :not_enough_money} = User.withdraw(user, 300.10, "tl")
    end
  end

  describe "get_balance/2" do
    setup do
      %{
        user: %User{
          accounts: %{:tl => 250.1, :usd => 95.02},
          name: "Test"
        }
      }
    end

    test "it should get_balance", %{user: user} do
      assert {:ok, 250.1} = User.get_balance(user, "tl")
      assert {:ok, 95.02} = User.get_balance(user, "usd")
    end
  end
end
