{ pkgs, ... } :

# EasyEffects on the desktop's analog out (ALC892 -> Harman Kardon SoundSticks 4).
#
# Chain: equalizer -> stereo tools -> compressor -> autogain -> limiter
# - equalizer:    32-band "cinematic" voicing: deeper sub, less low-mid mud, a
#                 touch of dialogue, softened harshness, more air. Runs first so the
#                 loudness stages measure what you actually hear.
# - stereo tools: widens the stereo image a little (more side signal) for a
#                 roomier, surround-ish feel. Not real Atmos: that needs
#                 height/surround speakers or headphone HRTF.
# - compressor:   runs BEFORE autogain on purpose. Autogain only raises the
#                 gain if the current peak won't clip (autogain.cpp: gain *
#                 peak < 1), so a quiet video with sharp peaks (peak-to-loudness
#                 gap > |target|) never gets boosted. Squashing peaks first
#                 gives it room. Also evens out dialogue vs. explosions.
# - autogain:     EBU R128 loudness normalisation towards -23 LUFS, using the
#                 short-term + integrated loudness over 30 s so it rides slowly
#                 instead of pumping on every loud moment.
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
        # 31 bells (Q 2) on a log grid 32 Hz..18 kHz, gains fitted numerically
        # (RBJ biquads, 48 kHz) to this target curve, within 0.65 dB 40 Hz-16 kHz:
        #   +2.5 dB sub shelf @70 Hz, -3 dB @250 Hz (mud), +1 dB @1.8 kHz
        #   (dialogue), -0.5 dB @3.5 kHz (harshness), +1 dB @5 kHz (detail),
        #   +3.5 dB air shelf @7 kHz.
        # Shape it by editing the gains here, not in the GUI (read-only preset).
        bell = frequency: gain: band "Bell" frequency gain 2.0;
        bands = {
          band0   = band "Hi-pass" 25.0 0.0 0.7;  # sub rumble the woofer can't play cleanly
          band1   = bell     32.0 1.6;
          band2   = bell     39.5 0.4;
          band3   = bell     48.8 0.6;
          band4   = bell     60.3 0.5;
          band5   = bell     74.4 0.4;
          band6   = bell     91.9 0.3;
          band7   = bell    113.5 0.3;
          band8   = bell    140.2 0.2;
          band9   = bell    173.2 (-0.4);
          band10  = bell    213.9 (-1.3);
          band11  = bell    264.2 (-1.5);
          band12  = bell    326.2 (-0.9);
          band13  = bell    402.9 (-0.2);
          band14  = bell    497.6 0.1;
          band15  = bell    614.5 0.1;
          band16  = bell    758.9 0.0;
          band17  = bell    937.3 0.1;
          band18  = bell   1157.6 0.2;
          band19  = bell   1429.6 0.4;
          band20  = bell   1765.6 0.5;
          band21  = bell   2180.5 0.5;
          band22  = bell   2693.0 0.4;
          band23  = bell   3325.9 (-0.3);
          band24  = bell   4107.5 0.5;
          band25  = bell   5072.8 1.1;
          band26  = bell   6265.0 0.8;
          band27  = bell   7737.3 0.7;
          band28  = bell   9555.7 0.9;
          band29  = bell  11801.3 1.3;
          band30  = bell  14574.8 1.8;
          band31  = bell  18000.0 2.6;
        };
      in {
        blocklist = [ ];
        plugins_order = [ "equalizer#0" "stereo_tools#0" "compressor#0" "autogain#0" "limiter#0" ];

        "equalizer#0" = {
          bypass = false;
          input-gain = -3.0;   # headroom for the boosts
          output-gain = 0.0;
          mode = "IIR";
          split-channels = false;
          num-bands = 32;
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
          target = -23.0;              # LUFS
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
          threshold = -28.0;
          ratio = 3.5;
          knee = -9.0;
          attack = 15.0;
          release = 250.0;
          makeup = 0.0;
          dry = -80.01;   # fully wet
          wet = 0.0;
          # Detector only: bass carries most of the energy in music, so a
          # full-range peak detector ducked everything on every kick/bass note
          # ("sounds muted"). High-pass the sidechain and use RMS so it reacts
          # to the mids/highs level instead. The audio itself stays full range.
          hpf-mode = "24 dB/oct";
          hpf-frequency = 150.0;
          sidechain = {
            type = "Feed-forward";
            mode = "RMS";
            source = "Middle";
            reactivity = 20.0;   # ms RMS window
            lookahead = 0.0;
            preamp = 0.0;
          };
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
