defmodule ClickboardWeb.UserRegistrationController do
  use ClickboardWeb, :controller

  alias Clickboard.Users
  alias ClickboardWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    case Users.get_or_create_user_by_email(user_params["email"]) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome!")
        |> UserAuth.log_in_user(user, user_params)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Please enter an email address.")
        |> redirect(to: ~p"/users/register")
    end
  end
end
