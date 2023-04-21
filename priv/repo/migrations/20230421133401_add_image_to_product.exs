defmodule Livraria.Repo.Migrations.AddImageToProduct do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :image, :string
    end
  end
end
