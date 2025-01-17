#!/bin/bash
major_group=()
minor_group=()
patch_group=()

groups=()
delimiters=("MAJOR_START" "MAJOR_END" "MINOR_START" "MINOR_END" "PATCH_START" "PATCH_END")
groups=("major_group"  "minor_group"  "patch_group")

added="### Added"
changed="### Changed"
fixed="### Fixed"
removed="### Removed"

# First loop: Identify start of categorized messages
while read -r hash message;
do
    for i in {0..2}; do
        first_key_idx=$((i * 2))

        raw_key=${delimiters[$first_key_idx]}

        key="(${delimiters[$first_key_idx]})"
        
        second_key_idx=$(($first_key_idx + 1))
        
        raw_second_key=${delimiters[$second_key_idx]}

        if [[ "$message" == *$key* ]]; then
            changes=$(echo "$message" | sed -n "s/.*\(($raw_key)\)\(.*\)\(($raw_second_key)\).*/\2/p")
            counter=1
            echo "$changes" | grep -o '\*\*[^*]*\*\*' > temp.txt
            while IFS= read -r line; do
                suffix=$(echo "$line" | sed 's/\*\*//g')
                change="$counter. $suffix."
                part_before_parentheses=$(echo "$change" | sed 's/ (\(.*\))//')
                part_with_parentheses=$(echo "$change" | sed -n 's/.*\((.*)\).*/\1/p')
                if [[ $part_with_parentheses == "(Added)" ]]; then
                    added="${added}\n"
                    added+="$part_before_parentheses"
                elif [[ $part_with_parentheses == "(Changed)" ]]; then
                    changed="${changed}\n"
                    changed+="$part_before_parentheses"
                elif [[ $part_with_parentheses == "(Fixed)"  ]]; then
                    fixed="${fixed}\n"
                    fixed+="$part_before_parentheses"
                elif [[ $part_with_parentheses == "(Removed)"  ]]; then
                    removed="${removed}\n"
                    removed+="$part_before_parentheses"
                fi

                eval "${groups[$i]}+=("\"$change"\")"
                ((counter++))
            done < temp.txt
        fi
    done
done < <(git log --reverse --format="%H %s" $(git rev-list --max-parents=0 HEAD)..HEAD)

echo $added
echo ------
echo $changed
echo ------
echo $fixed
echo ------
major_to_add=${#major_group[@]}
minor_to_add=${#minor_group[@]}
patch_to_add=${#patch_group[@]}

latest_version=$(sed -n 's/^## \[\([0-9]*\.[0-9]*\.[0-9]*\)\].*/\1/p' CHANGELOG.md | head -1)

echo $latest_version

major=$(echo $latest_version | cut -d'.' -f1)
minor=$(echo $latest_version | cut -d'.' -f2)
patch=$(echo $latest_version | cut -d'.' -f3)


if [ $major_to_add -gt 0 ]; then
    major=$(( major + $major_to_add ))
    minor=0
    patch=0
fi
if [ $minor_to_add -gt 0 ]; then
    minor=$(( minor + $minor_to_add ))
    patch=0
fi
if [ $patch_to_add -gt 0 ]; then
    patch=$(( patch + $patch_to_add ))
fi
new_latest_version="$major.$minor.$patch"


echo new version $new_latest_version
echo ${major_group[@]}
echo ${minor_group[@]}
echo ${patch_group[@]}

echo $added
echo $changed
echo $fixed
echo $removed

# Text to insert
header="## [$new_latest_version] - date"

# File to update
file="CHANGELOG.md"

