defmodule ExBanking.Model.UserTest do
  use ExUnit.Case
  alias ExBanking.Model.User

  @user_name "Test"

  test "it should create user" do
    assert %User{accounts: %{}, name: @user_name} = User.new(@user_name)
  end

  test "it should deposit" do
    amount = 101.10
    currency = "TL"
    user = User.new(@user_name)

    assert {:ok,
            %User{
              accounts: %{"TL" => 101.1},
              name: "Test"
            }} = User.deposit(user, amount, currency)
  end

  describe "withdraw/3" do
    setup do
      %{
        user: %User{
          accounts: %{"TL" => 250.1, "$" => 95.02},
          name: "Test"
        }
      }
    end

    test "it should withdraw", %{user: user} do
      amount = 101.10
      currency = "TL"

      assert {:ok,
              %User{
                accounts: %{"TL" => 149.0, "$" => 95.02},
                name: "Test"
              }} = User.withdraw(user, amount, currency)
    end

    test "it should return not enough money when account does not exist", %{user: user} do
      amount = 101.10
      currency = "euro"

      assert {:error, :not_enough_money} = User.withdraw(user, amount, currency)
    end

    test "it should return not_enough_money ", %{user: user} do
      amount = 300.10
      currency = "TL"

      assert {:error, :not_enough_money} = User.withdraw(user, amount, currency)
    end
  end

  describe "get_balance/2" do
    setup do
      %{
        user: %User{
          accounts: %{"TL" => 250.1, "$" => 95.02},
          name: "Test"
        }
      }
    end

    test "it should get_balance", %{user: user} do
      currency = "TL"
      assert {:ok, 250.1} = User.get_balance(user, currency)
    end
  end
end
