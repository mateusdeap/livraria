defmodule Livraria.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :title, :string
      add :description, :string
      add :sell_price, :decimal
      add :cost_price, :decimal
      add :quantity, :integer
      add :image, :string
      add :supplier_id, references(:suppliers, on_delete: :nothing)

      timestamps()
    end

    create index(:products, [:supplier_id])
  end
end
