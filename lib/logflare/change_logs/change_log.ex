defmodule Logflare.ChangeLogs.ChangeLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "change_logs" do
    field :body, :string
    field :title, :string
    field :version, :string

    timestamps()
  end

  @doc false
  def changeset(change_log, attrs) do
    change_log
    |> cast(attrs, [:title, :version, :body])
    |> validate_required([:title, :version, :body])
  end
end
