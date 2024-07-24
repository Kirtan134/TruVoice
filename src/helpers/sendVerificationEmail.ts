import nodemailer from 'nodemailer';
import { google } from 'googleapis';
import VerificationEmail from "../../emails/VerificationEmail";
import { render } from '@react-email/render';
import { ApiResponse } from '@/types/ApiResponse';

const { OAuth2 } = google.auth;

const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;
const REDIRECT_URI = process.env.REDIRECT_URI;
const REFRESH_TOKEN = process.env.REFRESH_TOKEN;

const oAuth2Client = new OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);
oAuth2Client.setCredentials({ refresh_token: REFRESH_TOKEN });

export async function sendVerificationEmail(email: string, username: string, verifyCode: string): Promise<ApiResponse> {
  try {
    console.log("Sending verification email to", email);

    const accessTokenResponse = await oAuth2Client.getAccessToken();
    if (!accessTokenResponse.token) {
      throw new Error("Failed to retrieve access token");
    }
    const accessToken = accessTokenResponse.token;
   const myEmail = process.env.EMAIL
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        type: 'OAuth2',
        user: myEmail,
        clientId: CLIENT_ID,
        clientSecret: CLIENT_SECRET,
        refreshToken: REFRESH_TOKEN,
        accessToken: accessToken,
      },
    });

    const mailOptions = {
      from: 'TruVoice <myEmail>',
      to: email,
      subject: 'TruVoice - Verification Code',
      html: render(VerificationEmail({ username, otp: verifyCode })),
    };

    await transporter.sendMail(mailOptions);

    return {
      success: true,
      message: "Verification email sent",
    };
  } catch (e) {
    console.error("Error sending verification email", e);
    return {
      success: false,
      message: "Error sending verification email",
    };
  }
}
