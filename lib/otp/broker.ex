defmodule ExBanking.Otp.Broker do
  @table :ex_banking

  def create_table(), do: :ets.new(@table, [:set, :public, :named_table])

  @spec register(pid(), binary()) :: true
  def register(pid, key), do: :ets.insert(@table, {key, pid, 0})

  def increase(user_name, count \\ 1),
    do: :ets.update_counter(@table, user_name, {3, count})

  def decrease(user_name, count \\ 1),
    do: :ets.update_counter(@table, user_name, {3, -count})

  @spec look_up(binary() | list()) ::
          {:error, :process_is_not_alive} | {:ok, {binary(), pid(), number()}}
  def look_up(key) do
    case :ets.lookup(@table, key) do
      [value] -> {:ok, value}
      [] -> {:error, :process_is_not_alive}
    end
  end

  def unregister_records(), do: :ets.delete_all_objects(@table)
end
