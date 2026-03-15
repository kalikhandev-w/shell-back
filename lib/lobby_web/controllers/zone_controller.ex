defmodule LobbyWeb.ZoneController do
  use LobbyWeb, :controller

  alias Lobby.Clubs
  alias Lobby.Guardian

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    zones = Clubs.list_zones(user.club_id)
    conn |> put_status(200) |> json(%{zones: Enum.map(zones, &zone_json/1)})
  end

  def create(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    attrs = Map.put(params, "club_id", user.club_id)

    case Clubs.create_zone(attrs) do
      {:ok, zone} -> conn |> put_status(201) |> json(%{zone: zone_json(zone)})
      {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: cs_errors(cs)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    case Clubs.get_zone(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Zone not found"})
      zone ->
        case Clubs.update_zone(zone, params) do
          {:ok, zone} -> conn |> put_status(200) |> json(%{zone: zone_json(zone)})
          {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: cs_errors(cs)})
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Clubs.get_zone(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Zone not found"})
      zone ->
        case Clubs.delete_zone(zone) do
          {:ok, _} -> conn |> put_status(200) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to delete zone"})
        end
    end
  end

  defp zone_json(z) do
    %{id: z.id, name: z.name, color: z.color, sort_order: z.sort_order}
  end

  defp cs_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
