{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Tailscale subnet router configuration
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
  };

  users.users.guilherme.shell = pkgs.zsh;

  services.tlp.enable = true;

   # custom modules
  services.scanbd.enable = true;
  services.scanbd.user = "guilherme";
  services.ssh-auth.enable = true;
}
