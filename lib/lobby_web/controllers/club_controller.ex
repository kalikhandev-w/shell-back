defmodule LobbyWeb.ClubController do
  use LobbyWeb, :controller

  alias Lobby.Clubs

  def register_pc(conn, %{"pc_token" => pc_token} = params) do
    case Clubs.get_pc_by_token(pc_token) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Invalid PC token"})

      pc ->
        pc = Lobby.Repo.preload(pc, [:club])
        tariffs = Clubs.list_tariffs(pc.club_id)

        attrs = %{
          hostname: params["hostname"],
          mac_address: params["mac_address"],
          ip_address: params["ip_address"],
          specs: params["specs"] || %{}
        }

        case Clubs.update_heartbeat(pc, attrs) do
          {:ok, pc} ->
            conn
            |> put_status(200)
            |> json(%{
              club: club_json(pc.club),
              pc: pc_json(pc),
              tariffs: Enum.map(tariffs, &tariff_json/1)
            })
          {:error, _} ->
            conn |> put_status(422) |> json(%{error: "Failed to update PC"})
        end
    end
  end

  def show(conn, %{"id" => id}) do
    case Clubs.get_club(id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Club not found"})

      club ->
        conn |> put_status(200) |> json(%{club: club_json(club)})
    end
  end

  defp club_json(club) do
    %{
      id: club.id,
      name: club.name,
      slug: club.slug,
      logo_url: club.logo_url,
      address: club.address,
      timezone: club.timezone
    }
  end

  defp pc_json(pc) do
    %{
      id: pc.id,
      hostname: pc.hostname,
      mac_address: pc.mac_address,
      status: pc.status,
      zone: pc.zone
    }
  end

  defp tariff_json(tariff) do
    %{
      id: tariff.id,
      name: tariff.name,
      zone: tariff.zone,
      price_per_hour_tiyn: tariff.price_per_hour_tiyn
    }
  end
end
