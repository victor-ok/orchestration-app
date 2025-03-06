# Accept variables as arguments
NAMESPACE="$1"
APP_NAME="$2"

# Check if arguments are provided
if [ -z "$NAMESPACE" ] || [ -z "$APP_NAME" ]; then
  echo "Usage: $0 <namespace> <app_name>"
  exit 1
fi

# Input and temporary output file
template_file="$3"
temp_file="temp-deployment.yaml"

# Replace placeholders and create a new file
sed "s#\${NAMESPACE}#$NAMESPACE#g; s#\${APP_NAME}#$APP_NAME#g" "$template_file" > "$temp_file"

# Apply the generated YAML file
kubectl apply -f "$temp_file"

# Delete the temporary file
rm "$temp_file"

echo "Deployment applied and temporary file deleted."