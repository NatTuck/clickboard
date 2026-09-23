defmodule Clickboard.ClicksTest do
  use Clickboard.DataCase

  alias Clickboard.Clicks

  describe "clicks" do
    alias Clickboard.Clicks.Click

    import Clickboard.UsersFixtures, only: [user_scope_fixture: 0]
    import Clickboard.ClicksFixtures

    test "list_clicks/1 returns all scoped clicks" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      click = click_fixture(scope)
      other_click = click_fixture(other_scope)
      assert Clicks.list_clicks(scope) == [click]
      assert Clicks.list_clicks(other_scope) == [other_click]
    end

    test "get_click!/2 returns the click with given id" do
      scope = user_scope_fixture()
      click = click_fixture(scope)
      other_scope = user_scope_fixture()
      assert Clicks.get_click!(scope, click.id) == click
      assert_raise Ecto.NoResultsError, fn -> Clicks.get_click!(other_scope, click.id) end
    end

    test "create_click/2 creates a click owned by the scope's user" do
      scope = user_scope_fixture()

      assert {:ok, %Click{} = click} = Clicks.create_click(scope, %{})
      assert click.user_id == scope.user.id
    end

    test "create_click/2 enforces the scope's user over supplied attrs" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()

      assert {:ok, %Click{} = click} = Clicks.create_click(scope, %{user_id: other_scope.user.id})
      assert click.user_id == scope.user.id
    end

    test "update_click/3 keeps the click owned by the scope's user" do
      scope = user_scope_fixture()
      click = click_fixture(scope)

      assert {:ok, %Click{} = click} = Clicks.update_click(scope, click, %{})
      assert click.user_id == scope.user.id
    end

    test "update_click/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      click = click_fixture(scope)

      assert_raise MatchError, fn ->
        Clicks.update_click(other_scope, click, %{})
      end
    end

    test "update_click/3 enforces the scope's user over supplied attrs" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      click = click_fixture(scope)

      assert {:ok, %Click{} = click} =
               Clicks.update_click(scope, click, %{user_id: other_scope.user.id})

      assert click.user_id == scope.user.id
    end

    test "delete_click/2 deletes the click" do
      scope = user_scope_fixture()
      click = click_fixture(scope)
      assert {:ok, %Click{}} = Clicks.delete_click(scope, click)
      assert_raise Ecto.NoResultsError, fn -> Clicks.get_click!(scope, click.id) end
    end

    test "delete_click/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      click = click_fixture(scope)
      assert_raise MatchError, fn -> Clicks.delete_click(other_scope, click) end
    end

    test "change_click/2 returns a click changeset" do
      scope = user_scope_fixture()
      click = click_fixture(scope)
      assert %Ecto.Changeset{} = Clicks.change_click(scope, click)
    end
  end

  describe "leaderboard" do
    alias Clickboard.Clicks.Click

    import Clickboard.UsersFixtures, only: [user_scope_fixture: 0]
    import Clickboard.ClicksFixtures

    test "count_clicks/1 counts only the scope's clicks" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      click_fixture(scope)
      click_fixture(scope)
      click_fixture(other_scope)

      assert Clicks.count_clicks(scope) == 2
      assert Clicks.count_clicks(other_scope) == 1
    end

    test "count_clicks/1 is zero with no clicks" do
      assert Clicks.count_clicks(user_scope_fixture()) == 0
    end

    test "leaderboard/1 orders users by click count" do
      top = user_scope_fixture()
      runner_up = user_scope_fixture()
      _no_clicks = user_scope_fixture()

      for _ <- 1..3, do: click_fixture(top)
      for _ <- 1..2, do: click_fixture(runner_up)

      assert [%{user_id: top_id, count: 3}, %{user_id: runner_id, count: 2}] =
               Clicks.leaderboard(2)

      assert top_id == top.user.id
      assert runner_id == runner_up.user.id
    end

    test "leaderboard/1 excludes users without clicks" do
      scope = user_scope_fixture()
      _other = user_scope_fixture()
      click_fixture(scope)

      assert [%{user_id: user_id, count: 1}] = Clicks.leaderboard()
      assert user_id == scope.user.id
    end

    test "subscribe_to_leaderboard/0 delivers created clicks" do
      scope = user_scope_fixture()
      Clicks.subscribe_to_leaderboard()

      click = click_fixture(scope)

      assert_receive {:click_created, %Click{id: id}}
      assert id == click.id
    end
  end
end
