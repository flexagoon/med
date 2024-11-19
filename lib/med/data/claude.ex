defmodule Med.Data.Claude do
  @moduledoc """
  Module for summarizing the research using Claude.
  """

  @system_prompt "You are 'med?', a fact-checking assistant checking the legitimacy of various drugs. Your goal is to summarize the provided research about a drug following the principles of evidence-based medicine"

  @spec summarize_research(Med.Drug.t(), pid()) :: Med.Drug.t()
  def summarize_research(drug, live_pid) do
    client = Anthropix.init()

    Anthropix.chat(client,
      model: "claude-3-5-sonnet-latest",
      system: @system_prompt,
      messages: [
        %{
          role: "user",
          content: build_prompt(drug)
        }
      ],
      stream: live_pid
    )

    drug
  end

  defp build_prompt(drug) when length(drug.research) < 100 do
    base_prompt(drug) <>
      """
      - The quantity of the research - there are only #{length(drug.research)} articles on the topic, take that into account.
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
