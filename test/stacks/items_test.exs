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

    test "create_item/1 with duplicate source_url returns error changeset" do
      valid_attrs = %{item_type: "some item_type", metadata: %{}, source_url: "duplicate_url", text_content: "some text_content", enrichment_status: :pending}

      assert {:ok, %Item{}} = Items.create_item(valid_attrs)
      assert {:error, %Ecto.Changeset{} = changeset} = Items.create_item(valid_attrs)
      assert changeset.errors[:source_url] == {"has already been taken", [constraint: :unique, constraint_name: "items_source_url_index"]}
    end

    test "get_item_by_source_url/1 returns the item with given source_url" do
      item = item_fixture()
      assert Items.get_item_by_source_url(item.source_url) == item
    end

    test "get_item_by_source_url/1 returns nil when source_url does not exist" do
      assert Items.get_item_by_source_url("non_existent_url") == nil
    end

    test "create_or_get_item/1 creates new item when source_url is unique" do
      valid_attrs = %{item_type: "some item_type", metadata: %{}, source_url: "unique_url", text_content: "some text_content", enrichment_status: :pending}

      assert {:ok, %Item{} = item} = Items.create_or_get_item(valid_attrs)
      assert item.source_url == "unique_url"
    end

    test "create_or_get_item/1 returns existing item when source_url already exists" do
      existing_item = item_fixture()
      
      duplicate_attrs = %{item_type: "different type", metadata: %{foo: "bar"}, source_url: existing_item.source_url, text_content: "different content", enrichment_status: :completed}

      assert {:existing, %Item{} = returned_item} = Items.create_or_get_item(duplicate_attrs)
      assert returned_item.id == existing_item.id
      assert returned_item.source_url == existing_item.source_url
    end
  end
end
