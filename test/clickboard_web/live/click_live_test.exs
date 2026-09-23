defmodule ClickboardWeb.ClickLiveTest do
  use ClickboardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Clickboard.UsersFixtures
  import Clickboard.ClicksFixtures

  alias Clickboard.Clicks
  alias Clickboard.Users.Scope

  describe "click page" do
    test "renders the button and leaderboard for a logged-in user", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/click")

      assert has_element?(lv, "#click-button", "Click Me!")
      assert has_element?(lv, "#leaderboard")
      assert has_element?(lv, "#my-score", "0")
    end

    test "redirects to log in when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: path, flash: flash}}} = live(conn, ~p"/click")

      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "clicking" do
    test "creates a click and increments the score", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/click")

      lv |> element("#click-button") |> render_click()
      assert has_element?(lv, "#my-score", "1")

      lv |> element("#click-button") |> render_click()
      assert has_element?(lv, "#my-score", "2")

      assert Clicks.count_clicks(Scope.for_user(user)) == 2
    end

    test "adds the clicker to the leaderboard", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/click")

      refute has_element?(lv, "#leaderboard li", user.email)

      lv |> element("#click-button") |> render_click()
      _ = :sys.get_state(lv.pid)

      assert has_element?(lv, "#leaderboard li", user.email)
      assert has_element?(lv, "#leaderboard li", "(you)")
    end
  end

  describe "leaderboard" do
    test "ranks users by click count", %{conn: conn} do
      leader = user_fixture()
      me = user_fixture()

      for _ <- 1..3, do: click_fixture(Scope.for_user(leader))
      click_fixture(Scope.for_user(me))

      {:ok, lv, _html} = conn |> log_in_user(me) |> live(~p"/click")

      assert has_element?(lv, "#leaderboard li", leader.email)
      assert has_element?(lv, "#leaderboard li", me.email)

      rows =
        lv
        |> render()
        |> LazyHTML.from_fragment()
        |> LazyHTML.query("#leaderboard li:not(#leaderboard-empty)")
        |> Enum.map(&LazyHTML.text/1)

      assert [leader_row, me_row | _] = rows
      assert leader_row =~ leader.email
      assert me_row =~ me.email
    end

    test "updates in realtime for other connected users", %{conn: conn} do
      clicker = user_fixture()
      watcher = user_fixture()

      {:ok, watcher_lv, _html} = conn |> log_in_user(watcher) |> live(~p"/click")

      {:ok, clicker_lv, _html} = conn |> log_in_user(clicker) |> live(~p"/click")

      refute has_element?(watcher_lv, "#leaderboard li", clicker.email)

      clicker_lv |> element("#click-button") |> render_click()
      _ = :sys.get_state(watcher_lv.pid)

      assert has_element?(watcher_lv, "#leaderboard li", clicker.email)
    end
  end
end
