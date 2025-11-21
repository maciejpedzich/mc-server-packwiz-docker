#!/bin/bash

if [[ ! -x "$(command -v packwiz)" ]]; then
    echo -e "Setup Error: packwiz is not installed in PATH!\n" >&2
    echo "Installation instructions can be found here:" >&2
    echo "https://packwiz.infra.link/installation" >&2
    exit 1
fi

echo "Initialising packwiz modpack..."
packwiz init -r

if [[ $? -ne 0 ]] || [[ ! -f pack.toml ]]; then
    echo "Setup Error: failed to initialise packwiz modpack!" >&2
    exit 1
fi

grep -q liteloader pack.toml

if [[ $? -eq 0 ]]; then
    echo "Setup Error: LiteLoader is not supported!" >&2
    exit 1
fi

version_fields=$(cat pack.toml | tail -n 2 | tr -d ' "')
first_field=$(echo "$version_fields" | head -n 1)
second_field=$(echo "$version_fields" | tail -n 1)

minecraft_field=$([[ "$first_field" =~ minecraft ]] && echo "$first_field" || echo "$second_field")
minecraft_version=$(echo "$minecraft_field" | cut -d '=' -f 2)

mod_loader_field=$([[ "$first_field" =~ minecraft ]] &&  echo "$second_field" || echo "$first_field" )
mod_loader_name=$(echo "$mod_loader_field" | cut -d '=' -f 1 | tr '[:lower:]' '[:upper:]')
mod_loader_version=$(echo "$mod_loader_field" | cut -d '=' -f 2)
loader_version_var=$([[ "$mod_loader_name" = "FORGE" ]] && echo "FORGE_VERSION" || echo "${mod_loader_name}_LOADER_VERSION")

echo "# For a complete list of environment variables and their defaults, see:
# https://docker-minecraft-server.readthedocs.io/en/latest/variables

EULA=true
PACKWIZ_URL=http://packwiz:3000/pack.toml
RCON_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
TYPE=${mod_loader_name}
VERSION=${minecraft_version}
${loader_version_var}=${mod_loader_version}" > .env

echo "Created .env file for the Minecraft server container!"

echo "[options]
no-internal-hashes = true" >> pack.toml

echo '#!/bin/bash

if  [[ ! -x "$(command -v packwiz)" ]]; then
    echo "Error: packwiz is not installed!" >&2
    exit 1
fi

readarray ignored_files < .dockerignore

for file in ${ignored_files[@]}; do
    mv $file "/tmp/$file"
done

packwiz refresh --build
touch /tmp/.commit' > .git/hooks/pre-commit

echo '#!/bin/bash

if [[ -e /tmp/.commit ]]; then
    rm /tmp/.commit
    readarray ignored_files < /tmp/.dockerignore

    for file in ${ignored_files[@]}; do
        mv "/tmp/$file" $file
    done

    git add -A
    git commit --amend -C HEAD --no-verify
fi' > .git/hooks/post-commit

echo "Created pre/post-commit Git hooks to prevent indexing of files in .dockerignore!"
echo "Making new hooks executable..."
sudo chmod +x .git/hooks/pre-commit .git/hooks/post-commit

if [[ $? -eq 0 ]]; then
    echo "Successfully updated hooks' permissions!"
else
    echo "Setup Error: failed to update hooks' permissions!" >&2
    exit 1
fi

echo "Committing modpack manifest and index..."

git add -A
git commit -m "Init modpack" -q

if [[ $? -eq 0 ]]; then
    echo "Successfully committed changes!"
    echo "Setup complete!"
else
    echo "Setup Error: failed to commit changes!" >&2
    exit 1
fi
