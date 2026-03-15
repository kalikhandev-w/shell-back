defmodule Lobby.Packages do
  import Ecto.Query
  alias Lobby.Repo
  alias Lobby.Packages.{Package, GamerPackage}

  # Package templates
  def get_package(id), do: Repo.get(Package, id)

  def list_packages(club_id) do
    Package
    |> where([p], p.club_id == ^club_id and p.is_active == true)
    |> order_by(:name)
    |> Repo.all()
  end

  def list_all_packages(club_id) do
    Package
    |> where([p], p.club_id == ^club_id)
    |> order_by(:name)
    |> Repo.all()
  end

  def create_package(attrs) do
    %Package{}
    |> Package.changeset(attrs)
    |> Repo.insert()
  end

  def update_package(pkg, attrs) do
    pkg
    |> Package.changeset(attrs)
    |> Repo.update()
  end

  def delete_package(pkg), do: Repo.delete(pkg)

  # Gamer packages (purchased)
  def get_gamer_package(id), do: Repo.get(GamerPackage, id)

  def sell_package(user_id, package, sold_by_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expires = DateTime.add(now, package.validity_days * 86400, :second)

    attrs = %{
      user_id: user_id,
      club_id: package.club_id,
      package_id: package.id,
      hours_remaining: package.hours && Decimal.new(package.hours),
      purchased_at: now,
      expires_at: expires,
      sold_by: sold_by_id,
      status: "active"
    }

    %GamerPackage{}
    |> GamerPackage.changeset(attrs)
    |> Repo.insert()
  end

  def list_active_packages(user_id, club_id) do
    now = DateTime.utc_now()

    GamerPackage
    |> where([gp], gp.user_id == ^user_id and gp.club_id == ^club_id and gp.status == "active")
    |> where([gp], gp.expires_at > ^now)
    |> order_by(asc: :expires_at)
    |> Repo.all()
    |> Repo.preload(:package)
  end

  def deduct_hours(gamer_package, hours) do
    gamer_package
    |> GamerPackage.deduct_changeset(hours)
    |> Repo.update()
  end
end
