defmodule ExBanking.Model.User do
  defstruct name: "",
            accounts: %{}

  alias __MODULE__
  defguard is_exist(accounts, currency) when is_map_key(accounts, currency)

  @type t :: %User{
          name: String.t(),
          accounts: %{String.t() => float()}
        }

  def new(name) when is_binary(name), do: %User{name: name}

  def deposit(%User{accounts: accounts} = user, amount, currency) do
    {:ok,
     %User{
       user
       | accounts: Map.update(accounts, currency, amount, &(&1 + amount))
     }}
  end

  def transfer_money(user, amount, currency), do: withdraw(user, amount, currency)

  def withdraw(%User{accounts: accounts} = user, amount, currency) do
    if enough?(accounts, amount, currency) do
      {:ok,
       %User{
         user
         | accounts: Map.update(accounts, currency, amount, &(&1 - amount))
       }}
    else
      {:error, :not_enough_money}
    end
  end

  def get_balance(%User{accounts: accounts}, currency) when is_exist(accounts, currency),
    do: {:ok, Map.get(accounts, currency)}

  def get_balance(_, _), do: {:ok, 0.0}

  def enough?(accounts, amount, currency),
    do: Map.get(accounts, currency) |> enough?(amount)

  def enough?(nil, _), do: false
  def enough?(balance, requested_amount), do: balance > requested_amount
end
