#!/bin/sh

if [ "$2" = "" ]; then
    echo $0 oldlogin newlogin
    exit 1
fi

cp v2p.db "v2p.db.$(date)"

# rename a pseudo on all tables

echo "update user_page set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update user_photo_queue set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update user_post set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update user set login='"$2"' where login='"$1"';" | sqlite3 v2p.db

echo "update remember_user set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update user_stats set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update last_forum_visit set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update last_user_visit set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update comment set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update user_preferences set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update user_photo_of_the_week set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update themes_user_votes set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update user_rating set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db

echo "update rating set user_login='"$2"' where user_login='"$1"';" | sqlite3 v2p.db
