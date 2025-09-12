# med?

This is a service that allows to quickly check the trustworthiness of a medicine
by its Russian trade name.

## Launching

Since the app uses Gemini API for summarization, you need to obtain an API key
from the [Google AI Studio](https://aistudio.google.com).

Then, set the `GOOGLE_AI_API_KEY` environment variable to your API key. The
code reads `.env` files, so you can set the variable there if you want.

To launch or build the app, follow the [Phoenix documentation](https://hexdocs.pm/phoenix/overview.html).
The main command youu need is `mix phx.server` to run the code.
