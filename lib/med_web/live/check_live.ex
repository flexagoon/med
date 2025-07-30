defmodule MedWeb.CheckLive do
  use MedWeb, :live_view

  alias MedWeb.CheckResults

  @impl Phoenix.LiveView
  def render(%{loading: true} = assigns) do
    ~H"""
    <p class="text-7xl font-black text-accent animate-pulse text-center">♥?</p>
    """
  end

  @impl Phoenix.LiveView
  def render(%{drug: nil} = assigns) do
    ~H"""
    <CheckResults.warning title="Препарат не найден">
      В Государственном Реестре Лекарственных Средств не найдено информации о данном препарате. Убедитесь, что вы верно ввели его название, и что препарат продаётся на территории России.
    </CheckResults.warning>
    """
  end

  @impl Phoenix.LiveView
  def render(%{drug: %{type: :homeopathy}} = assigns) do
    ~H"""
    <CheckResults.warning title="Гомеопатическое вещество">
      Данное средство является гомеопатией. Принципы гомеопатии противоречат фундаментальным законам науки, а эффективность гомеопатических средств не была подтверждена ни одним достоверным исследованием.
      <strong>Мы не рекомендуем использование данного средства для лечения любых заболеваний.</strong>
    </CheckResults.warning>
    """
  end

  @impl Phoenix.LiveView
  def render(%{drug: %{type: :supplement}} = assigns) do
    ~H"""
    <CheckResults.warning title="Биологическая добавка">
      Данное средство является биологически активной добавкой. В отличии от лекарств, БАДы практически не регулируются и не имеют большой доказательной базы. Они могут оказывать влияние на организм, но гарантировать их эффективность, как и безопасность, невозможно.
    </CheckResults.warning>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns), do: CheckResults.results(assigns)

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    if connected?(socket), do: send(self(), :check)

    name = String.downcase(params["med"])

    {:ok, assign(socket, name: name, loading: true, page_title: name <> "...")}
  end

  @impl Phoenix.LiveView
  def handle_info(:check, socket) do
    drug = Med.check(socket.assigns.name, self())

    name =
      case drug do
        nil -> socket.assigns.name
        %Med.Drug{name: name} -> String.downcase(name)
      end

    {:noreply,
     assign(socket,
       loading: false,
       drug: drug,
       page_title: name <> "!"
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(%LangChain.MessageDelta{content: text, role: :assistant}, socket) do
    drug = socket.assigns.drug
    summary = drug.summary <> text
    {:noreply, assign(socket, drug: %{drug | summary: summary})}
  end
end
