defmodule Clickboard.ClicksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Clickboard.Clicks` context.
  """

  @doc """
  Generate a click.
  """
  def click_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        user_id: 42
      })

    {:ok, click} = Clickboard.Clicks.create_click(scope, attrs)
    click
  end
end
