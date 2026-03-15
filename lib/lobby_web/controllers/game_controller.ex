defmodule LobbyWeb.GameController do
  use LobbyWeb, :controller

  alias Lobby.Gaming

  def index(conn, %{"club_id" => club_id}) do
    games = Gaming.list_games(club_id)

    conn
    |> put_status(200)
    |> json(%{games: Enum.map(games, &game_json/1)})
  end

  def popular(conn, %{"club_id" => club_id}) do
    games = Gaming.get_popular_games(club_id)

    conn
    |> put_status(200)
    |> json(%{games: Enum.map(games, &popular_json/1)})
  end

  defp game_json(game) do
    %{
      id: game.id,
      name: game.name,
      exe_name: game.exe_name,
      exe_path: game.exe_path,
      category: game.category,
      cover_url: game.cover_url
    }
  end

  defp popular_json(game) do
    %{name: game.name, player_count: 0}
  end
end
