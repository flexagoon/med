defmodule MedWeb.CheckLive do
  use MedWeb, :live_view

  @impl Phoenix.LiveView
  def render(%{loading: true} = assigns) do
    ~H"""
    <h1>loading</h1>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="text-2xl font-bold"><%= @name %></h1>
    <ul class="list-disc">
      <li><b>Active ingredient:</b> <%= @drug.active_ingredient %></li>
      <li><b>FDA approved:</b> <%= @drug.fda_approved %></li>
      <li><b>Homeopathy:</b> <%= @drug.homeopathy %></li>
      <li><b>Research score:</b> <%= @drug.research_score %></li>
    </ul>
    <p><%= @summary %></p>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    if connected?(socket), do: send(self(), :check)
    {:ok, assign(socket, name: params["med"], loading: true)}
  end

  @impl Phoenix.LiveView
  def handle_info(:check, socket) do
    drug = Med.check(socket.assigns.name, self())

    {:noreply,
     assign(socket,
       loading: false,
       drug: drug,
       summary: ""
     )}
  end

  @impl Phoenix.LiveView
  def handle_info({pid, {:data, data}}, socket) when is_pid(pid) do
    old_summary = socket.assigns.summary

    summary =
      case data do
        %{"type" => "message_start"} ->
          ""

        %{
          "type" => "content_block_start",
          "content_block" => %{"text" => text}
        } ->
          text

        %{
          "type" => "content_block_delta",
          "delta" => %{"text" => text}
        } ->
          old_summary <> text

        _msg ->
          old_summary
      end

    {:noreply, assign(socket, summary: summary)}
  end

  @impl Phoenix.LiveView
  def handle_info(_msg, socket), do: {:noreply, socket}
end
