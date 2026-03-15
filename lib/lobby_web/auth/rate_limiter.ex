defmodule LobbyWeb.Auth.RateLimiter do
  @moduledoc """
  Simple ETS-based rate limiter for auth endpoints.
  Limits requests per IP to prevent brute-force attacks.
  """
  import Plug.Conn

  @max_requests 10
  @window_ms 60_000

  def init(opts), do: opts

  def call(conn, _opts) do
    ensure_table()
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    key = "#{ip}:#{conn.request_path}"
    now = System.monotonic_time(:millisecond)

    case check_rate(key, now) do
      :ok ->
        conn

      :rate_limited ->
        conn
        |> put_status(429)
        |> Phoenix.Controller.json(%{error: "Too many requests. Try again later."})
        |> halt()
    end
  end

  defp ensure_table do
    if :ets.whereis(:rate_limiter) == :undefined do
      :ets.new(:rate_limiter, [:named_table, :public, :set])
    end
  end

  defp check_rate(key, now) do
    case :ets.lookup(:rate_limiter, key) do
      [{^key, count, window_start}] when now - window_start < @window_ms ->
        if count >= @max_requests do
          :rate_limited
        else
          :ets.update_element(:rate_limiter, key, {2, count + 1})
          :ok
        end

      _ ->
        :ets.insert(:rate_limiter, {key, 1, now})
        :ok
    end
  end
end
