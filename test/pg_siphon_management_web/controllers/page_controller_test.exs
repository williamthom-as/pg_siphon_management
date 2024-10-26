defmodule PgSiphonManagementWeb.PageControllerTest do
  use PgSiphonManagementWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "PgSiphonManagement"
  end
end
