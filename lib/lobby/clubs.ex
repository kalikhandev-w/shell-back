defmodule Lobby.Clubs do
  import Ecto.Query
  alias Lobby.Repo
  alias Lobby.Clubs.{Club, PC, Tariff}

  # ── Clubs ──

  def get_club(id), do: Repo.get(Club, id)

  def get_club_by_slug(slug), do: Repo.get_by(Club, slug: slug)

  # ── PCs ──

  def get_pc(id), do: Repo.get(PC, id)

  def get_pc_by_token(token), do: Repo.get_by(PC, pc_token: token)

  def register_pc(attrs) do
    %PC{}
    |> PC.changeset(attrs)
    |> Repo.insert()
  end

  def update_heartbeat(pc, attrs) do
    pc
    |> PC.heartbeat_changeset(attrs)
    |> Repo.update()
  end

  def set_pc_status(pc, status) do
    pc
    |> Ecto.Changeset.change(status: status)
    |> Repo.update()
  end

  def list_pcs(club_id) do
    PC
    |> where([p], p.club_id == ^club_id)
    |> order_by(:hostname)
    |> Repo.all()
  end

  # ── Tariffs ──

  def list_tariffs(club_id) do
    Tariff
    |> where([t], t.club_id == ^club_id and t.is_active == true)
    |> order_by(:name)
    |> Repo.all()
  end

  def get_tariff(id), do: Repo.get(Tariff, id)

  def create_tariff(attrs) do
    %Tariff{}
    |> Tariff.changeset(attrs)
    |> Repo.insert()
  end

  def update_tariff(tariff, attrs) do
    tariff
    |> Tariff.changeset(attrs)
    |> Repo.update()
  end

  def delete_tariff(tariff) do
    Repo.delete(tariff)
  end

  # ── Club CRUD ──

  def update_club(club, attrs) do
    club
    |> Club.changeset(attrs)
    |> Repo.update()
  end

  # ── PC CRUD ──

  def update_pc(pc, attrs) do
    pc
    |> PC.changeset(attrs)
    |> Repo.update()
  end

  def delete_pc(pc) do
    Repo.delete(pc)
  end

  def list_all_tariffs(club_id) do
    Tariff
    |> where([t], t.club_id == ^club_id)
    |> order_by(:name)
    |> Repo.all()
  end

  # ── Zones ──

  alias Lobby.Clubs.Zone

  def get_zone(id), do: Repo.get(Zone, id)

  def list_zones(club_id) do
    Zone
    |> where([z], z.club_id == ^club_id)
    |> order_by(:sort_order)
    |> Repo.all()
  end

  def create_zone(attrs) do
    %Zone{}
    |> Zone.changeset(attrs)
    |> Repo.insert()
  end

  def update_zone(zone, attrs) do
    zone
    |> Zone.changeset(attrs)
    |> Repo.update()
  end

  def delete_zone(zone), do: Repo.delete(zone)
end
