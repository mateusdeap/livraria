defmodule Livraria.Repo.Migrations.CreateSuppliers do
  use Ecto.Migration

  def change do
    create table(:suppliers) do
      add :name, :string

      timestamps()
    end
  end
end
