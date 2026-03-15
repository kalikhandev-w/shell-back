defmodule LobbyWeb.ClubChannel do
  use Phoenix.Channel

  @impl true
  def join("club:" <> club_id, _params, socket) do
    if socket.assigns.club_id == club_id do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    Phoenix.PubSub.subscribe(Lobby.PubSub, "club:#{socket.assigns.club_id}")
    {:noreply, socket}
  end

  def handle_info({:tournament_announce, payload}, socket) do
    push(socket, "tournament_announce", payload)
    {:noreply, socket}
  end

  def handle_info({:promo_announce, payload}, socket) do
    push(socket, "promo_announce", payload)
    {:noreply, socket}
  end

  def handle_info({:new_order, _order}, socket) do
    # Optionally broadcast new orders to club channel for admin visibility
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}
end
