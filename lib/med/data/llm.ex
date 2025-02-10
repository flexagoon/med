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
  def summarize_research(drug, live_pid) do
    Task.start(fn ->
      generate(drug, live_pid)
    end)

    drug
  end

  defp generate(drug, live_pid) do
    prompt = build_prompt(drug)
    callback = message_handler(drug, live_pid)

    %{llm: ChatAnthropic.new!(%{model: "claude-3-5-sonnet-latest", stream: true})}
    |> LLMChain.new!()
    |> LLMChain.add_messages([
      Message.new_system!(@system_prompt),
      Message.new_user!(prompt)
    ])
    |> LLMChain.add_callback(callback)
    |> LLMChain.run()
  end

  defp build_prompt(%Med.Drug{research: research} = drug) when length(research) < 100 do
    base_prompt(drug) <>
      """
      - Количество исследований - по этой теме есть всего #{length(research)} статей, это нужно учесть.
      """
  end

  defp build_prompt(drug), do: base_prompt(drug)

  defp base_prompt(drug) do
    articles_xml =
      drug.research
      |> Enum.take(20)
      |> Enum.map_join("\n", fn article ->
        """
        <article>
          #{article}
        </article>
        """
      end)

    """
    Вот аннотации научных исследований о препарате "#{drug.name}":

    <research>
      #{articles_xml}
    </research>

    Пожалуйста, напишите краткую (примерно 1 абзац) сводку исследований на русском языке.

    Не забудьте оценить качество доказательств, основываясь на принципах доказательной медицины и научного метода. В вашем ответе укажите следующее:

    - Насколько хорошо изучен препарат
    - При каких состояниях доказана его эффективность/неэффективность
    - В каких областях исследований недостаточно
    - Насколько достоверны исследования в целом
    - Возможная предвзятость/конфликты интересов в исследованиях
    - Если большинство исследований проведено в России или Китае, это сильно понижает надежность препарата
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
