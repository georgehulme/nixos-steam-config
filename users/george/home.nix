# users/george/home.nix
{ config, lib, pkgs, ... }:
{

  # Required Home Manager state version
  home.stateVersion = "unstable";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    settings = {
		  "*" = {
        KexAlgorithms = "sntrup761x25519-sha512@openssh.com,curve25519-sha256";
      };

			"github-hobby" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_hobby";
        extraOptions = {
          IdentitiesOnly = "yes";
        };
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      commit.gpgsign = true;
      core = {
        editor = "nvim";
        sshCommand = "ssh -o IdentityAgent=\${SSH_AUTH_SOCK}";
      };
      gpg.format = "openpgp";
      safe.directory = [
        "/etc/nixos"
      ];
      tag.gpgsign = true;
      user = {
        email = "georgehulme2@gmail.com";
        name = "George Hulme";
        # signingKey = <signing-key-id>;
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    enableExtraSocket = true;
    enableSshSupport = true;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
  };

  home = {
    activation = {
      importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        GPG="${pkgs.gnupg}/bin/gpg"
        # KEY_ID="${<signing-key-id>}"

        # Fetch key if not present in user keyring
        if ! $GPG --list-keys "$KEY_ID" >/dev/null 2>&1; then
          $GPG --keyserver hkps://keys.openpgp.org --recv-keys "$KEY_ID"
        fi

        # Set ultimate trust for signature signing
        echo "$KEY_ID:6:" | $GPG --import-ownertrust
      '';
    };

    file = {
      ".bashrc".text = ''
        # Source profile
        . "$HOME/.profile"
      '';

      ".cargo/config.toml".text = ''
        [build]
        rustc-wrapper = "sccache"

        [target.x86_64-unknown-linux-gnu]
        linker = "/usr/bin/clang"
        rustflags = ["-C", "link-arg=-fuse-ld=/usr/bin/mold"]
      '';

      # ".gnupg/sshcontrol".text = ''
      #   ${auth-key-keygrip}
      # '';

      ".profile".text = ''
        # Setup direnv
        ## Run direnv shell hook
        eval "$(direnv hook bash)"

        ## Setup SSH auth via OpenPGP
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

        ## Set direnv timeout warning to 2 minutes (default=20s)
        export DIRENV_WARN_TIMEOUT=2m

        # Setup sccache
        ## Set cache size
        export SCCACHE_CACHE_SIZE="5G"

        ## Set cache directory
        export SCCACHE_DIR="$HOME/.sccache/"

        # Setup editor env
        export EDITOR="nvim"
        export FCEDIT="$EDITOR"
      '';
    };
  };
}
