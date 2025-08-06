{ ... }:
{
  # Environment variables for differnt LLM providers:
  # - AWS Bedrock
  #   - ZED_AWS_ACCESS_KEY_ID
  #   - ZED_AWS_SECRET_ACCESS_KEY
  #   - ZED_AWS_REGION
  #   - ZED_AWS_PROFILE
  # - Anthropic
  #   - ANTHROPIC_API_KEY
  # - OpenAI
  programs.zed-editor = {
    enable = true;

    extensions = [
      "tokyo-night"

      "mcp-server-github"
      "mcp-server-grafana"
      "mcp-server-slack"
      "pollinations-mcp"
    ];

    userSettings = {
      theme = {
        mode = "system";
        light = "Ayu Light";
        dark = "Tokyo Night";
      };

      ui_font_size = 14;
      agent_font_size = 14;
      buffer_font_family = "MonaspiceKr NF";
      buffer_font_size = 12;
      terminal = {
        font_family = "MonaspiceKr NF";
        font_size = 12;
      };

      vim_mode = true;
      helix_mode = true;
    };
  };
}
