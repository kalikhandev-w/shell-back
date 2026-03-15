defmodule LobbyWeb.LoyaltyController do
  use LobbyWeb, :controller

  alias Lobby.Loyalty
  alias Lobby.Guardian

  # Bonus transactions
  def award_bonus(conn, %{"user_id" => user_id, "amount" => amount} = params) do
    admin = Guardian.Plug.current_resource(conn)

    attrs = %{
      user_id: user_id,
      club_id: admin.club_id,
      amount: amount,
      reason: params["reason"] || "admin"
    }

    case Loyalty.create_bonus(attrs) do
      {:ok, tx} -> conn |> put_status(201) |> json(%{bonus: bonus_json(tx)})
      {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed"})
    end
  end

  def bonus_history(conn, %{"user_id" => user_id}) do
    admin = Guardian.Plug.current_resource(conn)
    txs = Loyalty.list_bonus_transactions(user_id, admin.club_id)
    balance = Loyalty.bonus_balance(user_id, admin.club_id)
    conn |> put_status(200) |> json(%{transactions: Enum.map(txs, &bonus_json/1), balance: balance})
  end

  # Promo rules
  def list_promos(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    rules = Loyalty.list_promo_rules(user.club_id)
    conn |> put_status(200) |> json(%{promo_rules: Enum.map(rules, &promo_json/1)})
  end

  def create_promo(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    attrs = Map.put(params, "club_id", user.club_id)

    case Loyalty.create_promo_rule(attrs) do
      {:ok, rule} -> conn |> put_status(201) |> json(%{promo_rule: promo_json(rule)})
      {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed"})
    end
  end

  def update_promo(conn, %{"id" => id} = params) do
    case Loyalty.get_promo_rule(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Promo rule not found"})
      rule ->
        case Loyalty.update_promo_rule(rule, params) do
          {:ok, rule} -> conn |> put_status(200) |> json(%{promo_rule: promo_json(rule)})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to update promo rule"})
        end
    end
  end

  def delete_promo(conn, %{"id" => id}) do
    case Loyalty.get_promo_rule(id) do
      nil -> conn |> put_status(404) |> json(%{error: "Promo rule not found"})
      rule ->
        case Loyalty.delete_promo_rule(rule) do
          {:ok, _} -> conn |> put_status(200) |> json(%{ok: true})
          {:error, _} -> conn |> put_status(422) |> json(%{error: "Failed to delete promo rule"})
        end
    end
  end

  defp bonus_json(tx) do
    %{id: tx.id, amount: tx.amount, reason: tx.reason, user_id: tx.user_id,
      inserted_at: tx.inserted_at}
  end

  defp promo_json(r) do
    %{id: r.id, name: r.name, type: r.type, conditions: r.conditions,
      discount_percent: r.discount_percent, is_active: r.is_active}
  end
end
