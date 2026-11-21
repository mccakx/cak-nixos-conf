{ pkgs, lib, config, inputs, ...} : {

  users.users.cak = {
    isNormalUser = true;
    createHome = true;
    initialPassword = "12345";
    extraGroups = [ "wheel" "libvirtd" "podman" "networkmanager" ];
    name = "cak";
    home = "/home/cak";
    # sshd is key-only (modules/services.nix); the initial password is for console login.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEO0lbPxlPCzWIqikHJSrhoJZ4oTCfjlCRjxFOQPMWq cak@desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOB7kgvawLZhalWu0zgHKbPZZ89oraBzBbrxofmQRD0U deltaserv"
    ];
  };
}
