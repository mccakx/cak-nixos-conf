{ pkgs, lib, config, inputs,  ... } : {

  imports = [
    ./boot.nix
    ./environment.nix
    ./fonts.nix
    ./networking.nix
    ./programs.nix
    ./security.nix
    ./services.nix
    ./users.nix
    ./virtualisation.nix
  ];
  
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "all" ];
    extraLocaleSettings = {
      LANG = "en_US.UTF-8";
      LC_NUMERIC = "id_ID.UTF-8";
      LC_TIME = "id_ID.UTF-8";
      LC_MONETARY = "id_ID.UTF-8";
      LC_PAPER = "id_ID.UTF-8";
      LC_MEASUREMENT = "id_ID.UTF-8";
    };
  };
  
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  
  fileSystems = {
    "/" = { options = [ "compress=zstd:1" ]; };
    "/home" = { options = [ "compress=zstd:1" ]; };
    "/nix" = { options = [ "compress=zstd:1" "noatime" ]; };
  };
  
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [ "https://attic.xuyh0120.win/lantian" "https://ezkea.cachix.org" ];
      trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI=" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
  
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowedUnfreePredicate = (_: true);
    };
  };
  
  nixpkgs.config.packageOverrides = pkgs: rec {
    wpa_supplicant = pkgs.wpa_supplicant.overrideAttrs (attrs: {
      patches = attrs.patches ++ [ ./eduroam.patch ];
    });
  };

  nixpkgs.overlays = lib.singleton (final: prev: {
    kdePackages = prev.kdePackages // {
      plasma-workspace = let

        # the package we want to override
        basePkg = prev.kdePackages.plasma-workspace;

        # a helper package that merges all the XDG_DATA_DIRS into a single directory
        xdgdataPkg = pkgs.stdenv.mkDerivation {
          name = "${basePkg.name}-xdgdata";
          buildInputs = [ basePkg ];
          dontUnpack = true;
          dontFixup = true;
          dontWrapQtApps = true;
          installPhase = ''
            mkdir -p $out/share
            ( IFS=:
              for DIR in $XDG_DATA_DIRS; do
                if [[ -d "$DIR" ]]; then
                  cp -r $DIR/. $out/share/
                  chmod -R u+w $out/share
                fi
              done
            )
          '';
        };

        # undo the XDG_DATA_DIRS injection that is usually done in the qt wrapper
        # script and instead inject the path of the above helper package
        derivedPkg = basePkg.overrideAttrs {
          preFixup = ''
            for index in "''${!qtWrapperArgs[@]}"; do
              if [[ ''${qtWrapperArgs[$((index+0))]} == "--prefix" ]] && [[ ''${qtWrapperArgs[$((index+1))]} == "XDG_DATA_DIRS" ]]; then
                unset -v "qtWrapperArgs[$((index+0))]"
                unset -v "qtWrapperArgs[$((index+1))]"
                unset -v "qtWrapperArgs[$((index+2))]"
                unset -v "qtWrapperArgs[$((index+3))]"
              fi
            done
            qtWrapperArgs=("''${qtWrapperArgs[@]}")
            qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "${xdgdataPkg}/share")
            qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "$out/share")
          '';
        };

      in derivedPkg;
    };
  });
  
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  time.timeZone = "Asia/Jakarta";
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    enableAllFirmware = true;
  };
  
}
