defmodule Med.Data.RLSNet do
  @moduledoc """
  РЛС, the Russian registry of medicine, is used to get the information about
  the active ingredient and the English name of the medicine.

  Uses https://rlsnet.ru to fetch the data, since the official
  https://grls.rosminzdrav.ru website has a captcha.
  """

  alias Med.Drug

  def fetch(name) do
    url =
      Req.get!("https://www.rlsnet.ru/search_result.htm", params: [word: name]).body
      |> Floki.parse_document!()
      |> Floki.attribute("img.mr-1 + a", "href")
      |> hd()

    data = Req.get!(url).body |> Floki.parse_document!()

    english_name =
      Floki.find(data, "h1")
      |> Floki.text()
      |> extract_english_name()

    is_homeopathy =
      get_section(data, "farmakologiceskaia-gruppa") == "Гомеопатические средства"

    drug = %Drug{name: english_name, homeopathy: is_homeopathy}

    case get_section(data, "deistvuiushhee-veshhestvo") do
      nil ->
        %{drug | active_ingredient: nil}

      active_ingredient ->
        %{drug | active_ingredient: extract_english_name(active_ingredient)}
    end
  end

  defp extract_english_name(name) do
    Regex.run(~r/\(([\w ®*+]+)\)/, name)
    |> Enum.at(1)
    |> String.replace("®", "")
    |> String.replace("*", "")
    |> String.downcase(:ascii)
    |> String.split("+")
    |> hd()
    |> String.trim()
  end

  defp get_section(html, section) do
    case Floki.find(html, "h2##{section} + div a") do
      [] -> nil
      [link | _] -> Floki.text(link) |> String.trim()
    end
  end
end
