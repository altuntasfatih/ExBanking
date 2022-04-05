defmodule ExBanking.Model.User do
  defstruct name: "",
            accounts: %{}

  alias __MODULE__

  @initial_balance 0.0

  @type t :: %User{
          name: String.t(),
          accounts: map()
        }
  @spec new(name :: String.t()) :: User.t()
  def new(name) when is_binary(name), do: %User{name: name}

  @spec deposit(user :: User.t(), amount :: float(), currency :: String.t()) :: {:ok, User.t()}
  def deposit(%User{accounts: accounts} = user, amount, currency) do
    updated_user = %User{user | accounts: Map.update(accounts, currency, amount, &(&1 + amount))}
    {:ok, updated_user}
  end

  @spec withdraw(user :: User.t(), amount :: float(), currency :: String.t()) ::
          {:ok, User.t()} | {:error, :not_enough_money}
  def withdraw(%User{accounts: accounts} = user, amount, currency) do
    if enough?(accounts, amount, currency) do
      updated_user = %User{
        user
        | accounts: Map.update(accounts, currency, amount, &(&1 - amount))
      }

      {:ok, updated_user}
    else
      {:error, :not_enough_money}
    end
  end

  @spec get_balance(user :: User.t(), currency :: String.t()) :: {:ok, float()}
  def get_balance(%User{accounts: accounts}, currency) do
    {:ok, Map.get(accounts, currency, @initial_balance)}
  end

  defp enough?(accounts, amount, currency),
    do: Map.get(accounts, currency) |> enough?(amount)

  defp enough?(nil, _), do: false
  defp enough?(balance, requested_amount), do: balance > requested_amount
end
