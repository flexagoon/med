defmodule MedWeb.CheckLive do
  use MedWeb, :live_view

  @impl Phoenix.LiveView
  def render(%{loading: true} = assigns) do
    ~H"""
    <p class="text-7xl font-black text-accent animate-pulse text-center">♥?</p>
    """
  end

  @impl Phoenix.LiveView
  def render(%{drug: nil} = assigns) do
    ~H"""
    <div class="text-bg bg-red-500 w-fit p-3 rounded-xl">
      <h2 class="text-3xl sm:text-4xl font-bold pb-3">
        Препарат не найден <.icon name="hero-exclamation-triangle-solid" class="w-10 h-10" />
      </h2>
      <p class="text-lg sm:text-xl pb-3">
        В Государственном Реестре Лекарственных Средств не найдено информации о данном препарате. Убедитесь, что вы
        верно ввели его название, и что препарат продаётся на территории России.
      </p>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def render(%{drug: %{homeopathy: true}} = assigns) do
    ~H"""
    <div class="text-bg bg-red-500 w-fit p-3 rounded-xl">
      <h2 class="text-3xl sm:text-4xl font-bold pb-3">
        Гомеопатическое вещество <.icon name="hero-exclamation-triangle-solid" class="w-10 h-10" />
      </h2>
      <p class="text-lg sm:text-xl pb-3">
        Данное средство является гомеопатией. Принципы гомеопатии противоречат фундаментальным законам науки,
        а эффективность гомеопатических средств не была подтверждена ни одним достоверным исследованием.
      </p>
      <p class="text-lg sm:text-xl">
        Мы не рекомендуем использование данного средства для лечения любых заболеваний.
      </p>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def render(%{drug: %{active_ingredient: nil}} = assigns) do
    ~H"""
    <div class="text-bg bg-yellow-500 w-fit p-3 rounded-xl">
      <h2 class="text-4xl font-bold pb-3">
        Нет активного вещества <.icon name="hero-exclamation-triangle-solid" class="w-10 h-10" />
      </h2>
      <p class="text-xl pb-3">
        В Государственном Реестре Лекарственных Средств не найдена информация об активном веществе данного
        препарата.
      </p>
      <p class="text-xl pb-3">
        Это не обязательно указывает на ненадежность препарата — активный ингредиент также отсутствует у некоторых
        групп лекарств, например, лекарств растительного происхождения или комбинированных средств.
      </p>
      <p class="text-xl">
        Однако, в связи с отсутствием информации, med? не может оценить надежность лекарства.
      </p>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="text-2xl sm:text-3xl">
      <h2 class="text-accent font-bold">Активный ингредиент:</h2>
      <p class="w-fit p-3 m-3 border-l-4">{@drug.active_ingredient}</p>

      <h2 class="text-accent font-bold mt-10">Оценка изученности:</h2>
      <p class="w-fit p-3 m-3 border-l-4">
        {@drug.research_score} / 100 {cond do
          @drug.research_score < 40 -> "📄"
          @drug.research_score < 80 -> "📝"
          true -> "📑"
        end}
      </p>
      <p class="text-xl sm:text-2xl">На основе следующих факторов:</p>
      <ul class="list-disc pl-10 text-xl sm:text-2xl">
        <li :if={@drug.fda_approved}>Одобрен FDA</li>

        <%= if @drug.cochrane > 0 do %>
          <%= if @drug.cochrane >= 100 do %>
            <li><b class="text-accent">&gt; 100</b> Статей в Cochrane</li>
          <% else %>
            <li>Статей в Cochrane: <b class="text-accent">{@drug.cochrane}</b></li>
          <% end %>
        <% end %>

        <%= if @drug.pubmed > 0 do %>
          <%= if @drug.pubmed >= 100 do %>
            <li><b class="text-accent">&gt; 100</b> Статей в PubMed</li>
          <% else %>
            <li>Статей в PubMed: <b class="text-accent">{@drug.pubmed}</b></li>
          <% end %>
        <% end %>
      </ul>
      <p class="text-lg sm:text-xl pt-3 text-fg/80">
        Обратите внимание: эта оценка указывает на количество существующих исследований, но не на их результат.
        Для получения краткой сводки исследований используйте ИИ-анализ ниже.
      </p>

      <h2 class="text-accent font-bold mt-10">ИИ-анализ:</h2>
      <%= if @drug.summary == "" do %>
        <p class="text-lg sm:text-xl pt-3 animate-pulse">Генерация анализа...</p>
      <% else %>
        <p class="text-lg sm:text-xl pt-3 whitespace-pre-line">{@drug.summary}</p>
      <% end %>
    </div>
    <hr class="my-5" />
    <p class="text-fg/50">
      Данные предоставлены в ознакомительных целях и могут быть неточными. Не является медицинской рекомендацией.
      Информация взята из открытых источников, администрация сайта не несёт за неё ответственности.
    </p>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    if connected?(socket), do: send(self(), :check)

    name = String.downcase(params["med"])

    {:ok, assign(socket, name: name, loading: true, page_title: name <> "...")}
  end

  @impl Phoenix.LiveView
  def handle_info(:check, socket) do
    drug = Med.check(socket.assigns.name, self())

    {:noreply,
     assign(socket,
       loading: false,
       drug: drug,
       page_title: socket.assigns.name <> "!"
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(%LangChain.MessageDelta{content: text, role: :assistant}, socket) do
    drug = socket.assigns.drug
    summary = drug.summary <> text
    {:noreply, assign(socket, drug: %{drug | summary: summary})}
  end
end
