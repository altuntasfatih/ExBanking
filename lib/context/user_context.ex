defmodule ExBanking.Context.UserContext do
  alias ExBanking.Otp.{UserSupervisor, UserServer}
  alias ExBanking.Model.User

  @threshold 10

  def create_user(user_name) do
    user = User.new(user_name)

    case UserSupervisor.create_user(user) do
      {:ok, _} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  def deposit(user_name, amount, currency) do
    proxy(user_name, &UserServer.deposit(&1, Util.round(amount), currency))
  end

  def withdraw(user_name, amount, currency) do
    proxy(user_name, &UserServer.withdraw(&1, Util.round(amount), currency))
  end

  def get_balance(user_name, currency) do
    proxy(user_name, &UserServer.get_balance(&1, currency))
  end

  def send(from_user, to_user, amount, currency) do
    with {{:ok, from_pid}, _} <- {look_up(from_user), :from},
         {{:ok, _}, _} <- {look_up(to_user), :to} do
      UserServer.send(from_pid, to_user, Util.round(amount), currency)
    else
      {{:error, :user_does_not_exist}, :from} -> {:error, :sender_does_not_exist}
      {{:error, :user_does_not_exist}, :to} -> {:error, :receiver_does_not_exist}
      {{:error, :too_many_requests_to_user}, :from} -> {:error, :too_many_requests_to_sender}
      {{:error, :too_many_requests_to_user}, :to} -> {:error, :too_many_requests_to_receiver}
      {{err, _}} -> err
    end
  end

  def proxy(user_name, message) do
    case look_up(user_name) do
      {:ok, pid} -> message.(pid)
      err -> err
    end
  end

  def look_up(user_name) do
    with {:ok, pid} <- UserServer.look_up(user_name),
         true <- available?(pid) do
      {:ok, pid}
    else
      false -> {:error, :too_many_requests_to_user}
      {:error, :process_is_not_alive} -> {:error, :user_does_not_exist}
    end
  end

  defp available?({:message_queue_len, size}), do: size < @threshold

  defp available?(pid) when is_pid(pid),
    do: Process.info(pid, :message_queue_len) |> available?()
end
