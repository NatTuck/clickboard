defmodule Clickboard.Clicks do
  @moduledoc """
  The Clicks context.
  """

  import Ecto.Query, warn: false
  alias Clickboard.Repo

  alias Clickboard.Clicks.Click
  alias Clickboard.Users.Scope

  @leaderboard_topic "clicks:leaderboard"

  @doc """
  Subscribes the caller to global leaderboard notifications.

  Broadcasted messages match the pattern:

    * {:click_created, %Click{}}

  """
  def subscribe_to_leaderboard do
    Phoenix.PubSub.subscribe(Clickboard.PubSub, @leaderboard_topic)
  end

  defp broadcast_leaderboard(message) do
    Phoenix.PubSub.broadcast(Clickboard.PubSub, @leaderboard_topic, message)
  end

  @doc """
  Subscribes to scoped notifications about any click changes.

  The broadcasted messages match the pattern:

    * {:created, %Click{}}
    * {:updated, %Click{}}
    * {:deleted, %Click{}}

  """
  def subscribe_clicks(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Clickboard.PubSub, "user:#{key}:clicks")
  end

  defp broadcast_click(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Clickboard.PubSub, "user:#{key}:clicks", message)
  end

  @doc """
  Returns the list of clicks.

  ## Examples

      iex> list_clicks(scope)
      [%Click{}, ...]

  """
  def list_clicks(%Scope{} = scope) do
    Repo.all_by(Click, user_id: scope.user.id)
  end

  @doc """
  Returns the number of clicks belonging to the scope's user.

  ## Examples

      iex> count_clicks(scope)
      42

  """
  def count_clicks(%Scope{} = scope) do
    Repo.one(
      from c in Click,
        where: c.user_id == ^scope.user.id,
        select: count(c.id)
    )
  end

  @doc """
  Returns the top `limit` users ordered by their click count.

  Each entry is a map with the user's `:user_id`, `:email`, and `:count`.

  ## Examples

      iex> leaderboard()
      [%{user_id: 1, email: "user@example.com", count: 5}, ...]

  """
  def leaderboard(limit \\ 10) do
    from(c in Click,
      join: u in assoc(c, :user),
      group_by: [u.id, u.email],
      select: %{user_id: u.id, email: u.email, count: count(c.id)},
      order_by: [desc: count(c.id), asc: u.email],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets a single click.

  Raises `Ecto.NoResultsError` if the Click does not exist.

  ## Examples

      iex> get_click!(scope, 123)
      %Click{}

      iex> get_click!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_click!(%Scope{} = scope, id) do
    Repo.get_by!(Click, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a click.

  ## Examples

      iex> create_click(scope, %{field: value})
      {:ok, %Click{}}

      iex> create_click(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_click(%Scope{} = scope, attrs) do
    with {:ok, click = %Click{}} <-
           %Click{}
           |> Click.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_click(scope, {:created, click})
      broadcast_leaderboard({:click_created, click})
      {:ok, click}
    end
  end

  @doc """
  Updates a click.

  ## Examples

      iex> update_click(scope, click, %{field: new_value})
      {:ok, %Click{}}

      iex> update_click(scope, click, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_click(%Scope{} = scope, %Click{} = click, attrs) do
    true = click.user_id == scope.user.id

    with {:ok, click = %Click{}} <-
           click
           |> Click.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_click(scope, {:updated, click})
      {:ok, click}
    end
  end

  @doc """
  Deletes a click.

  ## Examples

      iex> delete_click(scope, click)
      {:ok, %Click{}}

      iex> delete_click(scope, click)
      {:error, %Ecto.Changeset{}}

  """
  def delete_click(%Scope{} = scope, %Click{} = click) do
    true = click.user_id == scope.user.id

    with {:ok, click = %Click{}} <-
           Repo.delete(click) do
      broadcast_click(scope, {:deleted, click})
      {:ok, click}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking click changes.

  ## Examples

      iex> change_click(scope, click)
      %Ecto.Changeset{data: %Click{}}

  """
  def change_click(%Scope{} = scope, %Click{} = click, attrs \\ %{}) do
    true = click.user_id == scope.user.id

    Click.changeset(click, attrs, scope)
  end
end
