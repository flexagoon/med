defmodule MedWeb.CheckResults do
  use MedWeb, :html

  attr :title, :string, required: true
  slot :inner_block, required: true

  def warning(assigns) do
    ~H"""
    <div class="text-bg bg-red-500 w-fit p-3 pb-0 rounded-xl">
      <h2 class="text-3xl sm:text-4xl font-bold pb-3">
        {@title} <.icon name="hero-exclamation-triangle-solid" class="w-10 h-10" />
      </h2>
      <p class="text-lg sm:text-xl pb-3">
        {render_slot(@inner_block)}
      </p>
    </div>
    """
  end

  attr :drug, Med.Drug, required: true

  def results(assigns) do
    ~H"""
    <p class="text-4xl font-black mb-8">
      Эффективность
      <%= if @drug.proven do %>
        <span class="text-accent">
          доказана
        </span>
      <% else %>
        <span class="text-accent">
          не доказана
        </span>
      <% end %>
    </p>

    <div class="text-2xl sm:text-3xl">
      <h2 class="text-accent font-bold">Активный ингредиент:</h2>
      <p class="w-fit p-3 m-3 border-l-4">{@drug.active_ingredient.ru}</p>

      <.research drug={@drug} />
    </div>
    <hr class="my-5" />
    <p class="text-fg/50">
      Данные предоставлены в ознакомительных целях и могут быть неточными. Не является медицинской рекомендацией. Информация взята из открытых источников, администрация сайта не несёт за неё ответственности.
    </p>
    """
  end

  attr :drug, Med.Drug, required: true

  defp research(%{drug: %{research: []}} = assigns) do
    ~H"""
    <p class="text-lg sm:text-xl pt-3 text-fg/80">
      По препарту не найдено ни одного исследования. Эта оценка учитывает только рандомизированные клинические исследования и мета-анализы. Эти виды исследований считаются самыми надежными, и их отсутствие означает, что препарат плохо изучен.
    </p>
    """
  end

  defp research(assigns) do
    ~H"""
    <p class="text-xl sm:text-2xl">На основе следующих факторов:</p>
    <ul class="list-disc pl-10 text-xl sm:text-2xl">
      <li :if={@drug.fda_approved}>Одобрен FDA</li>
      <li :if={@drug.who_list}>
        Входит в
        <a
          class="underline"
          href={"https://list.essentialmeds.org/?query=#{@drug.active_ingredient.en}"}
          target="_blank"
        >
          перечень WHO
        </a>
      </li>

      <.article_count
        label="Статей в Cochrane"
        href={"https://www.cochranelibrary.com/advanced-search?q=#{@drug.active_ingredient.en}&t=2"}
        count={@drug.cochrane}
      />
      <.article_count
        label="Статей в PubMed"
        href={"https://pubmed.ncbi.nlm.nih.gov/?term=#{@drug.active_ingredient.en}+AND+%28meta-analysis%5BFilter%5D+OR+randomizedcontrolledtrial%5BFilter%5D%29+AND+fha%5BFilter%5D+NOT+%22Cochrane+Database+Syst+Rev%22%5BJournal%5D"}
        count={@drug.pubmed}
      />
    </ul>

    <%= if @drug.description != "" do %>
      <h2 class="text-accent font-bold mt-10">Оценка эксперта:</h2>
      <p class="text-lg sm:text-xl pt-3 whitespace-pre-line">{@drug.description}</p>
      <p class="text-sm text-fg/50 text-right">
        Источник: <a class="underline" href="https://mediqlab.com" target="_blank">MedIQ</a>
      </p>
    <% end %>

    <h2 class="text-accent font-bold mt-10">ИИ-анализ:</h2>
    <%= if @drug.summary == "" do %>
      <p class="text-lg sm:text-xl pt-3 animate-pulse">Генерация анализа...</p>
    <% else %>
      <p class="text-lg sm:text-xl pt-3 whitespace-pre-line">{format_summary(@drug.summary)}</p>
    <% end %>
    <p class="text-sm text-fg/50 text-right">
      Анализ создан моделью
      <a class="underline" href="https://www.anthropic.com/claude/sonnet" target="_blank">
        Claude Sonnet 4
      </a>
    </p>
    """
  end

  attr :count, :integer, required: true
  attr :label, :string, required: true
  attr :href, :string

  defp article_count(assigns) do
    ~H"""
    <%= if @count > 0 do %>
      <%= if @count >= 100 do %>
        <li>
          <b class="text-accent">&gt; 100</b>
          <a class="underline" href={@href} target="_blank">{@label}</a>
        </li>
      <% else %>
        <li>
          <a class="underline" href={@href} target="_blank">{@label}</a>:
          <b class="text-accent">{@count}</b>
        </li>
      <% end %>
    <% end %>
    """
  end

  defp format_summary(summary) do
    summary = Regex.replace(~r/^\* /m, summary, "- ")
    summary = Regex.replace(~r/\*\*(.*?)\*\*/m, summary, "<b>\\1</b>")
    summary = Regex.replace(~r/\*(.*?)\*/m, summary, "<i>\\1</i>")
    summary = String.trim(summary)
    raw(summary)
  end
end
