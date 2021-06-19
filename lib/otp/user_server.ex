defmodule ExBanking.Otp.UserServer do
  use GenServer
  alias ExBanking.Model.User

  @spec start_link(User.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(%User{} = user) do
    GenServer.start_link(__MODULE__, user, name: via_tuple(user.name))
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:deposit, amount, currency}, _from, user) do
    {:ok, updated_user} = User.deposit(user, amount, currency)
    {:reply, User.get_balance(updated_user, currency), updated_user}
  end

  @impl true
  def handle_call({:withdraw, amount, currency}, _from, user) do
    case User.withdraw(user, amount, currency) do
      {:ok, updated_user} -> {:reply, User.get_balance(updated_user, currency), updated_user}
      err -> {:reply, err, user}
    end
  end

  @impl true
  def handle_call({:receive_money, amount, currency}, _from, user) do
    {:ok, updated_user} = User.deposit(user, amount, currency)
    {:reply, User.get_balance(updated_user, currency), updated_user}
  end

  @impl true
  def handle_call({:send_money, to_user, amount, currency}, _from, user) do
    with {:ok, updated_user} <- User.transfer_money(user, amount, currency),
         {:ok, current_balance} = User.get_balance(updated_user, currency),
         {:ok, to_user_balance} <- transfer_money(to_user, amount, currency) do
      {:reply, {:ok, current_balance, to_user_balance}, updated_user}
    else
      err -> {:reply, err, user}
    end
  end

  @impl true
  def handle_call({:get_balance, currency}, _from, user) do
    {:reply, User.get_balance(user, currency), user}
  end

  # only test purpose
  @impl true
  def handle_info({:sleep, milisecond}, state) do
    Process.sleep(milisecond)
    {:noreply, state}
  end

  def transfer_money(user, amount, currency),
    do: via(user, &GenServer.call(&1, {:receive_money, amount, currency}))

  def send(pid, to_user, amount, currency) when is_pid(pid),
    do: GenServer.call(pid, {:send_money, to_user, amount, currency})

  def send(from_user, to_user, amount, currency),
    do: via(from_user, &GenServer.call(&1, {:send_money, to_user, amount, currency}))

  def get_balance(pid, currency) when is_pid(pid),
    do: GenServer.call(pid, {:get_balance, currency})

  def get_balance(user, currency),
    do: via(user, &GenServer.call(&1, {:get_balance, currency}))

  def deposit(pid, amount, currency) when is_pid(pid),
    do: GenServer.call(pid, {:deposit, amount, currency})

  def deposit(user, amount, currency),
    do: via(user, &GenServer.call(&1, {:deposit, amount, currency}))

  def withdraw(pid, amount, currency) when is_pid(pid),
    do: GenServer.call(pid, {:withdraw, amount, currency})

  def withdraw(user, amount, currency),
    do: via(user, &GenServer.call(&1, {:withdraw, amount, currency}))

  def via(user_name, callback) when is_binary(user_name),
    do: ExBanking.Otp.Registry.where_is({__MODULE__, user_name}) |> via(callback)

  def via({:ok, pid}, callback) when is_pid(pid), do: callback.(pid)
  def via(err, _), do: err

  @spec look_up(binary()) :: {:error, :process_is_not_alive} | {:ok, pid()}
  def look_up(user_name), do: ExBanking.Otp.Registry.where_is({__MODULE__, user_name})

  def via_tuple(user_name) do
    ExBanking.Otp.Registry.via_tuple({__MODULE__, user_name})
  end
end
