defmodule ExBanking.Context.UserContext do
  alias ExBanking.{Otp.UserSupervisor, Otp.UserServer, Otp.UserRegistry, Model.User}

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

  def send(from_user, to_user, amount, currency) do
    with {:from, {:ok, from_pid}} <- {:from, look_up(from_user)},
         {:to, {:ok, to_pid}} <- {:to, look_up(to_user)} do
      UserServer.send_money(from_pid, to_pid, amount, currency)
    else
      {:from, {:error, :user_does_not_exist}} ->
        {:error, :sender_does_not_exist}

      {:from, {:error, :too_many_requests_to_user}} ->
        {:error, :too_many_requests_to_sender}

      {:to, {:error, :user_does_not_exist}} ->
        {:error, :receiver_does_not_exist}

      {:to, {:error, :too_many_requests_to_user}} ->
        {:error, :too_many_requests_to_receiver}

      err ->
        err
    end
  end

  defp proxy(user, message) when is_binary(user) do
    with {:ok, pid} <- look_up(user) do
      message.(pid)
    end
  end

  def look_up(user_name) do
    with {:ok, pid} <- UserRegistry.where_is({UserServer, user_name}),
         {:available?, true} <- {:available?, available?(pid)} do
      {:ok, pid}
    else
      {:available?, false} -> {:error, :too_many_requests_to_user}
      {:error, :process_is_not_alive} -> {:error, :user_does_not_exist}
    end
  end

  defp available?({:message_queue_len, size}), do: size < @operation_limit

  defp available?(pid) when is_pid(pid),
    do: Process.info(pid, :message_queue_len) |> available?()
end
