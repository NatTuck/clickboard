defmodule Clickboard.Clicks.Click do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clicks" do
    belongs_to :user, Clickboard.Users.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(click, attrs, user_scope) do
    click
    |> cast(attrs, [:user_id])
    |> put_change(:user_id, user_scope.user.id)
    |> validate_required([:user_id])
  end
end
