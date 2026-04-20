# To do

## llama-swap config for Goose and OpenCode

```console
❯ cat ~/.config/goose/custom_providers/custom_peacehaven_llama_swap.json
{
  "name": "custom_peacehaven_llama_swap",
  "engine": "openai",
  "display_name": "Peacehaven llama-swap",
  "description": "Custom Peacehaven Llama Swap provider",
  "api_key_env": "",
  "base_url": "https://llama-swap.peacehaven.carrier.family/v1",
  "models": [
    {
      "name": "davidau-glm-4.7-flash-uncensored-heretic-neo-code-imatrix-max-gguf",
      "context_limit": 128000,
      "input_token_cost": null,
      "output_token_cost": null,
      "currency": null,
      "supports_cache_control": null
    },
    {
      "name": "google-gemma-4-31b-it-vllm",
      "context_limit": 128000,
      "input_token_cost": null,
      "output_token_cost": null,
      "currency": null,
      "supports_cache_control": null
    },
    {
      "name": "qwen-qwen3.6-35b-a3b",
      "context_limit": 128000,
      "input_token_cost": null,
      "output_token_cost": null,
      "currency": null,
      "supports_cache_control": null
    },
    {
      "name": "unsloth-qwen3-coder-next-gguf",
      "context_limit": 128000,
      "input_token_cost": null,
      "output_token_cost": null,
      "currency": null,
      "supports_cache_control": null
    }
  ],
  "headers": null,
  "timeout_seconds": null,
  "supports_streaming": true,
  "requires_auth": false,
  "catalog_provider_id": "ollama-cloud",
  "base_path": null,
  "env_vars": null,
  "dynamic_models": null,
  "skip_canonical_filtering": false,
  "fast_model": null
}⏎
```
