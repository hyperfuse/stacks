defmodule Stacks.ItemsTest do
  use Stacks.DataCase

  alias Stacks.Items

  describe "items" do
    alias Stacks.Items.Item

    import Stacks.ItemsFixtures

    @invalid_attrs %{item_type: nil, metadata: nil, source_url: nil, text_content: nil, enrichment_status: nil}

    test "list_items/0 returns all items" do
      item = item_fixture()
      assert Items.list_items() == [item]
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture()
      assert Items.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      valid_attrs = %{item_type: "some item_type", metadata: %{}, source_url: "some source_url", text_content: "some text_content", enrichment_status: :pending}

      assert {:ok, %Item{} = item} = Items.create_item(valid_attrs)
      assert item.item_type == "some item_type"
      assert item.metadata == %{}
      assert item.source_url == "some source_url"
      assert item.text_content == "some text_content"
      assert item.enrichment_status == :pending
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Items.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      update_attrs = %{item_type: "some updated item_type", metadata: %{}, source_url: "some updated source_url", text_content: "some updated text_content", enrichment_status: :completed}

      assert {:ok, %Item{} = item} = Items.update_item(item, update_attrs)
      assert item.item_type == "some updated item_type"
      assert item.metadata == %{}
      assert item.source_url == "some updated source_url"
      assert item.text_content == "some updated text_content"
      assert item.enrichment_status == :completed
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture()
      assert {:error, %Ecto.Changeset{}} = Items.update_item(item, @invalid_attrs)
      assert item == Items.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture()
      assert {:ok, %Item{}} = Items.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Items.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture()
      assert %Ecto.Changeset{} = Items.change_item(item)
    end
  end
end
