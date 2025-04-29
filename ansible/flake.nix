{
  description = "Nix flake for Ansible role and playbook development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      uv2nix,
      pyproject-nix,
      pyproject-build-systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      supportedSystems = lib.systems.flakeExposed; # Use nixpkgs default supported systems

      # Function to generate the *devShell derivation* for a given system
      mkDevShellForSystem =
        system:
        let
          # Load a uv workspace from the current directory.
          # Requires pyproject.toml and uv.lock to exist.
          workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

          # Create package overlay from workspace based on uv.lock.
          overlay = workspace.mkPyprojectOverlay {
            sourcePreference = "wheel";
          };

          # Placeholder overlay for potential manual build fixups
          pyprojectOverrides = _final: _prev: { };

          # Get nixpkgs for the specific system
          pkgs = nixpkgs.legacyPackages.${system};

          # Use Python from nixpkgs (matching pyproject.toml requires-python)
          python = pkgs.python311;

          # Construct the Python package set including our dependencies
          pythonSet =
            (pkgs.callPackage pyproject-nix.build.packages {
              inherit python;
            }).overrideScope
              (
                lib.composeManyExtensions [
                  pyproject-build-systems.overlays.default # Build systems (poetry-core)
                  overlay # Packages from uv.lock
                  pyprojectOverrides # Manual fixups
                ]
              );

          # Build a virtual environment containing ALL dependencies (base + dev)
          ansibleEnv = pythonSet.mkVirtualEnv "ansible-dev-env" workspace.deps.all;

        in
        # Return the shell derivation directly
        pkgs.mkShell {
          name = "ansible-dev-shell";
          packages = [
            ansibleEnv # Provides python, ansible, ansible-lint, molecule, etc.
            pkgs.uv # Include uv tool
            pkgs.git # Include git
            # Add other native tools if needed, e.g.: pkgs.sshpass
          ];

          env = {
            UV_NO_SYNC = "1";
            UV_PYTHON = "${ansibleEnv}/bin/python";
            UV_PYTHON_DOWNLOADS = "never";
          };

          shellHook = ''
            unset PYTHONPATH

            echo "--- Ansible Development Environment ---"
            echo "Ansible tools (ansible, ansible-lint, molecule, etc.) are available."
            echo "Python interpreter: $(which python)"
            echo "Activated environment: ${ansibleEnv}" # Show which venv is active
            echo "---------------------------------------"
          '';
        };
    in
    {
      # --- Development Shells ---
      # Structure: devShells.<system>.<name>
      devShells = lib.genAttrs supportedSystems (system: {
        # Define the 'default' dev shell for each system
        default = mkDevShellForSystem system;
      });

      # --- Legacy Alias (Optional but recommended for compatibility) ---
      # Structure: devShell.<system>
      # Provides compatibility with older tools/workflows expecting `devShell.<system>`
      devShell = lib.genAttrs supportedSystems (system: self.devShells.${system}.default);

    };
}
