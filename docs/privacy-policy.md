# FinBalance Privacy Policy

**Effective Date:** November 2026  
**Application Version:** 1.0.0  
**Hosted URL:** [https://amruthlp.vercel.app/finbalance_policy](https://amruthlp.vercel.app/finbalance_policy)

FinBalance ("we", "our", or "the application") is committed to protecting your privacy. This Privacy Policy explains our principles and practices regarding the handling of your information when you use the FinBalance application on Android, Web, or desktop platforms.

FinBalance is engineered with a **local-first, privacy-by-design architecture**. Your personal financial portfolio records, profile configurations, and transaction history are stored entirely on your local device.

---

## 1. Introduction & Overview

FinBalance is a multi-profile personal finance management application that helps individuals and families track assets, liabilities, mutual funds, systematic investment plans (SIPs), cash flow, and overall net worth.

Unlike traditional cloud-based financial services that require personal registration and store sensitive financial details on external remote servers, FinBalance operates directly on your device. We believe your financial data belongs exclusively to you.

---

## 2. Information We Collect

**We do not collect, harvest, store, or transmit any personal financial data or identifiers.**

Specifically:
- **No Personal Identifiers:** We do not collect your name, phone number, email address, physical address, PAN, Aadhaar, bank account numbers, or government IDs.
- **No Financial Account Credentials:** FinBalance does not connect to bank accounts via screen scraping, Open Banking APIs, or SMS reading.
- **No Analytics or Telemetry:** FinBalance does not include third-party analytics SDKs, user behavior tracking, session recording, or advertising trackers.
- **No Unique Device Identifiers:** We do not log or track device IDs (IMEI, advertising ID, MAC address).

Any financial figures, profile details, asset values, and transaction notes you enter into the application exist solely in your device's local application storage.

---

## 3. How We Store Your Data

All data entered into FinBalance is stored in a private, sandboxed **on-device local database** managed directly by your operating system.

- **Local Storage:** All profiles, financial items, holdings, investment schedules, cash flow records, and preferences reside locally within the application sandbox.
- **No Cloud Sync:** FinBalance does not operate remote database servers, cloud synchronization backends, or hosted user accounts.
- **Operating System Sandboxing:** Your application database is shielded by standard operating system sandboxing mechanisms (such as Android app sandboxing and browser origin boundaries), preventing unauthorized access from other applications on your device unless the device security is explicitly compromised.

---

## 4. Mutual Fund Market Data & Network Usage

FinBalance requires an active internet connection **exclusively** to fetch publicly available mutual fund market data.

To provide up-to-date valuations and scheme details:
- **Public Market Rates:** The application connects to public, AMFI-compliant mutual fund market data services to download daily Net Asset Value (NAV) updates and scheme master catalogs.
- **No Personal Data Sent:** When fetching market data, the application only requests public scheme identifiers (such as AMFI scheme codes). **Zero personal data, portfolio amounts, transaction histories, unit balances, or profile information are ever transmitted over the network.**
- **Local Offline Caching:** Fetched NAV rates and historical mutual fund data are cached in your local on-device database so that your portfolio valuation remains accessible offline.

---

## 5. Multi-Profile & Family Privacy

FinBalance supports multiple financial profiles to help users manage family members' finances independently.

- **Local Profile Isolation:** Each profile maintains its own isolated holdings, asset allocations, SIP schedules, and transactions within your device's local database.
- **Zero Inter-Profile Sharing Over Network:** Profiles are not linked across devices and are never synced to any server. Switching between profiles is entirely an on-device operation.

---

## 6. Third-Party Services & APIs

The only network requests initiated by FinBalance are directed to public market data services to retrieve mutual fund scheme lists and NAV figures.

- **No Advertising SDKs:** FinBalance contains zero advertisements, sponsored trackers, or marketing pixels.
- **No Crash Reporting Trackers:** The application does not send crash logs or diagnostic telemetry to remote servers without explicit manual action by the developer during local development.
- **Public AMFI Data Feeds:** All external data requests query public market data endpoints over secure HTTPS connections.

---

## 7. Security

We take the security of your financial records seriously:
- **Transport Security:** All network requests for public mutual fund NAV rates use encrypted HTTPS/TLS connections.
- **OS-Level Protection:** Your local database relies on your device's operating system security sandbox.
- **User Responsibility:** Because data is stored locally without external password gates, your device security is paramount. We strongly recommend protecting your device with a strong passcode, biometric authentication (fingerprint/face recognition), full-disk encryption, and keeping your operating system up to date.

---

## 8. Data Retention & Deletion

Because FinBalance stores all data locally on your device:
- **Full User Control:** You maintain complete control over data retention.
- **Record Deletion:** You can delete individual transactions, SIP schedules, mutual fund holdings, or entire profiles at any time from within the application interface.
- **Permanent Purge:** Deleting a profile or tapping "Clear All Data" in Settings permanently purges the respective records from your device's local database.
- **App Uninstall:** Uninstalling FinBalance completely removes the application and its local database from your device operating system. Because we do not maintain server backups, uninstalled data cannot be recovered by us.

---

## 9. Backup & Export

FinBalance provides local data export and backup utilities to allow you to safeguard your records:
- **Local File Control:** When you generate an export file or database backup, the file is saved directly to your local file system or shared storage destination chosen by you.
- **No Automatic Uploads:** Backup files are never automatically uploaded to any remote server or third-party cloud storage service. You retain full control over where backup files are stored and how they are transferred.

---

## 10. Children's Privacy

FinBalance is designed for general audiences and personal finance tracking. We do not knowingly target or collect any personal information from children under the age of 13. Because no personal data is collected or transmitted by the application, FinBalance complies with child privacy protections by default.

---

## 11. Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect application improvements, new features, or regulatory requirements. Any updates will be:
1. Reflected in this document with a revised "Effective Date".
2. Included in the application's in-app Privacy Policy screen.
3. Summarized in the application's release notes (`CHANGELOG.md`).

Continued use of FinBalance following policy updates signifies your acknowledgment and acceptance of the revised terms.

---

## 12. Governing Law & Compliance

FinBalance is developed in accordance with the principles of data minimization, local processing, and user consent set forth in:
- The **Information Technology Act, 2000** (India) and applicable amendments.
- The **Digital Personal Data Protection Act, 2023** (DPDP Act, India).

By confining all personal financial information to on-device processing and transmitting zero user identifiers, FinBalance inherently adheres to privacy-by-design standards.

---

## 13. Open Source & Transparency

FinBalance is built with transparency and user trust at its core. We are committed to verifiable, local-first operation. The application's architecture, data access patterns, and API interactions are auditable in the project codebase.

---

## 14. Contact Information

If you have questions, feedback, or inquiries regarding this Privacy Policy or FinBalance's local-first architecture, please contact:

- **Developer:** Amruth L P
- **Email:** `privacy@amruthlp.vercel.app`
- **Developer Portfolio:** [https://amruthlp.vercel.app](https://amruthlp.vercel.app)
- **Policy URL:** [https://amruthlp.vercel.app/finbalance_policy](https://amruthlp.vercel.app/finbalance_policy)

---

## 15. Effective Date & Version

- **Effective Date:** November 2026
- **Version:** 1.0.0

