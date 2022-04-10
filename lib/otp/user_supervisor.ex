defmodule ExBanking.Otp.UserSupervisor do
  use DynamicSupervisor
  alias ExBanking.Otp.{UserServer, Registry}

  def start_link(:ok) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec create_user(User.t()) :: {:error, {:already_started, pid}} | {:ok, pid}
  def create_user(user) do
    case Registry.look_up(user.name) do
      {:error, :process_is_not_alive} ->
        DynamicSupervisor.start_child(__MODULE__, {UserServer, user})

      {:ok, {_, pid, _}} ->
        {:error, {:already_started, pid}}
    end
  end

  def init(:ok) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 10
    )
  end

  def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end

  @spec termine_child(pid) :: :ok | {:error, :not_found}
  def termine_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def termine_all() do
    children()
    |> Enum.map(fn {_, pid, _, _} -> termine_child(pid) end)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :transient
    }
  end
end
