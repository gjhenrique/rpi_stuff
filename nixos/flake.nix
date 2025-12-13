{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = {
    nixpkgs,
    nixos-hardware,
    self,
    ...
  } @ inputs: let
    linux_x86 = "x86_64-linux";
    linux_arm = "aarch64-linux";
    systems = [linux_x86 linux_arm];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    pkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
  in {
    formatter = forAllSystems (system: pkgsFor.${system}.alejandra);

    nixosConfigurations = (
      import ./hosts {
        inherit nixpkgs pkgsFor;
      }
    );
  };
}
