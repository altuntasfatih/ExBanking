defmodule ExBanking.Otp.Broker do
  @table :ex_banking

  def create_table(), do: :ets.new(@table, [:set, :public, :named_table])

  @spec register(pid(), any) :: true
  def register(pid, key), do: :ets.insert(@table, {key, pid, 0})

  def increase(user_name, count \\ 1),
    do: :ets.update_counter(@table, user_name, {3, count})

  def decrease(user_name, count \\ 1),
    do: :ets.update_counter(@table, user_name, {3, -count})

  @spec look_up(binary() | list()) ::
          {:error, :process_is_not_alive} | {:ok, {binary(), pid(), number()}}
  def look_up([]), do: {:error, :process_is_not_alive}
  def look_up([value]), do: {:ok, value}
  def look_up(key), do: :ets.lookup(@table, key) |> look_up()

  def unregister_records(), do: :ets.delete_all_objects(@table)
end
