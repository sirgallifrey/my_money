defmodule MyMoney.Repo do
  use Ecto.Repo,
    otp_app: :my_money,
    adapter: Ecto.Adapters.Postgres
end
