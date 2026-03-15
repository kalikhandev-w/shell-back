defmodule LobbyWeb.UserSocket do
  use Phoenix.Socket

  channel "pc:*", LobbyWeb.PcChannel
  channel "club:*", LobbyWeb.ClubChannel

  @impl true
  def connect(%{"token" => token, "pc_token" => pc_token}, socket, _connect_info) do
    # Verify JWT token if present
    user =
      case Lobby.Guardian.resource_from_token(token) do
        {:ok, user, _claims} -> user
        _ -> nil
      end

    # Verify PC token
    pc = Lobby.Clubs.get_pc_by_token(pc_token)

    if pc do
      socket =
        socket
        |> assign(:current_user, user)
        |> assign(:pc, pc)
        |> assign(:club_id, pc.club_id)

      {:ok, socket}
    else
      :error
    end
  end

  def connect(%{"pc_token" => pc_token}, socket, _connect_info) do
    case Lobby.Clubs.get_pc_by_token(pc_token) do
      nil ->
        :error

      pc ->
        socket =
          socket
          |> assign(:current_user, nil)
          |> assign(:pc, pc)
          |> assign(:club_id, pc.club_id)

        {:ok, socket}
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "pc_socket:#{socket.assigns.pc.id}"
end
