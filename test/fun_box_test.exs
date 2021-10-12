defmodule FunBoxTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts FunBox.Router.init([])

  test "visited domains" do
    conn = conn(:get, "/visited_domains?from=0&to=1")
    conn = FunBox.Router.call(conn, @opts)
    assert conn.state == :sent
    assert conn.status == 200
    assert Poison.decode!(conn.resp_body) == %{"domains" => [], "status" => "ok"}
  end

  test "visited links ok" do
    conn = conn(:post, "/visited_links", %{links: ["https://ya.ru"]})
    conn = FunBox.Router.call(conn, @opts)
    assert conn.status == 201
  end

  test "visited links error" do
    conn = conn(:post, "/visited_links", %{})
    conn = FunBox.Router.call(conn, @opts)
	assert conn.status == 201
    assert Poison.decode(conn.resp_body) == {:ok, %{"status" => "error"}}
  end

  test "404" do
    conn = conn(:get, "/fail")
    conn = FunBox.Router.call(conn, @opts)
    assert conn.status == 404
  end
end
