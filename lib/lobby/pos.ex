defmodule Lobby.Pos do
  import Ecto.Query
  alias Lobby.Repo
  alias Lobby.Pos.{MenuCategory, MenuItem, Order}

  # ── Menu ──

  def list_categories(club_id) do
    MenuCategory
    |> where([c], c.club_id == ^club_id)
    |> order_by(:sort_order)
    |> preload(:items)
    |> Repo.all()
  end

  def list_menu_items(club_id, category_id \\ nil) do
    query =
      MenuItem
      |> where([m], m.club_id == ^club_id and m.is_available == true)

    query =
      if category_id do
        where(query, [m], m.category_id == ^category_id)
      else
        query
      end

    query
    |> order_by(:name)
    |> Repo.all()
  end

  # ── Orders ──

  def get_order(id), do: Repo.get(Order, id)

  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def update_order_status(order, status) do
    order
    |> Ecto.Changeset.change(status: status)
    |> Repo.update()
  end

  def list_orders(club_id, opts \\ []) do
    query =
      Order
      |> where([o], o.club_id == ^club_id)

    query =
      case Keyword.get(opts, :status) do
        nil -> query
        status -> where(query, [o], o.status == ^status)
      end

    query
    |> order_by(desc: :inserted_at)
    |> limit(^Keyword.get(opts, :limit, 50))
    |> Repo.all()
  end

  def list_orders_for_session(session_id) do
    Order
    |> where([o], o.session_id == ^session_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # ── Category CRUD ──

  def get_category(id), do: Repo.get(MenuCategory, id)

  def create_category(attrs) do
    %MenuCategory{}
    |> MenuCategory.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(category, attrs) do
    category
    |> MenuCategory.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(category) do
    Repo.delete(category)
  end

  # ── Menu Item CRUD ──

  def get_menu_item(id), do: Repo.get(MenuItem, id)

  def create_menu_item(attrs) do
    %MenuItem{}
    |> MenuItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_menu_item(item, attrs) do
    item
    |> MenuItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_menu_item(item) do
    Repo.delete(item)
  end
end
