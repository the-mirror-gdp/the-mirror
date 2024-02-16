echo "Node version"
node --version
echo "Yarn version"
yarn --version

echo "Installing dependencies"
npm install

echo "Starting Mirror NodeJS REST API Server"
yarn dev