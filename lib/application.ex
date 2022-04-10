defmodule ExBanking.Application do
  @moduledoc false
  use Application
  alias ExBanking.Otp.{UserSupervisor, Registry}

  @impl true
  def start(_type, _args) do
    opts = [
      strategy: :one_for_one,
      max_restarts: 10,
      max_seconds: 20,
      name: ExBanking.BaseSupervisor
    ]

    Supervisor.start_link(children(), opts)
  end

  defp children() do
    [{UserSupervisor, :ok}, {Registry, :ok}]
  end
end
