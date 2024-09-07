#!/bin/bash

if [ -z "$GITHUB_API_TOKEN" ]; then
  >&2 echo "Error: GITHUB_API_KEY_TOKEN has not been defined." \
    "Requests targeting github api will be rated limited!"
  exit 1
else
  echo "Using github api token $GITHUB_API_TOKEN"
fi

# ensure levenshtein is installed
if ! python -m pip show python-Levenshtein >/dev/null 2>&1; then
  echo "Installing python-Levenshtein..."
  python -m pip install python-Levenshtein
fi

# esnure html xpath and jq are installed
deb_dependencies="libxml2-utils jq"
if ! dpkg -s $deb_dependencies >/dev/null 2>&1; then
  echo "Installing $deb_dependencies..."
  apt update
  apt install $deb_dependencies -y --no-install-recommends
fi

function pypi_query_stable {
  curl -s "https://pypi.org/search/?q=$1" | \
   xmllint --nonet --html - --xpath "//a[@class='package-snippet' and contains(@href, '$1')]/@href" 2> /dev/null | \
   grep -Po "(?<=href\=\"/project/).*(?=/\")"
}

# define hashmap to keep package names and github project stargazer count
declare -A package_stars

echo $(pypi_query_stable $1)

for package_snippet in $(pypi_query_stable "$1"); do
  git_url="$(
    curl -s "https://pypi.org/project/$package_snippet/" | \
    xmllint --nonet --html - --xpath '//h6[contains(text(), "Project links")]/following-sibling::*[1]//a[contains(@href, "github")]/@href' 2> /dev/null | \
    grep -Po "(?<=href\=\"https://github.com/).*(?=\")" | \
    head -n 1 | \
    xargs -I {} echo 'https://api.github.com/repos/{}'
  )"
  echo "$package_snippet $git_url"
  if [ -z "$git_url" ]; then
    echo "No git url found for $package_snippet"
    # no git url, set count to zero
    package_stars["$package_snippet"]=0
    continue
  fi

  echo "Querying $package_snippet github url for stargazers_count statistic on $git_url"
  package_stars["$package_snippet"]=$(
    curl -s "$git_url" --header "Authorization: Bearer $GITHUB_API_TOKEN"| \
    jq '.stargazers_count'
  )

  # github repo was deleted, set count to zero
  if [ "${package_stars[$package_snippet]}" == "null" ];then
    package_stars["$package_snippet"]=0
  fi
done

echo -e '\n*** Package Rank ***'
# Ranking policy:
# 1. affinity to package name (closest match, lower is better)
# 2. porject popularity (number of github stars, higher is better)
# feel free to add otehr criteria
# just add another field of -k<field_num>,<field_num> left (higher importance) to (lower importance)right 
sorted_candidates=$(
for package in "${!package_stars[@]}"; do
  # some conflicts like in dateutil are avoided through prefixing with python
  # accomodate such edge cases in order you fidn another pattern by 
  # or-ing the look behind or by adding manually in the caller script
  _package="$(grep -Po '(?<=^python-).*' - <<< "$package" || echo "$package")"
  diff=$(python -c \
    "from Levenshtein import distance; print(distance('$1', '$_package'))"
  )
  echo "$package $diff ${package_stars[$package]}"
done | sort -k2,2n -k3,3rn
)

echo -e "$sorted_candidates\n***********************"

candidate=$(echo -e "$sorted_candidates" | head -n 1 | cut -d ' ' -f1)

echo -e "\nSelected candidate package:\n$candidate"

