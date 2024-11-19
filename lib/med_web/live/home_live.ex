defmodule MedWeb.HomeLive do
  use MedWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <form phx-submit="check" class="flex flex-col">
      <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
      <label>
        Med name: <input class="border-black border-2" name="med" />
      </label>
      <button>Check</button>
    </form>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, med: "")}
  end

  @impl Phoenix.LiveView
  def handle_event("check", %{"med" => med}, socket) do
    med = String.trim(med)

    case med do
      "" ->
        {:noreply, put_flash(socket, :error, "Med name is required")}

      med ->
        {:noreply, push_navigate(socket, to: ~p"/check?med=#{med}")}
    end
  end
end
