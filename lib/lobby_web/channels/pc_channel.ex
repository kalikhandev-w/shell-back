defmodule LobbyWeb.PcChannel do
  use Phoenix.Channel

  @impl true
  def join("pc:" <> pc_id, _params, socket) do
    if socket.assigns.pc.id == pc_id do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    # Subscribe to PubSub for this PC
    Phoenix.PubSub.subscribe(Lobby.PubSub, "pc:#{socket.assigns.pc.id}")
    {:noreply, socket}
  end

  def handle_info({:order_status, payload}, socket) do
    push(socket, "order_status", payload)
    {:noreply, socket}
  end

  def handle_info({:session_update, payload}, socket) do
    push(socket, "session_update", payload)
    {:noreply, socket}
  end

  def handle_info({:admin_command, payload}, socket) do
    push(socket, "admin_command", payload)
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  # Admin can push commands to a PC via this channel
  @impl true
  def handle_in("admin_command", %{"action" => _action} = payload, socket) do
    # Verify sender is admin (check user role)
    user = socket.assigns.current_user

    if user && user.is_admin do
      broadcast!(socket, "admin_command", payload)
      {:reply, :ok, socket}
    else
      {:reply, {:error, %{reason: "unauthorized"}}, socket}
    end
  end

  def handle_in(_event, _payload, socket) do
    {:noreply, socket}
  end
end
