{
  description = "A collection of flake templates";

  outputs =
    { self }:
    {
      templates = {

        ansible = {
          path = ./ansible;
          description = "Nix flake for Ansible role and playbook development";
        };

        kubernetes = {
          path = ./kubernetes;
          description = "Development environment for kubernetes-managed infrastructure or modules";
        };

        opentofu = {
          path = ./opentofu;
          description = "Development environment for OpenTofu-managed infrastructure or modules";
        };

        terraform = {
          path = ./terraform;
          description = "Development environment for Terraform-managed infrastructure or modules";
        };

      };
    };
}
