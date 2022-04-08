defmodule ExBanking.Context.UserContext do
  alias ExBanking.Otp.{UserSupervisor, UserServer, Broker}
  alias ExBanking.Model.User

  @threshold 10

  @spec create_user(binary) :: :ok | {:error, :user_already_exists}
  def create_user(user_name) do
    with user <- User.new(user_name),
         {:ok, _} <- UserSupervisor.create_user(user) do
      :ok
    else
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  def deposit(user_name, amount, currency) do
    proxy(user_name, &UserServer.deposit(&1, amount, currency))
  end

  def withdraw(user_name, amount, currency) do
    proxy(user_name, &UserServer.withdraw(&1, amount, currency))
  end

  def get_balance(user_name, currency) do
    proxy(user_name, &UserServer.get_balance(&1, currency))
  end

  def send(sender_user, receiver_user, amount, currency) do
    with {:sender?, {:ok, sender_pid}} <- {:sender?, look_up(sender_user)},
         {:receiver?, {:ok, _}} <- {:receiver?, look_up(receiver_user)} do
      UserServer.send(sender_pid, receiver_user, amount, currency)
    else
      {:sender?, {:error, :user_does_not_exist}} ->
        {:error, :sender_does_not_exist}

      {:receiver?, {:error, :user_does_not_exist}} ->
        {:error, :receiver_does_not_exist}

      {:sender?, {:error, :too_many_requests_to_user}} ->
        {:error, :too_many_requests_to_sender}

      {:receiver?, {:error, :too_many_requests_to_user}} ->
        {:error, :too_many_requests_to_receiver}

      err ->
        err
    end
  end

  def proxy(user_name, message) do
    with {:ok, pid} <- look_up(user_name) do
      increase_operation_count(user_name)
      message.(pid)
    end
  end

  def look_up({:ok, {_, pid, count}}) when count < @threshold, do: {:ok, pid}
  def look_up({:ok, _}), do: {:error, :too_many_requests_to_user}
  def look_up({:error, :process_is_not_alive}), do: {:error, :user_does_not_exist}
  def look_up(user_name), do: Broker.look_up(user_name) |> look_up()

  def increase_operation_count(user_name), do: Broker.increase(user_name)
end
