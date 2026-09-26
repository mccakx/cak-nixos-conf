{ pkgs, lib, config, inputs, ...} :
let
  cfg = config.cak.plymouth;

  # Percent to enlarge the splash images by (100 = original pixel size).
  scale = cfg.scale;
  scaled = px: px * scale / 100;

  # White NixOS snowflake, drawn under the HUD animation. Taken from the 256px
  # icon and resized, so it stays sharp at any scale.
  distroLogo = "${pkgs.nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake-white.png";
  logoSize = toString (scaled 128);

  # adi1090x "black_hud" theme, patched to also show the distro logo and
  # resized by cfg.scale. (The package's installPhase doesn't run postInstall
  # hooks, so append to it.)
  blackHud = (pkgs.adi1090x-plymouth-themes.override {
    selected_themes = [ "black_hud" ];
  }).overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.imagemagick ];
    installPhase = old.installPhase + ''
      theme=$out/share/plymouth/themes/black_hud
      ${lib.optionalString (scale != 100) ''
        mogrify -resize ${toString scale}% $theme/progress-*.png
      ''}
      magick ${distroLogo} -resize ${logoSize}x${logoSize} $theme/logo.png
      cat >> $theme/black_hud.script <<'EOF'

      //------------------------------------- Distro logo -------------------------------
      logo.image = Image("logo.png");
      logo.sprite = Sprite(logo.image);
      logo.sprite.SetX(Window.GetX() + Window.GetWidth(0) / 2 - logo.image.GetWidth() / 2);
      logo.sprite.SetY(Window.GetY() + Window.GetHeight(0) / 2 + flyingman_image[0].GetHeight() / 2 + ${toString (scaled 48)});
      EOF
    '';
  });
in
{
  options.cak.plymouth.scale = lib.mkOption {
    type = lib.types.ints.between 50 400;
    default = 100;
    example = 125;
    description = "Percent to enlarge the Plymouth splash images by, like the desktop scale setting.";
  };

  config = {
    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };

    # Graphical boot splash: adi1090x black_hud + NixOS logo
    # (https://github.com/adi1090x/plymouth-themes).
    boot.plymouth = {
      enable = true;
      theme = "black_hud";
      themePackages = [ blackHud ];
      logo = distroLogo;
    };

    # Quiet the console so Plymouth's splash isn't overwritten by kernel/udev logs,
    # and hand off smoothly to SDDM. ("splash" is added by boot.plymouth itself.)
    boot.kernelParams = [ "quiet" "rd.udev.log_level=3" "udev.log_priority=3" ];
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;

    # kernel selection: the gaming-tuned CachyOS kernel comes from
    # modules/gaming.nix (cak.gaming.enable); non-gaming hosts use the
    # default nixpkgs kernel or set their own here.
  };
}
