defmodule StacksWeb.PageControllerTest do
  use StacksWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Home"
  end
end
