defmodule LobbyWeb.PaymentController do
  use LobbyWeb, :controller

  alias Lobby.Billing
  alias Lobby.Guardian

  def create(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    attrs = %{
      method: params["method"],
      amount_tiyn: params["amount_tiyn"],
      user_id: user.id,
      session_id: params["session_id"],
      club_id: params["club_id"],
      status: "pending"
    }

    case Billing.process_payment(attrs) do
      {:ok, payment} ->
        conn
        |> put_status(201)
        |> json(%{payment: payment_json(payment)})

      {:error, :insufficient_balance} ->
        conn
        |> put_status(422)
        |> json(%{error: "Insufficient balance"})

      {:error, :not_implemented} ->
        conn
        |> put_status(501)
        |> json(%{error: "Payment method not yet available"})

      {:error, _reason} ->
        conn
        |> put_status(422)
        |> json(%{error: "Payment failed"})
    end
  end

  def show(conn, %{"id" => id}) do
    case Billing.get_payment(id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Payment not found"})

      payment ->
        conn |> put_status(200) |> json(%{payment: payment_json(payment)})
    end
  end

  def confirm(conn, %{"id" => id}) do
    case Billing.get_payment(id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Payment not found"})

      payment ->
        {:ok, payment} = Billing.confirm_payment(payment)
        conn |> put_status(200) |> json(%{payment: payment_json(payment)})
    end
  end

  defp payment_json(payment) do
    %{
      id: payment.id,
      method: payment.method,
      amount_tiyn: payment.amount_tiyn,
      status: payment.status,
      inserted_at: payment.inserted_at
    }
  end
end
