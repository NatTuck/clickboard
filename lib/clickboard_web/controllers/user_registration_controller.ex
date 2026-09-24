defmodule ClickboardWeb.UserRegistrationController do
  use ClickboardWeb, :controller

  alias Clickboard.Users
  alias ClickboardWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    case Users.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Account created successfully.")
        |> UserAuth.log_in_user(user, user_params)

      {:error, %Ecto.Changeset{}} ->
        conn
        |> put_flash(:error, "Could not create account.")
        |> redirect(to: ~p"/users/register")
    end
  end
end
