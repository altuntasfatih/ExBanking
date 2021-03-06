defmodule ExBanking do
  defguard is_money(amount) when is_number(amount) and amount > 0

  alias ExBanking.Context.UserContext

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user), do: UserContext.create_user(user)
  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_money(amount) and is_binary(currency),
      do: UserContext.deposit(user, amount, currency)

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_money(amount) and is_binary(currency),
      do: UserContext.withdraw(user, amount, currency)

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency),
    do: UserContext.get_balance(user, currency)

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}

  def send(user, user, _, _), do: {:error, :wrong_arguments}

  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_money(amount) and
             is_binary(currency) do
    UserContext.send(from_user, to_user, amount, currency)
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}
end
