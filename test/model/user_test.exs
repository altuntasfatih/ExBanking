defmodule ExBanking.Model.UserTest do
  use ExUnit.Case
  alias ExBanking.Model.User

  @user_name "Test"

  test "it should create user" do
    assert User.new(@user_name) == %User{accounts: %{}, name: @user_name}
  end

  test "it should deposit" do
    amount = 101.10
    currency = "TL"

    assert User.new(@user_name) |> User.deposit(amount, currency) ==
             {:ok,
              %User{
                accounts: %{"TL" => 101.1},
                name: "Test"
              }}
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

      assert User.withdraw(user, amount, currency) ==
               {:ok,
                %User{
                  accounts: %{"TL" => 149.0, "$" => 95.02},
                  name: "Test"
                }}
    end

    test "it should return not enough money when account does not exist", %{user: user} do
      amount = 101.10
      currency = "euro"

      assert User.withdraw(user, amount, currency) == {:error, :not_enough_money}
    end

    test "it should return not_enough_money ", %{user: user} do
      amount = 300.10
      currency = "TL"

      assert User.withdraw(user, amount, currency) == {:error, :not_enough_money}
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
      assert User.get_balance(user, currency) == {:ok, 250.1}
    end
  end
end
