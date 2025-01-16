current_type=""
current_message=""
current_hash=""

# First loop: Identify start of categorized messages
#git log --reverse --format="%H %s" $(git rev-list --max-parents=0 HEAD)..HEAD | while read hash message
message="(PATCH START)
            ** added new feature that is not backward compatible **
        (PATCH START)
            "
for i in {1..2}; do
    if [[ $message == *"(MAJOR START)"* || $message == *"(MINOR START)"* || $message == *"(PATCH START)"*  ]]; then
        echo "entered PATCH"
    fi
done