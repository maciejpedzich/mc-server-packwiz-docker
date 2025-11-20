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

VERSION_FIELDS=$(cat pack.toml | tail -n 2 | tr -d ' "')
FIRST_FIELD=$(echo "$VERSION_FIELDS" | head -n 1)
SECOND_FIELD=$(echo "$VERSION_FIELDS" | tail -n 1)
MINECRAFT_FIELD=$([[ "$FIRST_FIELD" =~ minecraft ]] && echo "$FIRST_FIELD" || echo "$SECOND_FIELD")
MOD_LOADER_FIELD=$([[ "$FIRST_FIELD" =~ minecraft ]] &&  echo "$SECOND_FIELD"  || echo "$FIRST_FIELD" )

MINECRAFT_VERSION=$(echo "$MINECRAFT_FIELD" | cut -d '=' -f 2)
MOD_LOADER_NAME=$(echo "$MOD_LOADER_FIELD" | cut -d '=' -f 1 | tr '[:lower:]' '[:upper:]')
MOD_LOADER_VERSION=$(echo "$MOD_LOADER_FIELD" | cut -d '=' -f 2)
LOADER_VERSION_VAR_NAME=$([[ "$MOD_LOADER_NAME" = "FORGE" ]] && echo "FORGE_VERSION" || echo "${MOD_LOADER_NAME}_LOADER_VERSION")
RCON_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)

echo "# For a complete list of environment variables and their defaults, see:
# https://docker-minecraft-server.readthedocs.io/en/latest/variables

EULA=true
PACKWIZ_URL=http://packwiz:3000/pack.toml
RCON_PASSWORD=${RCON_PASSWORD}
TYPE=${MOD_LOADER_NAME}
VERSION=${MINECRAFT_VERSION}
${LOADER_VERSION_VAR_NAME}=${MOD_LOADER_VERSION}" > .env

echo "Created .env file for the Minecraft server container!"

echo "[options]
no-internal-hashes = true" >> pack.toml

echo '#!/bin/bash

if ! [ -x "$(command -v packwiz)" ]; then
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

if [ -e /tmp/.commit ]; then
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
git commit -m "(re)init modpack" -q

if [[ $? -eq 0 ]]; then
    echo "Successfully committed changes!"
    echo "Setup complete!"
else
    echo "Setup Error: failed to commit changes!" >&2
    exit 1
fi
