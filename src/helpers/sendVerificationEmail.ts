import { ApiResponse } from "@/types/ApiResponse";
import { render } from "@react-email/render";
import { Resend } from "resend";
import VerificationEmail from "../../emails/VerificationEmail";

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendVerificationEmail(
  email: string,
  username: string,
  verifyCode: string
): Promise<ApiResponse> {
  try {
    console.log("Sending verification email to", email);

    if (!process.env.RESEND_API_KEY) {
      throw new Error("RESEND_API_KEY is not configured");
    }

    const emailResponse = await resend.emails.send({
      from: "TruVoice <onboarding@resend.dev>",
      to: email,
      subject: "TruVoice - Verification Code",
      html: render(VerificationEmail({ username, otp: verifyCode })),
    });

    if (emailResponse.error) {
      throw new Error(`Resend error: ${emailResponse.error.message}`);
    }

    console.log("Email sent successfully via Resend:", emailResponse.data?.id);

    return {
      success: true,
      message: "Verification email sent successfully",
    };
  } catch (e) {
    console.error("Error sending verification email:", e);

    const errorMessage =
      e instanceof Error ? e.message : "Unknown error occurred";

    return {
      success: false,
      message: `Email sending failed: ${errorMessage}`,
    };
  }
}
