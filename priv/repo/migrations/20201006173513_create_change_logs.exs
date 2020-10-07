defmodule Logflare.Repo.Migrations.CreateChangeLogs do
  use Ecto.Migration

  def change do
    create table(:change_logs) do
      add :title, :string
      add :version, :string
      add :body, :text

      timestamps()
    end

  end
end
