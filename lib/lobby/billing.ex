defmodule Lobby.Billing do
  alias Lobby.Repo
  alias Lobby.Billing.Payment
  alias Lobby.Accounts

  def get_payment(id), do: Repo.get(Payment, id)

  def create_payment(attrs) do
    %Payment{}
    |> Payment.changeset(attrs)
    |> Repo.insert()
  end

  def process_payment(attrs) do
    case attrs[:method] || attrs["method"] do
      "balance" -> process_balance_payment(attrs)
      "cash" -> process_cash_payment(attrs)
      "kaspi_qr" -> {:error, :not_implemented}
      _ -> {:error, :invalid_method}
    end
  end

  defp process_balance_payment(attrs) do
    user_id = attrs[:user_id] || attrs["user_id"]
    amount = attrs[:amount_tiyn] || attrs["amount_tiyn"]

    user = Accounts.get_user(user_id)

    cond do
      is_nil(user) ->
        {:error, :user_not_found}

      user.balance_tiyn < amount ->
        {:error, :insufficient_balance}

      true ->
        Repo.transaction(fn ->
          {:ok, _user} = Accounts.deduct_balance(user, amount)
          {:ok, payment} = create_payment(Map.put(attrs, :status, "confirmed"))
          payment
        end)
    end
  end

  defp process_cash_payment(attrs) do
    # Cash payments are created as pending; admin confirms later
    create_payment(attrs)
  end

  def confirm_payment(payment) do
    payment
    |> Ecto.Changeset.change(status: "confirmed")
    |> Repo.update()
  end

  def cancel_payment(payment) do
    payment
    |> Ecto.Changeset.change(status: "cancelled")
    |> Repo.update()
  end

  # ── Admin queries ──

  def list_payments(club_id, opts \\ []) do
    import Ecto.Query

    query =
      Payment
      |> where([p], p.club_id == ^club_id)

    query =
      case Keyword.get(opts, :status) do
        nil -> query
        status -> where(query, [p], p.status == ^status)
      end

    query
    |> order_by(desc: :inserted_at)
    |> limit(^Keyword.get(opts, :limit, 50))
    |> Repo.all()
  end
end
