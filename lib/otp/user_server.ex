defmodule ExBanking.Otp.UserServer do
  use GenServer
  require Logger

  alias ExBanking.Model.User
  alias ExBanking.Otp.Registry

  @spec start_link(User.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(%User{} = user) do
    GenServer.start_link(__MODULE__, user)
  end

  @impl true
  def init(%User{} = user) do
    Logger.info("Start user: #{inspect(user)}")
    register(user.name)

    {:ok, user}
  end

  @impl true
  def handle_call({:deposit, amount, currency}, _from, user) do
    {:ok, updated_user} = User.deposit(user, amount, currency)
    {:reply, User.get_balance(updated_user, currency), updated_user, {:continue, :decrease}}
  end

  @impl true
  def handle_call({:withdraw, amount, currency}, _from, user) do
    case User.withdraw(user, amount, currency) do
      {:ok, updated_user} -> {:reply, User.get_balance(updated_user, currency), updated_user}
      err -> {:reply, err, user, {:continue, :decrease}}
    end
  end

  @impl true
  def handle_call({:receive_money, amount, currency}, _from, user) do
    {:ok, updated_user} = User.deposit(user, amount, currency)
    {:reply, User.get_balance(updated_user, currency), updated_user, {:continue, :decrease}}
  end

  @impl true
  def handle_call({:send_money, to_user, amount, currency}, _from, user) do
    with {:ok, updated_user} <- User.withdraw(user, amount, currency),
         {:ok, current_balance} = User.get_balance(updated_user, currency),
         {:ok, to_user_balance} <- transfer_money(to_user, amount, currency) do
      {:reply, {:ok, current_balance, to_user_balance}, updated_user, {:continue, :decrease}}
    else
      err -> {:reply, err, user, {:continue, :decrease}}
    end
  end

  @impl true
  def handle_call({:get_balance, currency}, _from, user) do
    {:reply, User.get_balance(user, currency), user, {:continue, :decrease}}
  end

  @impl true
  def handle_continue(:decrease, %User{name: user_name} = state) do
    decrease_operation_count(user_name)
    {:noreply, state}
  end

  @impl true
  def terminate(reason, %User{name: user_name} = state) do
    Logger.info("Terminate user:#{inspect(state)}, reason: #{inspect(reason)}")
    unregister(user_name)
    state
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
    do: Registry.look_up(user_name) |> via(callback)

  def via({:ok, {_user_name, pid, _load}}, callback) when is_pid(pid), do: callback.(pid)
  def via(err, _), do: err

  defp decrease_operation_count(user_name), do: Registry.decrease_operation_count(user_name)

  defp register(user_name) do
    Process.flag(:trap_exit, true)
    Registry.register(self(), user_name)
  end

  defp unregister(user_name), do: Registry.unregister(user_name)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary
    }
  end
end
