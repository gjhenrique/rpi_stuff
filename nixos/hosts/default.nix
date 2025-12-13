{
  pkgsFor,
  nixpkgs,
}: {
  lisa = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      pkgs = pkgsFor."x86_64-linux";

      host = {
        hostName = "lisa";
      };
    };
    modules = [
      ./lisa
      ./configuration.nix
      ../modules/scanning.nix
      ../modules/ssh-auth.nix
    ];
  };
  rpi = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    specialArgs = {
      pkgs = pkgsFor."aarch64-linux";

      host = {
        hostName = "rpi";
      };
    };
    modules = [
      ./rpi
      ./configuration.nix
      ../modules/ssh-auth.nix
    ];
  };
}
