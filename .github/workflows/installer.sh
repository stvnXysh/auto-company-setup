#!/bin/bash

set -e
LOGFILE="report.txt"
touch $LOGFILE

echo "🔍 Checking for required tools..." | tee -a $LOGFILE
for tool in git curl jq node npx; do
    if ! command -v $tool &> /dev/null; then
        echo "$tool not found. Please install it first." | tee -a $LOGFILE
        exit 1
    fi
done

echo "✅ All tools installed." | tee -a $LOGFILE

echo "📁 Creating project: $COMPANY" | tee -a $LOGFILE
mkdir -p $COMPANY && cd $COMPANY
echo "<h1>Welcome to $COMPANY</h1>" > index.html

echo "🗂️  Initializing Git repo and pushing to GitHub..." | tee -a $LOGFILE
git init
git add .
git commit -m "initial commit"

curl -s -H "Authorization: token $GH_TOKEN" \
     -d "{\"name\":\"$COMPANY\"}" \
     https://api.github.com/user/repos | tee -a $LOGFILE

git remote add origin https://github.com/$GH_USER/$COMPANY.git
git push -u origin master | tee -a $LOGFILE

echo "🚀 Deploying to Vercel..." | tee -a $LOGFILE
npx vercel deploy --prod --confirm --token=$VERCEL_TOKEN --cwd . | tee -a $LOGFILE

echo "📧 Creating email alias at ImprovMX..." | tee -a $LOGFILE
curl -s -X POST https://improvmx.com/api/aliases \
     -u "$IMPROV_KEY:" \
     -d domain=$DOMAIN \
     -d alias=info \
     -d destination=$ADMIN_EMAIL | tee -a $LOGFILE

echo "✅ Setup complete. Log saved to $LOGFILE" | tee -a $LOGFILE
