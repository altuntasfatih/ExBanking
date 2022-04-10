defmodule ExBanking.Otp.Registry do
  @table_name :ex_banking
  @type process_registry ::
          {key :: String.t(), pid :: pid(), operation_count :: non_neg_integer()}

  def start_link(:ok) do
    GenServer.start_link(__MODULE__, @table_name, name: __MODULE__)
  end

  def init(table_name) do
    ^table_name = :ets.new(table_name, [:set, :public, :named_table])
    {:ok, table_name}
  end

  @spec register(pid(), binary()) :: true
  def register(pid, key), do: :ets.insert(@table_name, {key, pid, 0})

  @spec unregister(binary()) :: true
  def unregister(key), do: :ets.delete(@table_name, key)

  def increase_operation_count(key, count \\ 1),
    do: :ets.update_counter(@table_name, key, {3, count})

  def decrease_operation_count(key, count \\ 1),
    do: :ets.update_counter(@table_name, key, {3, -count})

  @spec look_up(binary() | list()) :: {:ok, process_registry()} | {:error, :process_is_not_alive}
  def look_up(key) do
    case :ets.lookup(@table_name, key) do
      [value] -> {:ok, value}
      [] -> {:error, :process_is_not_alive}
    end
  end

  def unregister_records(), do: :ets.delete_all_objects(@table_name)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :transient
    }
  end
end
