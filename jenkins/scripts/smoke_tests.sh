#!/bin/bash

ENV=$1
WEB_IPS=$2
DB_IP=$3

# web server test
for ip in ${WEB_IPS//,/ }; do
    echo "Testing web server at $ip..." # IP for testing TAKE OUT LATER
    if curl -s -f "http://$ip" > /dev/null; then
        echo "Web server at $ip is responding"
    else
        echo "Web server at $ip is NOT responding"
        exit 1
    fi
done

# database test
WEB_IP=$(echo $WEB_IPS | cut -d',' -f1)
echo "Testing database connectivity through $WEB_IP..."
if ssh -i ~/.ssh/id_rsa ubuntu@$WEB_IP "pg_isready -h $DB_IP -U db_user"; then
    echo "Database is responding"
else
    echo "Database is NOT responding"
    exit 1
fi

echo "All smoke tests passed!"