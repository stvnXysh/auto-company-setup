#!/bin/bash

# Exit on error
set -e

# 1. Validate environment variables
REQUIRED_VARS=(GH_USER GH_TOKEN VERCEL_TOKEN IMPROV_KEY ADMIN_EMAIL COMPANY)
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "❌ Error: $var is not set. Please export it before running."
        exit 1
    fi
done

# 2. Create temp working directory
WORKDIR=$(mktemp -d)
cd "$WORKDIR"
echo "📁 Working in $WORKDIR"

# 3. Create basic HTML landing page
mkdir $COMPANY && cd $COMPANY
cat <<EOF > index.html
<!DOCTYPE html>
<html>
<head><title>$COMPANY</title></head>
<body><h1>Welcome to $COMPANY</h1></body>
</html>
EOF

# 4. Initialize Git & push to GitHub
git init
git remote add origin https://$GH_USER:$GH_TOKEN@github.com/$GH_USER/$COMPANY.git
gh repo create $COMPANY --public --confirm
git add .
git commit -m "Initial commit"
git push -u origin master

# 5. Deploy with Vercel CLI
npm install -g vercel
vercel --token $VERCEL_TOKEN --confirm --name $COMPANY --prod > vercel_output.txt
DEPLOYED_URL=$(grep -o 'https://[^ ]*\.vercel\.app' vercel_output.txt | head -n1)

# 6. Set up ImprovMX forwarding (contact@yourcompany.improvmx.com → admin email)
curl -s -X POST https://api.improvmx.com/v3/domains/improvmx.com/aliases \
  -u "$IMPROV_KEY:" \
  -d alias="contact@$COMPANY.improvmx.com" \
  -d destination="$ADMIN_EMAIL"

# 7. Report results
cat <<EOF > report.txt
✅ GitHub Repo: https://github.com/$GH_USER/$COMPANY
✅ Vercel Site: $DEPLOYED_URL
✅ Email Forwarding: contact@$COMPANY.improvmx.com → $ADMIN_EMAIL
EOF

cat report.txt
