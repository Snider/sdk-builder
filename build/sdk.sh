#!/bin/bash
# NOTE : Quote it else use array to avoid problems #
BASE_DIR="$(pwd)"
echo "Base Directory: ${BASE_DIR}"
package="*"
while getopts p: flag
do
    case "${flag}" in
        p) package=${OPTARG}.json;;
        *) ;;
    esac
done

PACKAGE_VERSION=$(cat "${BASE_DIR}/build/gogetssl.json" | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]')
PACKAGES="${BASE_DIR}/build/packages/$package"
for f in $PACKAGES
do
  echo "Processing $f file..."
  # map file name to openapi generator conf file names
  filename=$(basename "$f" .json)
  # remove previous build
  rm -rf "${BASE_DIR}/../tmp-build/client/$filename/*"
  # Build the SDK's
  openapi-generator-cli generate  --skip-validate-spec -i "${BASE_DIR}/build/gogetssl.json" -g "$filename" -o "${BASE_DIR}/../tmp-build/client/$filename" -c "$f" --git-host "github.com" \
  --git-repo-id "@snider/sdk-gogetssl-$filename" --git-user-id "snider" --artifact-version "${PACKAGE_VERSION}" --group-id "gogetssl" \
  -p packageVersion="${PACKAGE_VERSION}" --global-property "apiTests=true"
  # Push to git
  (cp -f "${BASE_DIR}/build/ext/git_push.sh" "${BASE_DIR}/../tmp-build/client/$filename/git_push.sh" && chmod +x "${BASE_DIR}/../tmp-build/client/$filename/git_push.sh" &&
  cd "${BASE_DIR}/../tmp-build/client/$filename" && /bin/sh "$BASE_DIR/../tmp-build/client/$filename"/git_push.sh snider sdk-gogetssl-"$filename")
done

echo "Yay! all done"