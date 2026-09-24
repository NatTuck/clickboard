defmodule ClickboardWeb.UserLive.LoginTest do
  use ClickboardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Clickboard.UsersFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Log in"
      assert html =~ "Sign up"
    end
  end

  describe "user login" do
    test "logs in an existing user", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form = form(lv, "#login_form", user: %{email: user.email})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "creates and logs in an unknown user", %{conn: conn} do
      email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form = form(lv, "#login_form", user: %{email: email})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
      assert Clickboard.Users.get_user_by_email(email)
    end

    test "redirects to login page with a flash error for a blank email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form = form(lv, "#login_form", user: %{email: ""})

      render_submit(form)

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Please enter an email address."
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Sign up")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/register")

      assert login_html =~ "Register"
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      user = user_fixture()
      %{user: user, conn: log_in_user(conn, user)}
    end

    test "shows login page with email filled in", %{conn: conn, user: user} do
      {:ok, lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "You need to reauthenticate"
      refute html =~ "Register"
      assert has_element?(lv, "#user_email")
      assert render(element(lv, "#user_email")) =~ ~s(value="#{user.email}")
    end
  end
end
