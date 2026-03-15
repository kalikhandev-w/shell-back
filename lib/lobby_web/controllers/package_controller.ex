defmodule LobbyWeb.PackageController do
  use LobbyWeb, :controller

  alias Lobby.{Packages, Accounts}
  alias Lobby.Guardian

  # Admin: list package templates
  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    packages = Packages.list_all_packages(user.club_id)
    conn |> put_status(200) |> json(%{packages: Enum.map(packages, &package_json/1)})
  end

  def create(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    attrs = Map.put(params, "club_id", user.club_id)

    case Packages.create_package(attrs) do
      {:ok, pkg} -> conn |> put_status(201) |> json(%{package: package_json(pkg)})
      {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(cs)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    case Packages.get_package(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Package not found"})
      pkg ->
        case Packages.update_package(pkg, params) do
          {:ok, pkg} -> conn |> put_status(200) |> json(%{package: package_json(pkg)})
          {:error, cs} -> conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(cs)})
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Packages.get_package(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Package not found"})
      pkg ->
        case Packages.delete_package(pkg) do
          {:ok, _} -> conn |> put_status(200) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to delete package"})
        end
    end
  end

  # Sell package to a gamer
  def sell(conn, %{"user_id" => user_id, "package_id" => package_id}) do
    admin = Guardian.Plug.current_resource(conn)

    case {Accounts.get_user(user_id), Packages.get_package(package_id)} do
      {nil, _} -> conn |> put_status(404) |> json(%{error: "User not found"})
      {_, nil} -> conn |> put_status(404) |> json(%{error: "Package not found"})
      {_user, package} ->
        case Packages.sell_package(user_id, package, admin.id) do
          {:ok, gp} ->
            conn |> put_status(201) |> json(%{gamer_package: gamer_package_json(gp)})
          {:error, cs} ->
            conn |> put_status(422) |> json(%{error: "Failed", details: changeset_errors(cs)})
        end
    end
  end

  # List gamer's active packages
  def gamer_packages(conn, %{"user_id" => user_id}) do
    admin = Guardian.Plug.current_resource(conn)
    packages = Packages.list_active_packages(user_id, admin.club_id)
    conn |> put_status(200) |> json(%{gamer_packages: Enum.map(packages, &gamer_package_json/1)})
  end

  defp package_json(p) do
    %{id: p.id, name: p.name, type: p.type, hours: p.hours,
      price: p.price, validity_days: p.validity_days, is_active: p.is_active}
  end

  defp gamer_package_json(gp) do
    %{id: gp.id, hours_remaining: gp.hours_remaining, purchased_at: gp.purchased_at,
      expires_at: gp.expires_at, status: gp.status, package_id: gp.package_id,
      user_id: gp.user_id}
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
