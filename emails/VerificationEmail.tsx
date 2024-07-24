import {
  Html,
  Head,
  Font,
  Preview,
  Heading,
  Row,
  Section,
  Text,
} from '@react-email/components';

interface VerificationEmailProps {
  username: string;
  otp: string;
}

export default function VerificationEmail({ username, otp }: VerificationEmailProps) {
  return (
    <Html lang="en" dir="ltr">
      <Head>
        <title>Verification Code</title>
        <Font
          fontFamily="Roboto"
          fallbackFontFamily="Verdana"
          webFont={{
            url: 'https://fonts.gstatic.com/s/roboto/v27/KFOmCnqEu92Fr1Mu4mxKKTU1Kg.woff2',
            format: 'woff2',
          }}
          fontWeight={400}
          fontStyle="normal"
        />
      </Head>
      <Preview>Here's your verification code: {otp}</Preview>
      <Section style={{ padding: '20px', fontFamily: 'Roboto, Verdana' }}>
        <Row>
          <Heading as="h2" style={{ fontSize: '24px', marginBottom: '10px' }}>
            Hello {username},
          </Heading>
        </Row>
        <Row>
          <Text style={{ fontSize: '16px', marginBottom: '10px' }}>
            Thank you for registering. Please use the following verification
            code to complete your registration:
          </Text>
        </Row>
        <Row>
          <Text style={{ fontSize: '20px', fontWeight: 'bold', marginBottom: '10px' }}>
            {otp}
          </Text> 
        </Row>
        <Row>
          <Text style={{ fontSize: '16px', marginBottom: '20px' }}>
            If you did not request this code, please ignore this email.
          </Text>
        </Row>
      </Section>
    </Html>
  );
}
