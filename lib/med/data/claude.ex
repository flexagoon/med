defmodule Med.Data.Claude do
  @moduledoc """
  Module for summarizing the research using Claude.
  """

  @system_prompt "You are 'med?', a fact-checking assistant checking the legitimacy of various drugs. Your goal is to summarize the provided research about a drug following the principles of evidence-based medicine"

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
      - The quantity of the research - there are only #{length(research)} articles on the topic, take that into account.
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
    Here are the abstracts of the research articles on the drug "#{drug.name}":

    <research>
      #{articles_xml}
    </research>

    Please write a short (~1 paragraph) summary of the research.

    Remember to evaluate the quality of evidence based on the principles of evidence-based medicine and the scientific method. In your answer, include the following:

    - How well-researched the drug is
    - What conditions is it proven to be effective/not effective for
    - In what areas the research is lacking
    - How trustworthy the overall research is
    - Any potential bias/conflicts of interest in the research
    - How trustworthy is the drug on the scale of 1 to 10
    """
  end
end
