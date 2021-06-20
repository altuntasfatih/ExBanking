defmodule ExBanking.Application do
  @moduledoc false
  use Application
  alias ExBanking.Otp.{UserSupervisor, Broker}

  @impl true
  def start(_type, _args) do
    :ex_banking = Broker.create_table()

    opts = [
      strategy: :one_for_one,
      max_restarts: 10,
      max_seconds: 20,
      name: ExBanking.BaseSupervisor
    ]

    Supervisor.start_link(
      [
        {UserSupervisor, :ok}
      ],
      opts
    )
  end
end
