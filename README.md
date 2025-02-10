# med?

This is a service that allows to quickly check the trustworthiness of a medicine
by its Russian trade name.

## Algorithm

Here's how the code works:

1. Search for the trade name on [RLSNet](https://rlsnet.ru)
   - Get the official trade name in English (`name`)
   - Extract the main active ingredient (`active_ingredient`)
     - If there's no active ingredient, further steps are skipped and a warning is shown
   - Check if the drug is homeopathic (`homeopathy`)
     - If it is, further steps are skipped and a warning is shown
2. Use [OpenFDA API](https://open.fda.gov/) to get FDA approval status (`fda_approved`)
3. Use [PubMed E-Utils](https://www.ncbi.nlm.nih.gov/home/develop/api/) to fetch the abstracts of the research on the drug
   1. First, get the Cochrane Reviews on the topic
   2. Then, search for non-Cochrane studies by the trade name
   3. Lastly, search for non-Cochrane studies by the active ingredient name
   4. Save the numbers of found studies (`cochrane`, `pubmed`)
4. Summarize the obtained abstracts using [Gemini API](https://ai.google.dev)
5. Calculate the research score: $min(fda\\_approved * 40 + cochrane * 10 + pubmed, 100)$ 

## Launching

Since the app uses Gemini API for summarization, you need to obtain an API key
from the [Google AI Studio](https://aistudio.google.com).

Then, set the `GOOGLE_AI_API_KEY` environment variable to your API key. The
code reads `.env` files, so you can set the variable there if you want.

To launch or build the app, follow the [Phoenix documentation](https://hexdocs.pm/phoenix/overview.html).
The main command youu need is `mix phx.server` to run the code.
