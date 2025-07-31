import {
  cognitoClient,
  cognitoConfig,
  validateCognitoConfig,
} from "@/lib/cognito";
import dbConnect from "@/lib/dbConnect";
import UserModel from "@/model/User";
import { ConfirmSignUpCommand } from "@aws-sdk/client-cognito-identity-provider";
import crypto from "crypto";

// Helper function to calculate SECRET_HASH
function calculateSecretHash(username: string): string {
  return crypto
    .createHmac("SHA256", cognitoConfig.clientSecret!)
    .update(username + cognitoConfig.clientId)
    .digest("base64");
}

export async function POST(request: Request) {
  try {
    await dbConnect();
    validateCognitoConfig();

    const { username, verificationCode } = await request.json();

    if (!username || !verificationCode) {
      return Response.json(
        {
          success: false,
          message: "Username and verification code are required",
        },
        { status: 400 }
      );
    }

    // Confirm user in Cognito with proper verification code validation
    const confirmCommand = new ConfirmSignUpCommand({
      ClientId: cognitoConfig.clientId,
      Username: username,
      ConfirmationCode: verificationCode,
      SecretHash: calculateSecretHash(username),
    });

    try {
      await cognitoClient.send(confirmCommand);
      console.log("User confirmed in Cognito:", username);

      // Update user verification status in our database
      const user = await UserModel.findOne({ username });
      if (user) {
        user.isVerified = true;
        await user.save();
      }

      return Response.json(
        {
          success: true,
          message: "Account verified successfully",
        },
        { status: 200 }
      );
    } catch (cognitoError: any) {
      console.error("Cognito verification error:", cognitoError);

      if (cognitoError.name === "CodeMismatchException") {
        return Response.json(
          {
            success: false,
            message: "Invalid verification code",
          },
          { status: 400 }
        );
      }

      if (cognitoError.name === "ExpiredCodeException") {
        return Response.json(
          {
            success: false,
            message: "Verification code has expired",
          },
          { status: 400 }
        );
      }

      if (cognitoError.name === "UserNotFoundException") {
        return Response.json(
          {
            success: false,
            message: "User not found",
          },
          { status: 404 }
        );
      }

      if (cognitoError.name === "NotAuthorizedException") {
        return Response.json(
          {
            success: false,
            message: "User is already verified",
          },
          { status: 400 }
        );
      }

      return Response.json(
        {
          success: false,
          message: `Verification failed: ${
            cognitoError.message || "Unknown error"
          }`,
        },
        { status: 500 }
      );
    }
  } catch (error) {
    console.error("Error verifying user:", error);
    return Response.json(
      {
        success: false,
        message: "Internal server error",
      },
      { status: 500 }
    );
  }
}
