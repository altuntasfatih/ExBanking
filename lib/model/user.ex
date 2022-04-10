defmodule ExBanking.Model.User do
  defstruct name: "",
            accounts: %{}

  alias __MODULE__

  @initial_balance 0.00

  @type t :: %User{
          name: String.t(),
          accounts: map()
        }
  @spec new(name :: String.t()) :: User.t()
  def new(name), do: %User{name: name}

  @spec deposit(user :: User.t(), amount :: number(), currency :: String.t()) :: {:ok, User.t()}
  def deposit(%User{accounts: accounts} = user, amount, currency) do
    amount = Util.round(amount)
    user = %{user | accounts: Map.update(accounts, currency, amount, &(&1 + amount))}
    {:ok, user}
  end

  @spec withdraw(user :: User.t(), amount :: number(), currency :: String.t()) ::
          {:ok, User.t()} | {:error, :not_enough_money}
  def withdraw(%User{accounts: accounts} = user, amount, currency) do
    if enough?(accounts, amount, currency) do
      amount = Util.round(amount)
      user = %{user | accounts: Map.update(accounts, currency, amount, &(&1 - amount))}

      {:ok, user}
    else
      {:error, :not_enough_money}
    end
  end

  @spec get_balance(user :: User.t(), currency :: String.t()) :: {:ok, float()}
  def get_balance(%User{accounts: accounts}, currency) do
    {:ok, Map.get(accounts, currency, @initial_balance)}
  end

  defp enough?(accounts, amount, currency),
    do: Map.get(accounts, currency, @initial_balance) |> enough?(amount)

  defp enough?(balance, requested_amount), do: balance > requested_amount
end
