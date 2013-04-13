#!/bin/sh

if [ "$1" = "" ]; then
    echo $0 login
    exit 1
fi

cp v2p.db "v2p.db.$(date)"

# remove e-mail and password

echo "delete from user where login='"$1"';" | sqlite3 v2p.db

echo "delete from user_page where user_login='"$1"';" | sqlite3 v2p.db
echo "delete from user_photo_queue where user_login='"$1"';" | sqlite3 v2p.db
echo "delete from remember_user where user_login='"$1"';" | sqlite3 v2p.db
echo "delete from user_stats where user_login='"$1"';" | sqlite3 v2p.db
