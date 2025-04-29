{
  description = "A collection of flake templates";

  outputs = {
    templates = {

      ansible = {
        path = ./ansible;
        description = "Nix flake for Ansible role and playbook development";
      };

      # opentofu = {
      #   path = ./opentofu;
      #   description = "Development environment for OpenTofu-managed infrastructure or modules";
      # };

      # terraform = {
      #   path = ./terraform;
      #   description = "Development environment for Terraform-managed infrastructure or modules";
      # };

    };
  };
}
