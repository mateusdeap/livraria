defmodule Livraria.Repo.Migrations.ChangeProductTitleToName do
  use Ecto.Migration

  def change do
    rename table(:products), :title, to: :name
  end
end
