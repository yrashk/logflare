defmodule Logflare.ChangeLogsTest do
  use Logflare.DataCase

  alias Logflare.ChangeLogs

  describe "change_logs" do
    alias Logflare.ChangeLogs.ChangeLog

    @valid_attrs %{body: "some body", title: "some title", version: "some version"}
    @update_attrs %{body: "some updated body", title: "some updated title", version: "some updated version"}
    @invalid_attrs %{body: nil, title: nil, version: nil}

    def change_log_fixture(attrs \\ %{}) do
      {:ok, change_log} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ChangeLogs.create_change_log()

      change_log
    end

    test "list_change_logs/0 returns all change_logs" do
      change_log = change_log_fixture()
      assert ChangeLogs.list_change_logs() == [change_log]
    end

    test "get_change_log!/1 returns the change_log with given id" do
      change_log = change_log_fixture()
      assert ChangeLogs.get_change_log!(change_log.id) == change_log
    end

    test "create_change_log/1 with valid data creates a change_log" do
      assert {:ok, %ChangeLog{} = change_log} = ChangeLogs.create_change_log(@valid_attrs)
      assert change_log.body == "some body"
      assert change_log.title == "some title"
      assert change_log.version == "some version"
    end

    test "create_change_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ChangeLogs.create_change_log(@invalid_attrs)
    end

    test "update_change_log/2 with valid data updates the change_log" do
      change_log = change_log_fixture()
      assert {:ok, %ChangeLog{} = change_log} = ChangeLogs.update_change_log(change_log, @update_attrs)
      assert change_log.body == "some updated body"
      assert change_log.title == "some updated title"
      assert change_log.version == "some updated version"
    end

    test "update_change_log/2 with invalid data returns error changeset" do
      change_log = change_log_fixture()
      assert {:error, %Ecto.Changeset{}} = ChangeLogs.update_change_log(change_log, @invalid_attrs)
      assert change_log == ChangeLogs.get_change_log!(change_log.id)
    end

    test "delete_change_log/1 deletes the change_log" do
      change_log = change_log_fixture()
      assert {:ok, %ChangeLog{}} = ChangeLogs.delete_change_log(change_log)
      assert_raise Ecto.NoResultsError, fn -> ChangeLogs.get_change_log!(change_log.id) end
    end

    test "change_change_log/1 returns a change_log changeset" do
      change_log = change_log_fixture()
      assert %Ecto.Changeset{} = ChangeLogs.change_change_log(change_log)
    end
  end
end
