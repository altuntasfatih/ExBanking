defmodule ExBanking.Application do
  @moduledoc false
  use Application
  alias ExBanking.Otp.{Registry, UserSupervisor}

  @impl true
  def start(_type, _args) do
    opts = [
      strategy: :one_for_one,
      max_restarts: 10,
      max_seconds: 20,
      name: ExBanking.BaseSupervisor
    ]

    Supervisor.start_link(
      [
        {UserSupervisor, :ok},
        {Registry, :ok}
      ],
      opts
    )
  end
end
