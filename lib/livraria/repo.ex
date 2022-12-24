defmodule Livraria.Repo do
  use Ecto.Repo,
    otp_app: :livraria,
    adapter: Ecto.Adapters.Postgres
end
