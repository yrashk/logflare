defmodule LogflareWeb.ChangeLogController do
  use LogflareWeb, :controller

  alias Logflare.ChangeLogs
  alias Logflare.ChangeLogs.ChangeLog

  def index(conn, _params) do
    change_logs = ChangeLogs.list_change_logs()
    render(conn, "index.html", change_logs: change_logs)
  end

  def new(conn, _params) do
    changeset = ChangeLogs.change_change_log(%ChangeLog{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"change_log" => change_log_params}) do
    case ChangeLogs.create_change_log(change_log_params) do
      {:ok, change_log} ->
        conn
        |> put_flash(:info, "Change log created successfully.")
        |> redirect(to: Routes.change_log_path(conn, :show, change_log))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    change_log = ChangeLogs.get_change_log!(id)
    render(conn, "show.html", change_log: change_log)
  end

  def edit(conn, %{"id" => id}) do
    change_log = ChangeLogs.get_change_log!(id)
    changeset = ChangeLogs.change_change_log(change_log)
    render(conn, "edit.html", change_log: change_log, changeset: changeset)
  end

  def update(conn, %{"id" => id, "change_log" => change_log_params}) do
    change_log = ChangeLogs.get_change_log!(id)

    case ChangeLogs.update_change_log(change_log, change_log_params) do
      {:ok, change_log} ->
        conn
        |> put_flash(:info, "Change log updated successfully.")
        |> redirect(to: Routes.change_log_path(conn, :show, change_log))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", change_log: change_log, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    change_log = ChangeLogs.get_change_log!(id)
    {:ok, _change_log} = ChangeLogs.delete_change_log(change_log)

    conn
    |> put_flash(:info, "Change log deleted successfully.")
    |> redirect(to: Routes.change_log_path(conn, :index))
  end
end
