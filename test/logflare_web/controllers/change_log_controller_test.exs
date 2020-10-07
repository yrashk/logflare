defmodule LogflareWeb.ChangeLogControllerTest do
  use LogflareWeb.ConnCase

  alias Logflare.ChangeLogs

  @create_attrs %{body: "some body", title: "some title", version: "some version"}
  @update_attrs %{body: "some updated body", title: "some updated title", version: "some updated version"}
  @invalid_attrs %{body: nil, title: nil, version: nil}

  def fixture(:change_log) do
    {:ok, change_log} = ChangeLogs.create_change_log(@create_attrs)
    change_log
  end

  describe "index" do
    test "lists all change_logs", %{conn: conn} do
      conn = get(conn, Routes.change_log_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Change logs"
    end
  end

  describe "new change_log" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.change_log_path(conn, :new))
      assert html_response(conn, 200) =~ "New Change log"
    end
  end

  describe "create change_log" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.change_log_path(conn, :create), change_log: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.change_log_path(conn, :show, id)

      conn = get(conn, Routes.change_log_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Change log"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.change_log_path(conn, :create), change_log: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Change log"
    end
  end

  describe "edit change_log" do
    setup [:create_change_log]

    test "renders form for editing chosen change_log", %{conn: conn, change_log: change_log} do
      conn = get(conn, Routes.change_log_path(conn, :edit, change_log))
      assert html_response(conn, 200) =~ "Edit Change log"
    end
  end

  describe "update change_log" do
    setup [:create_change_log]

    test "redirects when data is valid", %{conn: conn, change_log: change_log} do
      conn = put(conn, Routes.change_log_path(conn, :update, change_log), change_log: @update_attrs)
      assert redirected_to(conn) == Routes.change_log_path(conn, :show, change_log)

      conn = get(conn, Routes.change_log_path(conn, :show, change_log))
      assert html_response(conn, 200) =~ "some updated body"
    end

    test "renders errors when data is invalid", %{conn: conn, change_log: change_log} do
      conn = put(conn, Routes.change_log_path(conn, :update, change_log), change_log: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Change log"
    end
  end

  describe "delete change_log" do
    setup [:create_change_log]

    test "deletes chosen change_log", %{conn: conn, change_log: change_log} do
      conn = delete(conn, Routes.change_log_path(conn, :delete, change_log))
      assert redirected_to(conn) == Routes.change_log_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.change_log_path(conn, :show, change_log))
      end
    end
  end

  defp create_change_log(_) do
    change_log = fixture(:change_log)
    %{change_log: change_log}
  end
end
