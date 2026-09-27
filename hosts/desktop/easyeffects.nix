{ pkgs, ... } :

# EasyEffects on the desktop's analog out (ALC892 -> Harman Kardon SoundSticks 4).
#
# Chain: equalizer -> autogain -> compressor -> limiter
# - equalizer:  mild voicing for the SoundSticks (cut sub rumble + low-mid
#               mud, a little presence and air). Runs first so the loudness
#               stages measure what you actually hear.
# - autogain:   EBU R128 loudness normalisation, pulls every source (quiet
#               YouTube, loud game, mastered music) towards -18 LUFS.
# - compressor: gentle 3:1 on peaks so quiet dialogue and loud scenes in
#               films sit closer together.
# - limiter:    -1 dB ceiling, catches anything autogain boosted too far.
#
# The preset files are read-only Nix store links: to experiment, tweak in the
# GUI and "Save as" a new preset name, then copy the values back here.
# Keys not set below fall back to EasyEffects' defaults.
let
  # EasyEffects 8 only forwards --load-preset over its local socket to an
  # already-running instance, so the HM module's `preset` (passed to the
  # service itself) is silently dropped. Load it from a client once the
  # service is listening instead. Offscreen Qt: the client needs no window.
  loadPreset = pkgs.writeShellScript "easyeffects-load-preset" ''
    export QT_QPA_PLATFORM=offscreen
    sleep 3
    exec ${pkgs.easyeffects}/bin/easyeffects --load-preset SoundSticks4
  '';
in
{
  home-manager.users.cak.systemd.user.services.easyeffects.Service.ExecStartPost = "${loadPreset}";

  home-manager.users.cak.services.easyeffects = {
    enable = true;

    extraPresets.SoundSticks4.output =
      let
        band = type: frequency: gain: q: {
          inherit type frequency gain q;
          mode = "RLC (BT)";
          slope = "x1";
          solo = false;
          mute = false;
        };
        bands = {
          band0 = band "Hi-pass"  25.0     0.0  0.7;  # sub rumble the woofer can't play cleanly
          band1 = band "Bell"     200.0  (-2.5) 1.2;  # boomy / muddy low-mids
          band2 = band "Bell"     450.0  (-1.0) 1.4;  # boxiness
          band3 = band "Bell"     2500.0   1.5  1.0;  # presence, dialogue clarity
          band4 = band "Hi-shelf" 10000.0  1.5  0.7;  # air
        };
      in {
        blocklist = [ ];
        plugins_order = [ "equalizer#0" "autogain#0" "compressor#0" "limiter#0" ];

        "equalizer#0" = {
          bypass = false;
          input-gain = -2.0;   # headroom for the boosts
          output-gain = 0.0;
          mode = "IIR";
          split-channels = false;
          num-bands = 5;
          left = bands;
          right = bands;
        };

        "autogain#0" = {
          bypass = false;
          input-gain = 0.0;
          output-gain = 0.0;
          target = -18.0;              # LUFS
          reference = "Geometric Mean (MSI)";
          maximum-history = 15;        # seconds of loudness history
          silence-threshold = -70.0;   # don't pump up silence
          force-silence = false;
        };

        "compressor#0" = {
          bypass = false;
          input-gain = 0.0;
          output-gain = 0.0;
          mode = "Downward";
          threshold = -24.0;
          ratio = 3.0;
          knee = -6.0;
          attack = 20.0;
          release = 250.0;
          makeup = 3.0;
          dry = -80.01;   # fully wet
          wet = 0.0;
        };

        "limiter#0" = {
          bypass = false;
          input-gain = 0.0;
          output-gain = 0.0;
          mode = "Herm Thin";
          oversampling = "Half x2/24 bit";
          dithering = "None";
          threshold = -1.0;
          lookahead = 5.0;
          attack = 5.0;
          release = 20.0;     # max 20 ms
          alr = false;
        };
      };
  };
}
