defmodule ExBanking.Otp.UserServer do
  use GenServer
  require Logger
  alias ExBanking.{Model.User, Otp.UserRegistry}

  @spec start_link(User.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(%User{} = user) do
    GenServer.start_link(__MODULE__, user, name: via_tuple(user.name))
  end

  @impl true
  def init(%User{} = user) do
    Process.flag(:trap_exit, true)
    Logger.info("Start user: #{inspect(user)}")
    {:ok, user}
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
  @deprecated
  def handle_call({:send_money, to_pid, amount, currency}, _from, user) do
    with {:ok, updated_user} <- User.withdraw(user, amount, currency),
         {:ok, current_balance} = User.get_balance(updated_user, currency),
         {:ok, to_user_balance} <- receive_money(to_pid, amount, currency) do
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


  @impl true
  def terminate(reason, %User{} = state) do
    Logger.info("Terminate user:#{inspect(state)}, reason: #{inspect(reason)}")
    state
  end

  @deprecated
  def receive_money(pid, amount, currency) when is_pid(pid),
    do: GenServer.call(pid, {:receive_money, amount, currency})
    @deprecated
  def send_money(pid, to_pid, amount, currency) when is_pid(pid),
    do: GenServer.call(pid, {:send_money, to_pid, amount, currency})

  def get_balance(pid, currency) when is_pid(pid),
    do: GenServer.call(pid, {:get_balance, currency})

  def deposit(pid, amount, currency) when is_pid(pid),
    do: GenServer.call(pid, {:deposit, amount, currency})

  def withdraw(pid, amount, currency) when is_pid(pid),
    do: GenServer.call(pid, {:withdraw, amount, currency})

  def via_tuple(user_name) do
    UserRegistry.via_tuple({__MODULE__, user_name})
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary
    }
  end
end
