defmodule Livraria.Repo.Migrations.CreateCollaboratorsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:collaborators) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:collaborators, [:email])

    create table(:collaborators_tokens) do
      add :collaborator_id, references(:collaborators, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:collaborators_tokens, [:collaborator_id])
    create unique_index(:collaborators_tokens, [:context, :token])
  end
end
