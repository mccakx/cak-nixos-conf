{pkgs, ...}: {

  imports = [
    ../../home/default.nix
    #../../home/kde
    ../../home/programs
  ];
  #home.username = "mccak";
}
