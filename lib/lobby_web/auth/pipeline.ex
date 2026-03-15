defmodule LobbyWeb.Auth.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :lobby,
    module: Lobby.Guardian,
    error_handler: LobbyWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
