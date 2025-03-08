# Authentify

Overview

This project aims to overcome the vulnerabilities of centralized authentication systems by implementing a decentralized authentication mechanism using Decentralized Identifiers (DIDs). By eliminating a single point of failure, this solution enhances security, privacy, and resilience against breaches.

How It Works

1.DID Generation – A unique Decentralized Identifier (DID) is generated for each user.

2.Encryption & Sharding – The DID is encrypted and broken into multiple shards, which are stored locally.

3.Authentication via Encryption Key – An encryption key is formed, and when entered correctly, it reconstructs and verifies the DID for authentication.

Features

Decentralized Authentication – Eliminates single points of failure.

Local Storage Security – Sensitive data remains with the user, reducing attack risks.

Strong Encryption – Ensures secure identity management.

Resilience Against Breaches – Compromising a single shard does not expose the entire authentication system.

Installation & Setup

Clone the repository:

git clone https://github.com/Parth7039/Athentify.git

In terminal:
flutter run

Usage

Create a new DID.

Encrypt and store the shards securely.

Use the encryption key to authenticate when required.

Security Considerations

Ensure shards are stored in secure locations.

Use strong encryption methods to protect the DID.

Regularly update encryption algorithms to maintain security.

Contributing

Contributions are welcome! Feel free to submit issues, feature requests, or pull requests.


For more details, reach out to [p.k.bhamare07@gmail.com].
