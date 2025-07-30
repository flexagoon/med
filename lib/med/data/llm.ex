defmodule Med.Data.LLM do
  @moduledoc """
  Module for summarizing the research using an LLM.
  """
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatAnthropic
  alias LangChain.Message
  alias LangChain.MessageDelta

  @system_prompt "Вы - 'med?', ассистент по проверке фактов, оценивающий надежность различных лекарственных препаратов. Ваша цель - обобщить предоставленные исследования о препарате, следуя принципам доказательной медицины."

  @spec summarize_research(Med.Drug.t(), pid()) :: Med.Drug.t()

  def summarize_research(%{research: []} = drug, _live_pid), do: drug

  def summarize_research(drug, live_pid) do
    Task.start(fn ->
      generate(drug, live_pid)
    end)

    drug
  end

  defp generate(drug, live_pid) do
    prompt = build_prompt(drug)
    callback = message_handler(drug, live_pid)

    %{llm: ChatAnthropic.new!(%{model: "claude-sonnet-4-20250514", stream: true})}
    |> LLMChain.new!()
    |> LLMChain.add_messages([
      Message.new_system!(@system_prompt),
      Message.new_user!(prompt)
    ])
    |> LLMChain.add_callback(callback)
    |> LLMChain.run()
  end

  defp build_prompt(drug) do
    articles_xml =
      drug.research
      |> Enum.take(100)
      |> Enum.map_join("\n", fn article ->
        """
        <article>
          #{article}
        </article>
        """
      end)

    research_length = length(drug.research)

    """
    Вот аннотации научных исследований об активном ингредиенте "#{drug.active_ingredient.ru}" ("#{drug.active_ingredient.en}") препарата "#{drug.name}":

    <research>
      #{articles_xml}
    </research>

    Пожалуйста, напишите краткую (примерно 200 слов) сводку исследований и описание активного ингредиента на русском языке. Не используйте Markdown-заголовки.

    Пишите понятным научно-популярным языком.

    Сводка должна быть объективной (при наличии серьезных недочетов, это должно быть сразу понятно), но и не слишком жесткой (маленькие пробелы в знаниях не обязательно делают препарат ненадежным).

    Не ссылайтесь на номера исследований и не упоминайте их.

    Не забудьте оценить качество доказательств, основываясь на принципах доказательной медицины и научного метода. В вашем ответе укажите следующее:

    - Насколько хорошо изучен препарат
    - При каких состояниях доказана его эффективность/неэффективность
    - В каких областях исследований недостаточно
    - Насколько достоверны исследования в целом, имеются ли в них методологические ошибки
    - Насколько хорошо работает активный ингредиент исходя из общих знаний
    #{if research_length < 100 do
      "- Количество исследований - по этой теме есть всего #{research_length} статей, это нужно учесть."
    end}
    """
  end

  defp message_handler(drug, live_pid) do
    %{
      on_llm_new_delta: fn _model, %MessageDelta{} = delta ->
        send(live_pid, delta)
      end,
      on_message_processed: fn _model, %Message{content: text} ->
        Med.cache(%{drug | summary: text})
      end
    }
  end
end
