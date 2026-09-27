{ pkgs, ... } :

# EasyEffects on the desktop's analog out (ALC892 -> Harman Kardon SoundSticks 4).
#
# Chain: equalizer -> stereo tools -> autogain -> compressor -> limiter
# - equalizer:    "cinematic" voicing: deeper sub, less low-mid mud, a touch
#                 of dialogue, softened harshness, more air. Runs first so the
#                 loudness stages measure what you actually hear.
# - stereo tools: widens the stereo image a little (more side signal) for a
#                 roomier, surround-ish feel. Not real Atmos: that needs
#                 height/surround speakers or headphone HRTF.
# - autogain:     EBU R128 loudness normalisation towards -21 LUFS, using the
#                 short-term + integrated loudness over 30 s so it rides slowly
#                 instead of pumping on every loud moment.
# - compressor:   light 2:1, slow attack/release, only evens out big jumps
#                 (quiet dialogue vs. explosions).
# - limiter:      -1.5 dB true-peak safety net; with the settings above it
#                 should rarely engage.
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
          band1 = band "Lo-shelf" 70.0     2.0  0.7;  # deep, cinematic low end from the sub
          band2 = band "Bell"     250.0  (-3.0) 1.0;  # boomy / muddy low-mids
          band3 = band "Bell"     1800.0   1.0  1.2;  # dialogue
          band4 = band "Bell"     3500.0 (-1.5) 2.0;  # harshness / edge
          band5 = band "Hi-shelf" 8000.0   2.0  0.7;  # air, "sparkle"
        };
      in {
        blocklist = [ ];
        plugins_order = [ "equalizer#0" "stereo_tools#0" "autogain#0" "compressor#0" "limiter#0" ];

        "equalizer#0" = {
          bypass = false;
          input-gain = -3.0;   # headroom for the boosts
          output-gain = 0.0;
          mode = "IIR";
          split-channels = false;
          num-bands = 6;
          left = bands;
          right = bands;
        };

        "stereo_tools#0" = {
          bypass = false;
          input-gain = 0.0;
          output-gain = 0.0;
          mode = "LR > LR (Stereo Default)";
          stereo-base = 0.25;   # -1 mono .. 0 unchanged .. 1 max width
          softclip = false;
        };

        "autogain#0" = {
          bypass = false;
          input-gain = 0.0;
          output-gain = 0.0;
          target = -21.0;              # LUFS
          reference = "Geometric Mean (SI)";
          maximum-history = 30;        # seconds of loudness history
          silence-threshold = -70.0;   # don't pump up silence
          force-silence = false;
        };

        "compressor#0" = {
          bypass = false;
          input-gain = 0.0;
          output-gain = 0.0;
          mode = "Downward";
          threshold = -20.0;
          ratio = 2.0;
          knee = -9.0;
          attack = 40.0;
          release = 400.0;
          makeup = 0.0;
          dry = -80.01;   # fully wet
          wet = 0.0;
        };

        "limiter#0" = {
          bypass = false;
          input-gain = 0.0;
          output-gain = 0.0;
          mode = "Herm Wide";
          oversampling = "True Peak/24 bit";
          dithering = "None";
          threshold = -1.5;
          lookahead = 5.0;
          attack = 5.0;
          release = 20.0;     # max 20 ms
          alr = false;
        };
      };
  };
}
