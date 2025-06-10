defmodule StacksWeb.ItemControllerTest do
  use StacksWeb.ConnCase

  import Stacks.ItemsFixtures

  alias Stacks.Items.Item

  @create_attrs %{
    item_type: "some item_type",
    metadata: %{},
    source_url: "some source_url",
    text_content: "some text_content",
    enrichment_status: :pending
  }
  @update_attrs %{
    item_type: "some updated item_type",
    metadata: %{},
    source_url: "some updated source_url",
    text_content: "some updated text_content",
    enrichment_status: :completed
  }
  @invalid_attrs %{item_type: nil, metadata: nil, source_url: nil, text_content: nil, enrichment_status: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all items", %{conn: conn} do
      conn = get(conn, ~p"/api/items")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create item" do
    test "renders item when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/items", item: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/items/#{id}")

      assert %{
               "id" => ^id,
               "item_type" => "some item_type",
               "metadata" => %{},
               "source_url" => "some source_url",
               "text_content" => "some text_content",
               "inserted_at" => _,
               "updated_at" => _
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/items", item: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "returns existing item when source_url already exists", %{conn: conn} do
      # Create first item
      conn1 = post(conn, ~p"/api/items", item: @create_attrs)
      assert %{"id" => id1} = json_response(conn1, 201)["data"]

      # Try to create another item with the same source_url
      conn2 = post(conn, ~p"/api/items", item: @create_attrs)
      assert %{"id" => id2} = json_response(conn2, 200)["data"]

      # Should return the same item
      assert id1 == id2
    end

    test "creates new item when source_url is different", %{conn: conn} do
      # Create first item
      conn1 = post(conn, ~p"/api/items", item: @create_attrs)
      assert %{"id" => id1} = json_response(conn1, 201)["data"]

      # Create item with different source_url
      different_attrs = Map.put(@create_attrs, :source_url, "different_source_url")
      conn2 = post(conn, ~p"/api/items", item: different_attrs)
      assert %{"id" => id2} = json_response(conn2, 201)["data"]

      # Should create a new item
      assert id1 != id2
    end
  end

  describe "update item" do
    setup [:create_item]

    test "renders item when data is valid", %{conn: conn, item: %Item{id: id} = item} do
      conn = put(conn, ~p"/api/items/#{item}", item: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/items/#{id}")

      assert %{
               "id" => ^id,
               "item_type" => "some updated item_type",
               "metadata" => %{},
               "source_url" => "some updated source_url",
               "text_content" => "some updated text_content",
               "inserted_at" => _,
               "updated_at" => _
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, item: item} do
      conn = put(conn, ~p"/api/items/#{item}", item: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete item" do
    setup [:create_item]

    test "deletes chosen item", %{conn: conn, item: item} do
      conn = delete(conn, ~p"/api/items/#{item}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/items/#{item}")
      end
    end
  end

  defp create_item(_) do
    item = item_fixture()
    %{item: item}
  end
end
