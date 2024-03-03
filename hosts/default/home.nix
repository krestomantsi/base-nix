#.config/home-manager/home.nix

 programs = {
      zsh = {
          enable = true;
          enableAutosuggestions.enable = true;
          syntaxHighlighting.enable = true;
          oh-my-zsh = {
            enable = true;
            theme = "robbyrussell";
            plugins = [
              "git"
              "npm"
              "history"
              "node"
              "rust"
              "deno"
            ];
          };
      };
  };
