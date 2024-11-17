defmodule MedWeb.CheckLive do
  use MedWeb, :live_view

  def render(assigns = %{loading: true}) do
    ~H"""
    <h1>loading</h1>
    """
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl font-bold"><%= @drug %></h1>
    <ul class="list-disc">
      <li><b>Active ingredient:</b> <%= @active_ingredient %></li>
      <li><b>FDA approved:</b> <%= @fda_approved %></li>
      <li><b>Homeopathy:</b> <%= @homeopathy %></li>
      <li><b>Research score:</b> <%= @score %></li>
    </ul>
    <ol class="list-decimal">
      <%= for research <- @research do %>
        <li><%= research %></li>
      <% end %>
    </ol>
    """
  end

  def mount(params, _session, socket) do
    if connected?(socket), do: send(self(), :check)
    {:ok, assign(socket, drug: params["med"], loading: true)}
  end

  def handle_info(:check, socket) do
    {drug, score} = Med.check(socket.assigns.drug)

    {:noreply,
     assign(socket,
       loading: false,
       active_ingredient: drug.active_ingredient,
       homeopathy: drug.homeopathy,
       fda_approved: drug.fda_approved,
       research: drug.research,
       score: score
     )}
  end
end
