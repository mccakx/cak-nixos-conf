{ pkgs, lib, config, inputs, ... } : {

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ 51820 ];
    };
    networkmanager = {
      enable = true;
    };
 };

}
