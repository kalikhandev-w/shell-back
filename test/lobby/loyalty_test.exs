defmodule Lobby.LoyaltyTest do
  use Lobby.DataCase, async: true

  alias Lobby.Loyalty
  import Lobby.Fixtures

  setup do
    club = create_club()
    user = create_user(club)
    %{club: club, user: user}
  end

  test "create_bonus and list transactions", %{club: club, user: user} do
    {:ok, tx} = Loyalty.create_bonus(%{
      user_id: user.id, club_id: club.id,
      amount: 1000, reason: "cashback"
    })
    assert tx.amount == 1000

    txs = Loyalty.list_bonus_transactions(user.id, club.id)
    assert length(txs) == 1
  end

  test "bonus_balance sums transactions", %{club: club, user: user} do
    Loyalty.create_bonus(%{user_id: user.id, club_id: club.id, amount: 1000, reason: "cashback"})
    Loyalty.create_bonus(%{user_id: user.id, club_id: club.id, amount: 500, reason: "referral"})
    balance = Loyalty.bonus_balance(user.id, club.id)
    assert balance == 1500
  end

  test "CRUD promo rules", %{club: club} do
    {:ok, rule} = Loyalty.create_promo_rule(%{
      "name" => "Off-peak", "type" => "time_based",
      "conditions" => %{"hours_from" => 10, "hours_to" => 14},
      "discount_percent" => 20, "club_id" => club.id
    })
    assert rule.name == "Off-peak"

    rules = Loyalty.list_promo_rules(club.id)
    assert length(rules) == 1

    {:ok, updated} = Loyalty.update_promo_rule(rule, %{"discount_percent" => 30})
    assert updated.discount_percent == 30

    {:ok, _} = Loyalty.delete_promo_rule(updated)
    assert Loyalty.get_promo_rule(rule.id) == nil
  end
end
