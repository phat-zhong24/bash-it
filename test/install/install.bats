#!/usr/bin/env bats

load ../test_helper

# Determine which config file to use based on OS.
case $OSTYPE in
  darwin*)
    export BASH_IT_CONFIG_FILE=.bash_profile
    ;;
  *)
    export BASH_IT_CONFIG_FILE=.bashrc
    ;;
esac

function local_setup {
  setup_test_fixture
}

@test "install: verify that the install script exists" {
  assert_file_exist "$BASH_IT/install.sh"
}

@test "install: run the install script silently" {
  cd "$BASH_IT"

  ./install.sh --silent

  assert_file_exist "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE"

  assert_link_exist "$BASH_IT/enabled/150---general.aliases.bash"
  assert_link_exist "$BASH_IT/enabled/250---base.plugin.bash"
  assert_link_exist "$BASH_IT/enabled/800---aliases.completion.bash"
  assert_link_exist "$BASH_IT/enabled/350---bash-it.completion.bash"
  assert_link_exist "$BASH_IT/enabled/325---system.completion.bash"
}

@test "install: verify that a backup file is created" {
  cd "$BASH_IT"

  touch "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE"
  echo "test file content" > "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE"
  local md5_orig=$(md5sum "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE" | awk '{print $1}')

  ./install.sh --silent

  assert_file_exist "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE"
  assert_file_exist "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE.bak"

  local md5_bak=$(md5sum "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE.bak" | awk '{print $1}')

  assert_equal "$md5_orig" "$md5_bak"
}

@test "install: verify that silent and interactive can not be used at the same time" {
  cd "$BASH_IT"

  run ./install.sh --silent --interactive

  assert_failure
}

@test "install: verify that no-modify-config and append-to-config can not be used at the same time" {
  cd "$BASH_IT"

  run ./install.sh --silent --no-modify-config --append-to-config

  assert_failure
}

@test "install: verify that the template is appended" {
  cd "$BASH_IT"

  touch "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE"
  echo "test file content" > "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE"

  ./install.sh --silent --append-to-config

  assert_file_exist "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE"
  assert_file_exist "$BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE.bak"

  run cat $BASH_IT_TEST_HOME/$BASH_IT_CONFIG_FILE

  assert_line "test file content"
  assert_line "source \"\$BASH_IT\"/bash_it.sh"
}
