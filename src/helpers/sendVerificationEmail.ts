import { cognitoClient, cognitoConfig, validateCognitoConfig, } from "@/lib/cognito";
import { ApiResponse } from "@/types/ApiResponse";
import { AdminGetUserCommand, ResendConfirmationCodeCommand, SignUpCommand, UserStatusType, } from "@aws-sdk/client-cognito-identity-provider";
import crypto from "crypto";

// Helper function to calculate SECRET_HASH
function calculateSecretHash(username: string): string {
  return crypto
    .createHmac("SHA256", cognitoConfig.clientSecret!)
    .update(username + cognitoConfig.clientId)
    .digest("base64");
}

export async function createCognitoUser(
  email: string,
  username: string,
  password: string
): Promise<ApiResponse> {
  try {
    // Validate Cognito configuration
    validateCognitoConfig();

    // Use SignUp command for proper self-registration with email verification
    const signUpCommand = new SignUpCommand({
      ClientId: cognitoConfig.clientId,
      Username: username,
      Password: password,
      SecretHash: calculateSecretHash(username),
      UserAttributes: [
        {
          Name: "email",
          Value: email,
        },
      ],
    });

    const signUpResponse = await cognitoClient.send(signUpCommand);
    console.log("Cognito user signed up:", signUpResponse);

    return {
      success: true,
      message:
        "User registered successfully. Please check your email for the verification code.",
    };
  } catch (error: any) {
    console.error("Error creating Cognito user:", error);

    if (error.name === "UsernameExistsException") {
      // Check if user exists but is unverified
      try {
        const getUserCommand = new AdminGetUserCommand({
          UserPoolId: cognitoConfig.userPoolId,
          Username: username,
        });

        const userResponse = await cognitoClient.send(getUserCommand);

        // If user exists but is not confirmed, resend verification code
        if (userResponse.UserStatus === UserStatusType.UNCONFIRMED) {
          const resendResult = await resendVerificationEmail(username);
          if (resendResult.success) {
            return {
              success: true,
              message:
                "Account already exists but not verified. A new verification code has been sent to your email.",
            };
          } else {
            return {
              success: false,
              message:
                "Account exists but verification code could not be resent. Please try again later.",
            };
          }
        } else {
          // User exists and is confirmed
          return {
            success: false,
            message:
              "User already exists and is verified. Please sign in instead.",
          };
        }
      } catch (getUserError: any) {
        console.error("Error checking user status:", getUserError);
        return {
          success: false,
          message:
            "User already exists. Please try signing in or contact support.",
        };
      }
    }

    if (error.name === "InvalidPasswordException") {
      return {
        success: false,
        message: "Password does not meet requirements",
      };
    }

    return {
      success: false,
      message: `Failed to create user: ${error.message || "Unknown error"}`,
    };
  }
}

export async function resendVerificationEmail(
  username: string
): Promise<ApiResponse> {
  try {
    validateCognitoConfig();

    // Check user status first
    const getUserCommand = new AdminGetUserCommand({
      UserPoolId: cognitoConfig.userPoolId,
      Username: username,
    });

    try {
      const userResponse = await cognitoClient.send(getUserCommand);

      if (userResponse.UserStatus === UserStatusType.CONFIRMED) {
        return {
          success: false,
          message: "User is already verified",
        };
      }
    } catch (error: any) {
      if (error.name === "UserNotFoundException") {
        return {
          success: false,
          message: "User not found",
        };
      }
    }

    // Resend verification code
    const resendCodeCommand = new ResendConfirmationCodeCommand({
      ClientId: cognitoConfig.clientId,
      Username: username,
      SecretHash: calculateSecretHash(username),
    });

    await cognitoClient.send(resendCodeCommand);
    console.log("Verification email resent to user:", username);

    return {
      success: true,
      message: "Verification email has been resent",
    };
  } catch (error: any) {
    console.error("Error resending verification email:", error);
    return {
      success: false,
      message: `Failed to resend verification email: ${
        error.message || "Unknown error"
      }`,
    };
  }
}
