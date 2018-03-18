defmodule WhiteboardWeb.WhiteboardChannel do
  use WhiteboardWeb, :channel
  alias WhiteboardWeb.Presence

  def join("whiteboard:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      random_number = :rand.uniform(1000)
      user = %{
        id: random_number, 
        color: "", 
        name: ""
      }

      {:ok, socket |> assign(:user, user) }
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} = Presence.track(socket, socket.assigns.user.id, %{
      online_at: inspect(System.system_time(:seconds)),
      name: "",
      color: ""
    })
    {:noreply, socket}
  end

  def handle_in("update_user", %{"color" => color}, socket) do
    new_user = Map.merge(socket.assigns.user, %{color: color})
    Presence.update(socket, socket.assigns.user.id, new_user)
    {:noreply, socket |> assign(:user, new_user)}
  end

  def handle_in("update_user", %{"name" => name}, socket) do
    new_user = Map.merge(socket.assigns.user, %{name: name})
    Presence.update(socket, socket.assigns.user.id, new_user)
    {:noreply, socket |> assign(:user, new_user)}
  end

  def handle_in("draw", data, socket) do
    WhiteboardWeb.Endpoint.broadcast_from! self(), "whiteboard:lobby", "external_draw", %{data: data}
    {:noreply, socket} 
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
