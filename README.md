# nix-flakes

Some flakes that I find useful for adding to my projects with common tooling ready.

If a flake already exists at https://github.com/NixOS/templates, I recommend using that

## aliases/functions

I use aliases in my system configuration so I can easily initialize a project with these templates (pulled from git) and
a corresponding [envrc](https://direnv.net/).

Example:

Fish Shell Function

```fish
function flakify --description "Initialize a Nix flake and direnv environment"
    # Configuration
    set -l user_flake_url "github:tcpkump/nix-flakes"
    set -l default_template "github:nix-community/nix-direnv"
    set -l official_flake_url "github:NixOS/templates"
    
    # Create flake.nix if it doesn't exist
    if not test -e flake.nix
        set -l template_to_use ""
        
        if set -q argv[1]
            set -l template_name $argv[1]
            
            # Try personal repo first
            if nix flake show --json --quiet --no-warn-dirty "$user_flake_url" 2>/dev/null | 
               jq -e --arg name "$template_name" '.templates[$name] != null' >/dev/null 2>&1
                set template_to_use "$user_flake_url#$template_name"
                echo "Using template '$template_name' from personal repo"
            # Then try official repo
            else if nix flake show --json --quiet --no-warn-dirty "$official_flake_url" 2>/dev/null | 
                    jq -e --arg name "$template_name" '.templates[$name] != null' >/dev/null 2>&1
                set template_to_use "$official_flake_url#$template_name"
                echo "Using template '$template_name' from official repo"
            else
                echo "Error: Template '$template_name' not found in any repository" >&2
                return 1
            end
        else
            # Use default template
            set template_to_use $default_template
            echo "No template specified, using default: $default_template"
        end
        
        # Create flake using template
        if not nix flake new --quiet --template "$template_to_use" .
            echo "Error: Failed to create flake" >&2
            return 1
        end
        echo "flake.nix created successfully"
    end
    
    # Create .envrc if needed
    if not test -e .envrc
        echo "source_up_if_exists" >> .envrc
        echo "use flake" >> .envrc
        echo ".envrc created"
    end
    
    # Open in editor
    if test -n "$EDITOR"
        echo "Opening flake.nix in $EDITOR"
        $EDITOR flake.nix
    else
        echo "Warning: \$EDITOR not set. Please edit flake.nix manually."
    end
end
```
