defmodule ExBanking.Otp.Registry do
  def via_tuple(key) when is_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  @spec where_is(tuple) :: {:error, :process_is_not_alive} | {:ok, pid()}
  def where_is(key) when is_tuple(key) do
    case Registry.lookup(__MODULE__, key) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :process_is_not_alive}
    end
  end

  def start_link(:ok) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient
    }
  end
end
