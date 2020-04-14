defmodule MiataBotWeb.PageControllerTest do
  use MiataBotWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert conn
  end
end
