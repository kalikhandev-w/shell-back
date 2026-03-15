defmodule Lobby.Gaming.Session do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "sessions" do
    field :status, :string, default: "active"
    field :duration_minutes, :integer
    field :total_price_tiyn, :integer, default: 0
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime

    belongs_to :user, Lobby.Accounts.User
    belongs_to :pc, Lobby.Clubs.PC
    belongs_to :tariff, Lobby.Clubs.Tariff
    belongs_to :club, Lobby.Clubs.Club

    field :paused_at, :utc_datetime
    field :total_pause_seconds, :integer, default: 0
    field :payment_method, :string, default: "balance"
    field :payment_source, :string, default: "self_service"
    field :notes, :string
    field :package_id, :binary_id

    has_many :orders, Lobby.Pos.Order
    has_many :payments, Lobby.Billing.Payment

    belongs_to :shift, Lobby.Shifts.Shift

    timestamps(type: :utc_datetime)
  end

  def create_changeset(session, attrs) do
    session
    |> cast(attrs, [:duration_minutes, :total_price_tiyn, :user_id, :pc_id, :tariff_id,
                     :club_id, :shift_id, :payment_method, :payment_source, :package_id, :notes])
    |> validate_required([:duration_minutes, :user_id, :pc_id, :tariff_id, :club_id])
    |> validate_number(:duration_minutes, greater_than: 0)
    |> put_change(:started_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> put_change(:status, "active")
  end

  def end_changeset(session) do
    session
    |> change(status: "ended", ended_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def extend_changeset(session, extra_minutes) do
    session
    |> change(duration_minutes: session.duration_minutes + extra_minutes)
  end

  def pause_changeset(session) do
    session
    |> change(status: "paused", paused_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def resume_changeset(session) do
    pause_duration =
      if session.paused_at do
        DateTime.diff(DateTime.utc_now(), session.paused_at, :second)
      else
        0
      end

    session
    |> change(
      status: "active",
      paused_at: nil,
      total_pause_seconds: (session.total_pause_seconds || 0) + pause_duration
    )
  end

  def move_changeset(session, new_pc_id) do
    session
    |> change(pc_id: new_pc_id)
  end

  def add_time_changeset(session, minutes, note) do
    session
    |> change(
      duration_minutes: session.duration_minutes + minutes,
      notes: note
    )
  end
end
