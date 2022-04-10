defmodule ExBanking.Context.UserContext do
  alias ExBanking.Otp.{UserSupervisor, UserServer, Registry}
  alias ExBanking.Model.User

  @operation_limit Application.compile_env(:ex_banking, :operion_count_limit)

  @spec create_user(binary) :: :ok | {:error, :user_already_exists}
  def create_user(user) do
    with user <- User.new(user),
         {:ok, _} <- UserSupervisor.create_user(user) do
      :ok
    else
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  def deposit(user, amount, currency) do
    proxy(user, &UserServer.deposit(&1, amount, currency))
  end

  def withdraw(user, amount, currency) do
    proxy(user, &UserServer.withdraw(&1, amount, currency))
  end

  def get_balance(user, currency) do
    proxy(user, &UserServer.get_balance(&1, currency))
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

  defp proxy(user, message) do
    with {:ok, pid} <- look_up(user) do
      increase_operation_count(user)
      message.(pid)
    end
  end

  defp look_up({:ok, {_, pid, count}}) when count < @operation_limit, do: {:ok, pid}
  defp look_up({:ok, _}), do: {:error, :too_many_requests_to_user}
  defp look_up({:error, :process_is_not_alive}), do: {:error, :user_does_not_exist}
  defp look_up(user), do: Registry.look_up(user) |> look_up()

  defp increase_operation_count(user), do: Registry.increase_operation_count(user)
end
