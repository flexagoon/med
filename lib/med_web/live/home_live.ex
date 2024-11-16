defmodule MedWeb.HomeLive do
  use MedWeb, :live_view

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

  def mount(_params, _session, socket) do
    {:ok, assign(socket, med: "")}
  end

  def handle_event("check", %{"med" => med}, socket) do
    med = String.trim(med)

    case med do
      "" ->
        {:noreply, put_flash(socket, :error, "Med name is required")}

      _ ->
        {:noreply, push_navigate(socket, to: ~p"/check?med=#{med}")}
    end
  end
end
