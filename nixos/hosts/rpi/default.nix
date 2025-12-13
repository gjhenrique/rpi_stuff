{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  users.users.guilherme.shell = pkgs.bash;

  users.users.guilherme.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAOtJO7WF9lx0bpGrHUMDg6r3U2IoImwG+Afx1wmszEj backrest-backup-key"
  ];

  services.ssh-auth.enable = true;

  fileSystems."/mnt/external" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [ "nofail" ];
  };
}
