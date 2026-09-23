defmodule ClickboardWeb.ClickLive do
  use ClickboardWeb, :live_view

  alias Clickboard.Clicks

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Clicks.subscribe_to_leaderboard()

    scope = socket.assigns.current_scope

    socket =
      socket
      |> assign(:page_title, "Clickboard")
      |> assign(:current_user_id, scope.user.id)
      |> assign(:current_count, Clicks.count_clicks(scope))
      |> stream_leaderboard()

    {:ok, socket}
  end

  @impl true
  def handle_event("click", _params, socket) do
    case Clicks.create_click(socket.assigns.current_scope, %{}) do
      {:ok, _click} ->
        {:noreply, update(socket, :current_count, &(&1 + 1))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not record that click. Try again.")}
    end
  end

  @impl true
  def handle_info({:click_created, _click}, socket) do
    {:noreply,
     socket
     |> assign(:current_count, Clicks.count_clicks(socket.assigns.current_scope))
     |> stream_leaderboard()}
  end

  defp stream_leaderboard(socket) do
    entries =
      Clicks.leaderboard()
      |> Enum.with_index(1)
      |> Enum.map(fn {entry, rank} ->
        %{id: entry.user_id, rank: rank, email: entry.email, count: entry.count}
      end)

    stream(socket, :leaderboard, entries, reset: true)
  end
end
