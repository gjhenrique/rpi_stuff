{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = {
    nixpkgs,
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
    nixosConfigurations = (
      import ./hosts {
        inherit nixpkgs pkgsFor;
      }
    );
  };
}
