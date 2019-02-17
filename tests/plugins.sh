#/usr/bin/env bash

# Change directory to this test directory for relative paths.
cd $(dirname "$0")

# These may need to be changed!
HOST=tcc24
EXAMPLE_PLUGIN_SRC=../../inf-ice-example-plugin


echo -en "\e[92m"
echo "Exercise encapsia-plugins and encapsia-plugins-maker commands."
echo "They are *not* self-verifying tests, so check the output for reasonableness!"
echo
echo "Using server: $HOST"
echo "Using example src plugin code: $EXAMPLE_PLUGIN_SRC"
echo -en "\e[0m"

# Pretty print the test descriptions
function test() {
    echo -e "\n\n\e[1m=== $1 ===\e[0m\n"
}

# Always fail on error.
set -e

# Log commands except for echo because they are used to explain what is being done.
trap '[[ $BASH_COMMAND != test* ]] && echo -e ">${BASH_COMMAND}"' DEBUG


# TESTS START HERE...

test "Build the example plugin from src"
encapsia-plugins-maker --force build-from-src $EXAMPLE_PLUGIN_SRC

test "Requst a build again, but this time it should be skipped over because it already exists in the cache"
encapsia-plugins-maker build-from-src $EXAMPLE_PLUGIN_SRC

test "Move the example plugin out of the cache and then add it back in directly"
mv ~/.encapsia/plugins-cache/plugin-example-0.0.1.tar.gz /tmp/
encapsia-plugins-maker fetch-from-url file:///tmp/plugin-example-0.0.1.tar.gz

test "Build the launch plugin from legacy S3 (after first removing from the cache)"
rm -f ~/.encapsia/plugins-cache/plugin-launch-*.tar.gz
encapsia-plugins-maker build-from-legacy-s3 --versions=s3_plugins.toml --email=test_user@encapsia.com

test "Second time should be skipped over because it is already in the cache"
encapsia-plugins-maker build-from-legacy-s3 --versions=s3_plugins.toml --email=test_user@encapsia.com

test "Install the example plugin form the cache, then uninstall it"
encapsia-plugins --host=$HOST install --versions=example.toml
encapsia-plugins --host=$HOST uninstall example

test "Dev update the example plugin from scratch"
encapsia-plugins --host=$HOST dev-update $EXAMPLE_PLUGIN_SRC --reset

test "Second time round there is nothing to do because nothing has changed"
encapsia-plugins --host=$HOST dev-update $EXAMPLE_PLUGIN_SRC

test "Modify the example plugin and update again. This time only the tasks should be updated"
touch $EXAMPLE_PLUGIN_SRC/tasks/test_new_module.py
encapsia-plugins --host=$HOST dev-update $EXAMPLE_PLUGIN_SRC
rm $EXAMPLE_PLUGIN_SRC/tasks/test_new_module.py

test "Uninstall the example plugin"
encapsia-plugins --host=$HOST uninstall example

test "Create and destroy new namespace"
encapsia-plugins --host $HOST dev-create-namespace testing123
encapsia-plugins --host $HOST dev-destroy-namespace testing123

test "Get info on all plugins"
encapsia-plugins --host $HOST info