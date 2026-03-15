defmodule Lobby.AccountsTest do
  use Lobby.DataCase, async: true

  alias Lobby.Accounts
  import Lobby.Fixtures

  setup do
    club = create_club()
    %{club: club}
  end

  describe "register/1" do
    test "creates user with valid attrs", %{club: club} do
      attrs = %{email: "new@test.com", password: "secret123", username: "newuser", club_id: club.id}
      assert {:ok, user} = Accounts.register(attrs)
      assert user.email == "new@test.com"
      assert user.username == "newuser"
      assert user.password_hash != nil
    end

    test "fails with short password", %{club: club} do
      attrs = %{email: "new@test.com", password: "short", club_id: club.id}
      assert {:error, changeset} = Accounts.register(attrs)
      assert %{password: _} = errors_on(changeset)
    end

    test "fails with duplicate email", %{club: club} do
      attrs = %{email: "dup@test.com", password: "secret123", club_id: club.id}
      assert {:ok, _} = Accounts.register(attrs)
      assert {:error, changeset} = Accounts.register(attrs)
      assert %{email: _} = errors_on(changeset)
    end
  end

  describe "authenticate/2" do
    test "succeeds with correct credentials", %{club: club} do
      create_user(club, %{email: "auth@test.com", password: "secret123"})
      assert {:ok, user} = Accounts.authenticate("auth@test.com", "secret123")
      assert user.email == "auth@test.com"
    end

    test "fails with wrong password", %{club: club} do
      create_user(club, %{email: "auth2@test.com", password: "secret123"})
      assert {:error, :invalid_password} = Accounts.authenticate("auth2@test.com", "wrong")
    end

    test "fails with unknown email" do
      assert {:error, :not_found} = Accounts.authenticate("unknown@test.com", "secret123")
    end
  end

  describe "create_guest/1" do
    test "creates guest user", %{club: club} do
      assert {:ok, guest} = Accounts.create_guest(%{club_id: club.id})
      assert guest.is_guest == true
      assert guest.username =~ "Guest-"
    end
  end

  describe "balance operations" do
    test "add_balance increases balance", %{club: club} do
      user = create_user(club)
      assert {:ok, updated} = Accounts.add_balance(user, 100_000)
      assert updated.balance_tiyn == 100_000
    end

    test "deduct_balance decreases balance", %{club: club} do
      user = create_user(club)
      {:ok, user} = Accounts.add_balance(user, 200_000)
      assert {:ok, updated} = Accounts.deduct_balance(user, 50_000)
      assert updated.balance_tiyn == 150_000
    end

    test "deduct_balance fails if insufficient", %{club: club} do
      user = create_user(club)
      assert {:error, _} = Accounts.deduct_balance(user, 50_000)
    end
  end

  describe "update_user/2" do
    test "updates user fields", %{club: club} do
      user = create_user(club)
      assert {:ok, updated} = Accounts.update_user(user, %{username: "newname"})
      assert updated.username == "newname"
    end

    test "can ban user", %{club: club} do
      user = create_user(club)
      assert {:ok, banned} = Accounts.update_user(user, %{is_banned: true, ban_reason: "cheating"})
      assert banned.is_banned == true
      assert banned.ban_reason == "cheating"
    end
  end

  describe "list_users/1" do
    test "returns users for club", %{club: club} do
      create_user(club)
      create_user(club)
      users = Accounts.list_users(club.id)
      assert length(users) == 2
    end
  end
end
