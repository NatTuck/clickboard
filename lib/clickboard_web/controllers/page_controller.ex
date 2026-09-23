defmodule ClickboardWeb.PageController do
  use ClickboardWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
