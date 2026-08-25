from fastapi import APIRouter
from fastapi.responses import HTMLResponse


router = APIRouter(tags=["Legal"])


@router.get("/privacy-policy", response_class=HTMLResponse, include_in_schema=False)
def privacy_policy() -> str:
    return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>SafeColony AI - Privacy Policy</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 900px;
            margin: 0 auto;
            padding: 24px;
            color: #222;
            background: #fff;
        }
        h1, h2 { color: #17324d; }
        h1 { margin-bottom: 8px; }
        .updated { color: #666; margin-bottom: 28px; }
        section { margin-bottom: 24px; }
    </style>
</head>
<body>
    <h1>SafeColony AI - Privacy Policy</h1>
    <p class="updated"><strong>Last Updated: August 25, 2026</strong></p>

    <section>
        <h2>1. About SafeColony</h2>
        <p>
            SafeColony AI is a residential community management application that
            helps communities manage residents, properties, maintenance, security,
            communication, services, visitors, deliveries, amenities and marketplace
            activities.
        </p>
    </section>

    <section>
        <h2>2. Information We Collect</h2>
        <p>Depending on the features you use, SafeColony may collect:</p>
        <ul>
            <li>Full name</li>
            <li>Email address</li>
            <li>Mobile phone number</li>
            <li>Account and authentication information</li>
            <li>Community, block/section and unit information</li>
            <li>Resident and household information provided by you or your community administrator</li>
            <li>Maintenance, utility, payment and transaction information</li>
            <li>Complaints, service requests, incidents and community communications</li>
            <li>Visitor and delivery information</li>
            <li>Amenity bookings and marketplace information</li>
            <li>Notification and device information needed to deliver notifications</li>
            <li>Technical, diagnostic and application activity information required to operate and secure the service</li>
        </ul>
    </section>

    <section>
        <h2>3. How We Use Information</h2>
        <p>We use information to:</p>
        <ul>
            <li>Create and manage user accounts</li>
            <li>Authenticate users and verify email addresses</li>
            <li>Provide community management functionality</li>
            <li>Manage maintenance, utility and service requests</li>
            <li>Manage visitors, deliveries and security activities</li>
            <li>Support amenities and marketplace functionality</li>
            <li>Process and maintain payment-related records where applicable</li>
            <li>Send account, security and community notifications</li>
            <li>Provide customer support</li>
            <li>Maintain application security and prevent misuse</li>
            <li>Improve application reliability and functionality</li>
        </ul>
    </section>

    <section>
        <h2>4. Email and Authentication Communications</h2>
        <p>
            We may use your email address to send account verification emails,
            password reset emails, authentication-related messages and important
            service communications.
        </p>
    </section>

    <section>
        <h2>5. How Information Is Shared</h2>
        <p>
            SafeColony does not sell your personal information. Information may be
            made available to authorized community administrators and other users
            according to their roles and permissions when required to provide
            community functionality.
        </p>
        <p>
            We may also use service providers for hosting, databases, email delivery,
            notifications, payment processing and other infrastructure required to
            operate SafeColony. These providers may process information on our behalf.
        </p>
        <p>
            We may disclose information when required by applicable law or when
            reasonably necessary to protect the security, rights or property of
            SafeColony, its users or the community.
        </p>
    </section>

    <section>
        <h2>6. Data Security</h2>
        <p>
            We use reasonable technical and organizational measures to protect
            information against unauthorized access, alteration, disclosure or
            destruction. No internet-based service can guarantee absolute security.
        </p>
    </section>

    <section>
        <h2>7. Data Retention</h2>
        <p>
            We retain information for as long as necessary to provide the service,
            maintain appropriate account and transaction records, comply with legal
            obligations, resolve disputes and enforce applicable agreements.
        </p>
    </section>

    <section>
        <h2>8. Account and Data Deletion</h2>
        <p>
            Users may request deletion of their SafeColony account and associated
            personal information by contacting the SafeColony administrator through
            the support/contact information provided in the application.
        </p>
        <p>
            Some information may need to be retained where required for legal,
            security, accounting or legitimate operational purposes.
        </p>
    </section>

    <section>
        <h2>9. Children's Privacy</h2>
        <p>
            SafeColony is a general residential community management application and
            is not specifically directed toward children. We do not knowingly collect
            personal information from children for purposes prohibited by applicable law.
        </p>
    </section>

    <section>
        <h2>10. Third-Party Services</h2>
        <p>
            SafeColony may use third-party services for cloud hosting, database
            infrastructure, email delivery, authentication, notifications, payment
            processing and application infrastructure. Their processing is subject
            to their respective terms and privacy policies.
        </p>
    </section>

    <section>
        <h2>11. Changes to This Privacy Policy</h2>
        <p>
            We may update this Privacy Policy from time to time. The updated version
            will be published at this URL with a revised "Last Updated" date.
        </p>
    </section>

    <section>
        <h2>12. Contact</h2>
        <p>
            For privacy questions, account deletion requests or other privacy-related
            requests, please use the SafeColony support/contact information provided
            within the application.
        </p>
    </section>
</body>
</html>
"""
