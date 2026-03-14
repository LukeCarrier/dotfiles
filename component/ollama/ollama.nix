{ ... }:
{
  services.ollama = {
    enable = true;
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "GPU-c4528165-5c12-164b-e7d2-873249aa04c3";

      OLLAMA_DEBUG = "1";

      OLLAMA_NOPRUNE = "1";

      OLLAMA_GPU_MEMORY_FRACTION = "0.8";
      OLLAMA_SWAP_SPACE = "16GB";

      OLLAMA_MEMORY_COMPRESSION = "true";
      OLLAMA_COMPRESSION_RATIO = "0.6";

      OLLAMA_MIXED_PRECISION = "fp16";
      OLLAMA_GRADIENT_CHECKPOINTING = "true";

      OLLAMA_CPU_FALLBACK = "true";

      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q4_0";

      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_MAX_QUEUE = "8";
    };
  };
}
