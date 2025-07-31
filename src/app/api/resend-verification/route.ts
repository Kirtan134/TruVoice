import { resendVerificationEmail } from "@/helpers/sendVerificationEmail";

export async function POST(request: Request) {
  try {
    const { username } = await request.json();

    if (!username) {
      return Response.json(
        {
          success: false,
          message: "Username is required",
        },
        { status: 400 }
      );
    }

    const result = await resendVerificationEmail(username);

    return Response.json(
      {
        success: result.success,
        message: result.message,
      },
      { status: result.success ? 200 : 400 }
    );
  } catch (error) {
    console.error("Error resending verification email:", error);
    return Response.json(
      {
        success: false,
        message: "Error resending verification email",
      },
      { status: 500 }
    );
  }
}
