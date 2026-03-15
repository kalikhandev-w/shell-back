defmodule Lobby.Loyalty do
  import Ecto.Query
  alias Lobby.Repo
  alias Lobby.Loyalty.{BonusTransaction, PromoRule}

  # Bonus transactions
  def create_bonus(attrs) do
    %BonusTransaction{}
    |> BonusTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_bonus_transactions(user_id, club_id, opts \\ []) do
    query =
      BonusTransaction
      |> where([b], b.user_id == ^user_id and b.club_id == ^club_id)

    query
    |> order_by(desc: :inserted_at)
    |> limit(^Keyword.get(opts, :limit, 50))
    |> Repo.all()
  end

  def bonus_balance(user_id, club_id) do
    BonusTransaction
    |> where([b], b.user_id == ^user_id and b.club_id == ^club_id)
    |> Repo.aggregate(:sum, :amount) || 0
  end

  # Promo rules
  def get_promo_rule(id), do: Repo.get(PromoRule, id)

  def list_promo_rules(club_id) do
    PromoRule
    |> where([p], p.club_id == ^club_id)
    |> order_by(:name)
    |> Repo.all()
  end

  def create_promo_rule(attrs) do
    %PromoRule{}
    |> PromoRule.changeset(attrs)
    |> Repo.insert()
  end

  def update_promo_rule(rule, attrs) do
    rule
    |> PromoRule.changeset(attrs)
    |> Repo.update()
  end

  def delete_promo_rule(rule), do: Repo.delete(rule)
end
