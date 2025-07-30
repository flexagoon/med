defmodule MedWeb.HomeLive do
  use MedWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
    <form phx-submit="check">
      <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
      <label class="font-bold text-3xl md:text-4xl" for="med">Название лекарства:</label>
      <div class="inline-flex w-full my-5 group">
        <input
          class="
            text-3xl md:text-4xl
            bg-white
            border-4 border-base-content border-r-0 outline-none group-hover:border-primary focus:border-primary
            rounded-full rounded-r-none
            px-7 py-1
            flex-auto
            min-w-0
            peer"
          name="med"
        />
        <button class="bg-base-content rounded-full rounded-l-none p-3 pr-16 text-3xl md:text-4xl text-base-100 font-bold peer-focus:bg-primary group-hover:bg-primary min-w-0">
          ♥?
        </button>
      </div>
    </form>
    <p class="mt-16">
      Российские медицинские практики сильно отстают от международных.
      Тогда как во многих странах врачи обязаны регулярно обновлять свою лицензию,
      а для выпуска лекарств требуется наличие достоверных клинических испытаний,
      многие Российские врачи используют устаревшие советские практики и свободно
      выписывают лекарства с нулевой доказательной базой.
    </p>
    <p class="mt-2">
      <span class="text-primary font-bold">med?</span>
      − это инструмент, который помогает вам оценить надежность лекарств.
      Он автоматически получает информацию о препарате и анализирует её при помощи
      нейросети.
    </p>
    <p class="mt-2">
      Этот сайт может быть использован для получения общего представления о достоверности
      препарата, но важно понимать, что полученные результаты могут быть неточыми.
      Он не должен использоваться как основной источник медицинской информации
      или замена консультации квалифицированного врача.
    </p>
    <p class="mt-2">
      Исходный код этого сайта полностью открыт. Вы можете проверить его и
      предложить свою улучшения в <a
        class="underline hover:text-primary"
        href="https://github.com/flexagoon/med"
      >репозитории на GitHub</a>.
    </p>
    </Layouts.app>
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
        {:noreply, put_flash(socket, :error, "Вы не ввели название лекарства!")}

      med ->
        {:noreply, push_navigate(socket, to: ~p"/check?med=#{med}")}
    end
  end
end
