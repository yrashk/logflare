defmodule Logflare.ChangeLogs do
  @moduledoc """
  The ChangeLogs context.
  """

  import Ecto.Query, warn: false
  alias Logflare.Repo

  alias Logflare.ChangeLogs.ChangeLog

  @doc """
  Returns the list of change_logs.

  ## Examples

      iex> list_change_logs()
      [%ChangeLog{}, ...]

  """
  def list_change_logs do
    Repo.all(ChangeLog)
  end

  @doc """
  Gets a single change_log.

  Raises `Ecto.NoResultsError` if the Change log does not exist.

  ## Examples

      iex> get_change_log!(123)
      %ChangeLog{}

      iex> get_change_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_change_log!(id), do: Repo.get!(ChangeLog, id)

  @doc """
  Creates a change_log.

  ## Examples

      iex> create_change_log(%{field: value})
      {:ok, %ChangeLog{}}

      iex> create_change_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_change_log(attrs \\ %{}) do
    %ChangeLog{}
    |> ChangeLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a change_log.

  ## Examples

      iex> update_change_log(change_log, %{field: new_value})
      {:ok, %ChangeLog{}}

      iex> update_change_log(change_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_change_log(%ChangeLog{} = change_log, attrs) do
    change_log
    |> ChangeLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a change_log.

  ## Examples

      iex> delete_change_log(change_log)
      {:ok, %ChangeLog{}}

      iex> delete_change_log(change_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_change_log(%ChangeLog{} = change_log) do
    Repo.delete(change_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking change_log changes.

  ## Examples

      iex> change_change_log(change_log)
      %Ecto.Changeset{data: %ChangeLog{}}

  """
  def change_change_log(%ChangeLog{} = change_log, attrs \\ %{}) do
    ChangeLog.changeset(change_log, attrs)
  end
end
