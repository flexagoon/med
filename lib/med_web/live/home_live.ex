defmodule MedWeb.HomeLive do
  use MedWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <form phx-submit="check">
      <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
      <label class="font-bold text-4xl" for="med">Название лекарства:</label>
      <div class="inline-flex w-full my-5 group">
        <input
          class="
            text-4xl
            border-4 border-fg border-r-0 outline-none group-hover:border-accent focus:border-accent
            rounded-full rounded-r-none
            px-7 py-1
            flex-auto
            peer"
          name="med"
        />
        <button class="bg-fg rounded-full rounded-l-none p-3 pr-20 text-4xl text-bg font-bold peer-focus:bg-accent group-hover:bg-accent">
          ?
        </button>
      </div>
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
