defmodule Med.Data.Claude do
  @moduledoc """
  Module for summarizing the research using Claude.
  """

  @system_prompt "Вы - 'med?', ассистент по проверке фактов, оценивающий надежность различных лекарственных препаратов. Ваша цель - обобщить предоставленные исследования о препарате, следуя принципам доказательной медицины."

  @spec summarize_research({[String.t()], Med.Drug.t()}, pid()) :: Med.Drug.t()
  def summarize_research({_research, drug} = data, live_pid) do
    client = Anthropix.init()

    Anthropix.chat(client,
      model: "claude-3-5-sonnet-latest",
      system: @system_prompt,
      messages: [
        %{
          role: "user",
          content: build_prompt(data)
        }
      ],
      stream: live_pid
    )

    drug
  end

  defp build_prompt({research, _drug} = data) when length(research) < 100 do
    base_prompt(data) <>
      """
      - Количество исследований - по этой теме есть всего #{length(research)} статей, это нужно учесть.
      """
  end

  defp build_prompt(data), do: base_prompt(data)

  defp base_prompt({research, drug}) do
    articles_xml =
      research
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
end
