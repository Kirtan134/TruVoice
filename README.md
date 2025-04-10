## Deployment

To access deployment-related configurations and manifests, switch to the `deployments` branch:

```bash
git checkout deployment
```

👉 [Go to the deployment branch](https://github.com/Kirtan134/TruVoice/tree/deployment)


# TruVoice

### The World of Anonymous Feedback

TruVoice - Where your identity remains a secret. Now with the power of AI.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction

TruVoice is an innovative platform designed to allow users to give and receive anonymous feedback. With the integration of AI, users can generate thoughtful and constructive feedback easily. Whether authenticated or not, users can provide feedback securely and anonymously.

## Features

- **Anonymous Feedback:** Receive feedback from others while keeping your identity secret.
- **Email Authentication:** Authenticate via email using OTP for secure feedback receipt.
- **AI-Generated Feedback:** Use Gemini AI to generate feedback messages.
- **Cross-Platform:** Fully responsive design for both desktop and mobile devices.

## Tech Stack

TruVoice is built using the following technologies:

- **Frontend:** Next.js, ShadCN
- **Backend:** Next.js API routes
- **Database:** MongoDB
- **Authentication:** Next-Auth, Auth.js, JWT tokens
- **Validation:** Zod
- **Email Services:** Nodemailer, Gmail API
- **AI Integration:** Gemini AI

## Installation

To get a local copy up and running, follow these simple steps:

1. Clone the repo
   ```sh
   git clone https://github.com/Kirtan134/TruVoice.git
   ```
2. Install NPM packages
   ```sh
   npm install
   ```
3. Set up environment variables
   - Create a `.env` file in the root directory
   - Add your MONGODB_URI, NEXTAUTH_SECRET, GEMINI_API_KEY, CLIENT_ID,  CLIENT_SECRET, REDIRECT_URI, REFRESH_TOKEN and other necessary credentials

4. Run the development server
   ```sh
   npm run dev
   ```

## Usage

1. **Authentication:**
   - Sign up with your email.
   - Verify your email using the OTP sent to your inbox.

2. **Giving Feedback:**
   - Choose to authenticate or give feedback anonymously.
   - Use Gemini AI to generate feedback messages if needed.
   - Submit your feedback.

3. **Receiving Feedback:**
   - Receive feedback anonymously.
   - Manage your feedback through the user dashboard.

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

---

