defmodule ClickboardWeb.UserSessionControllerTest do
  use ClickboardWeb.ConnCase

  import Clickboard.UsersFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /users/log-in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => "anything"}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ user.email
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/users/log-out"
    end

    test "creates an account for an unknown email", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => email, "password" => "anything"}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Clickboard.Users.get_user_by_email(email)
    end

    test "logs the user in without a password", %{conn: conn, user: user} do
      conn = post(conn, ~p"/users/log-in", %{"user" => %{"email" => user.email}})

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "remember_me" => "true"}
        })

      assert conn.resp_cookies["_clickboard_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/users/log-in", %{"user" => %{"email" => user.email}})

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "redirects to login page with a blank email", %{conn: conn} do
      conn = post(conn, ~p"/users/log-in", %{"user" => %{"email" => ""}})

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Please enter an email address."
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "POST /users/register" do
    test "logs the new user in", %{conn: conn} do
      email = unique_user_email()

      conn = post(conn, ~p"/users/register", %{"user" => %{"email" => email}})

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Clickboard.Users.get_user_by_email(email)
    end

    test "logs an existing user in instead of failing", %{conn: conn, user: user} do
      conn = post(conn, ~p"/users/register", %{"user" => %{"email" => user.email}})

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "DELETE /users/log-out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
