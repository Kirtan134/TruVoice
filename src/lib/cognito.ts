import { CognitoIdentityProviderClient } from "@aws-sdk/client-cognito-identity-provider";

// AWS Cognito Configuration
export const cognitoConfig = {
  region: process.env.AWS_REGION || "us-east-1",
  userPoolId: process.env.AWS_COGNITO_USER_POOL_ID,
  clientId: process.env.AWS_COGNITO_CLIENT_ID,
  clientSecret: process.env.AWS_COGNITO_CLIENT_SECRET,
};

// Create Cognito client
export const cognitoClient = new CognitoIdentityProviderClient({
  region: cognitoConfig.region,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  },
});

// Validate required environment variables
export function validateCognitoConfig() {
  const requiredVars = [
    "AWS_REGION",
    "AWS_COGNITO_USER_POOL_ID",
    "AWS_COGNITO_CLIENT_ID",
    "AWS_COGNITO_CLIENT_SECRET",
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
  ];

  const missing = requiredVars.filter((varName) => !process.env[varName]);

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(", ")}`
    );
  }
}
