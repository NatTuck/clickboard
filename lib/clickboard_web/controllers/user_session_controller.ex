defmodule ClickboardWeb.UserSessionController do
  use ClickboardWeb, :controller

  alias Clickboard.Users
  alias ClickboardWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    case Users.get_or_create_user_by_email(user_params["email"]) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> UserAuth.log_in_user(user, user_params)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Please enter an email address.")
        |> put_flash(:email, "")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def update_password(conn, %{"user" => user_params}) do
    user = conn.assigns.current_scope.user
    true = Users.sudo_mode?(user)
    {:ok, {user, expired_tokens}} = Users.update_user_password(user, user_params)

    # disconnect all existing LiveViews with old sessions
    UserAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_flash(:info, "Password updated successfully!")
    |> put_session(:user_return_to, ~p"/users/settings")
    |> UserAuth.log_in_user(user, user_params)
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
