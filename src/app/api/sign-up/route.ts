import { createCognitoUser } from "@/helpers/sendVerificationEmail";
import dbConnect from "@/lib/dbConnect";
import UserModel from "@/model/User";
import bcrypt from "bcryptjs";

export async function POST(request: Request) {
  await dbConnect();

  try {
    const { username, email, password } = await request.json();

    // Check if username is already taken by a verified user in our database
    const existingVerifiedUserByUsername = await UserModel.findOne({
      username,
      isVerified: true,
    });

    if (existingVerifiedUserByUsername) {
      return Response.json(
        {
          success: false,
          message: "Username is already taken",
        },
        { status: 400 }
      );
    }

    // Check if email already exists and is verified in our database
    const existingUserByEmail = await UserModel.findOne({ email });
    if (existingUserByEmail && existingUserByEmail.isVerified) {
      return Response.json(
        {
          success: false,
          message: "User already exists with this email",
        },
        { status: 400 }
      );
    }

    // Check if username exists but is unverified (edge case handling)
    const existingUnverifiedUserByUsername = await UserModel.findOne({
      username,
      isVerified: false,
    });

    // Create user in Cognito first
    const cognitoResponse = await createCognitoUser(email, username, password);

    if (!cognitoResponse.success) {
      return Response.json(
        {
          success: false,
          message: cognitoResponse.message,
        },
        { status: 400 }
      );
    }

    // If Cognito user creation successful, create/update user in our database
    if (existingUserByEmail || existingUnverifiedUserByUsername) {
      // Update existing unverified user (by email or username)
      const userToUpdate =
        existingUserByEmail || existingUnverifiedUserByUsername;
      const hashedPassword = await bcrypt.hash(password, 10);

      userToUpdate!.password = hashedPassword;
      userToUpdate!.username = username;
      userToUpdate!.email = email;
      userToUpdate!.isVerified = false; // Will be verified through Cognito
      await userToUpdate!.save();
    } else {
      // Create new user in our database
      const hashedPassword = await bcrypt.hash(password, 10);

      const newUser = new UserModel({
        username,
        email,
        password: hashedPassword,
        isVerified: false, // Will be verified through Cognito
        isAcceptingMessages: true,
        messages: [],
      });

      await newUser.save();
    }

    return Response.json(
      {
        success: true,
        message: cognitoResponse.message,
      },
      { status: 201 }
    );
  } catch (error) {
    console.error("Error registering user:", error);
    return Response.json(
      {
        success: false,
        message: "Error registering user",
      },
      { status: 500 }
    );
  }
}
