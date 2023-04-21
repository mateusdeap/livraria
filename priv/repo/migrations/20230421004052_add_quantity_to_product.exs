defmodule Livraria.Repo.Migrations.AddQuantityToProduct do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :quantity, :integer
    end
  end
end
