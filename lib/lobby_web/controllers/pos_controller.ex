defmodule LobbyWeb.PosController do
  use LobbyWeb, :controller

  alias Lobby.Pos
  alias Lobby.Guardian

  def menu(conn, %{"club_id" => club_id} = params) do
    items = Pos.list_menu_items(club_id, params["category_id"])
    categories = Pos.list_categories(club_id)

    conn
    |> put_status(200)
    |> json(%{
      categories: Enum.map(categories, &category_json/1),
      items: Enum.map(items, &item_json/1)
    })
  end

  def create_order(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    attrs = %{
      items: params["items"],
      total_price_tiyn: params["total_price_tiyn"],
      user_id: user.id,
      session_id: params["session_id"],
      club_id: params["club_id"]
    }

    case Pos.create_order(attrs) do
      {:ok, order} ->
        # Broadcast to admin via PubSub
        Phoenix.PubSub.broadcast(
          Lobby.PubSub,
          "club:#{order.club_id}",
          {:new_order, order}
        )

        conn
        |> put_status(201)
        |> json(%{order: order_json(order)})

      {:error, _changeset} ->
        conn
        |> put_status(422)
        |> json(%{error: "Failed to create order"})
    end
  end

  def show_order(conn, %{"id" => id}) do
    case Pos.get_order(id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Order not found"})

      order ->
        conn |> put_status(200) |> json(%{order: order_json(order)})
    end
  end

  def update_order(conn, %{"id" => id, "status" => status}) do
    case Pos.get_order(id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Order not found"})

      order ->
        {:ok, order} = Pos.update_order_status(order, status)

        # Broadcast status change to PC channel
        if order.session_id do
          Phoenix.PubSub.broadcast(
            Lobby.PubSub,
            "pc:#{order.session_id}",
            {:order_status, %{order_id: order.id, status: order.status}}
          )
        end

        conn |> put_status(200) |> json(%{order: order_json(order)})
    end
  end

  defp category_json(cat) do
    %{id: cat.id, name: cat.name, sort_order: cat.sort_order}
  end

  defp item_json(item) do
    %{
      id: item.id,
      name: item.name,
      price_tiyn: item.price_tiyn,
      image_url: item.image_url,
      is_available: item.is_available,
      category_id: item.category_id
    }
  end

  defp order_json(order) do
    %{
      id: order.id,
      status: order.status,
      items: order.items,
      total_price_tiyn: order.total_price_tiyn,
      inserted_at: order.inserted_at
    }
  end
end
