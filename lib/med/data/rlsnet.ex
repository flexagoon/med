defmodule Med.Data.RLSNet do
  @moduledoc """
  РЛС, the Russian registry of medicine, is used to get the information about
  the active ingredient and the English name of the medicine.

  Uses https://rlsnet.ru to fetch the data, since the official
  https://grls.rosminzdrav.ru website has a captcha.
  """

  alias Med.Drug

  @spec fetch(String.t()) :: Med.Drug.t()
  def fetch(name) do
    search_response = Req.get!("https://www.rlsnet.ru/search_result.htm", params: [word: name])

    url_tag =
      search_response.body
      |> Floki.parse_document!()
      |> Floki.attribute("img.mr-1 + a", "href")

    case url_tag do
      [] ->
        nil

      [url | _other] ->
        fetch_drug(url)
    end
  end

  defp fetch_drug(url) do
    data_response = Req.get!(url)

    data = Floki.parse_document!(data_response.body)

    english_name =
      data
      |> Floki.find("h1")
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
      [] ->
        nil

      [link | _] ->
        link
        |> Floki.text()
        |> String.trim()
    end
  end
end
