import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web3dart/credentials.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'Successpage.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final storage = FlutterSecureStorage();
  String? did;
  List<String> shards = [];
  String statusMessage = "";
  String? encryptionKey;
  TextEditingController keyController = TextEditingController();

  encrypt.Key? aesKey;
  final iv = encrypt.IV.fromLength(16);

  String generateEncryptionKey() {
    const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    Random rnd = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(16, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  String encryptData(String data, String encryptionKey) {
    aesKey = encrypt.Key.fromUtf8(encryptionKey);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey!));
    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedData, String userKey) {
    try {
      final userAesKey = encrypt.Key.fromUtf8(userKey);
      final encrypter = encrypt.Encrypter(encrypt.AES(userAesKey));
      final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception("Invalid encryption key or corrupted data.");
    }
  }

  Future<void> generateDID() async {
    try {
      var rng = Random.secure();

      // Generate a smaller random private key (e.g., 128 bits / 16 bytes)
      List<int> privateKeyBytes = List.generate(16, (index) => rng.nextInt(256));

      // Create the EthPrivateKey from the smaller key
      EthPrivateKey privateKey = EthPrivateKey.fromHex(privateKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join());

      EthereumAddress address = await privateKey.extractAddress();

      did = "did:ethr:${address.hex}";

      await storage.write(key: 'user_did', value: did);

      setState(() {
        statusMessage = "DID generated: $did";
      });
    } catch (e) {
      print(e);
      setState(() {
        statusMessage = "Error generating DID.";
      });
    }
  }

  List<String> shardData(String encryptedData, int numberOfShards) {
    List<String> shards = [];
    int shardSize = (encryptedData.length / numberOfShards).ceil();

    for (int i = 0; i < numberOfShards; i++) {
      int start = i * shardSize;
      int end = start + shardSize;
      if (end > encryptedData.length) {
        end = encryptedData.length;
      }
      shards.add(encryptedData.substring(start, end));
    }

    return shards;
  }

  Future<String> saveShardLocally(String shard, int index) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/shard_$index.txt');
      await file.writeAsString(shard);

      print("Shard saved locally: ${file.path}");
      return file.path;
    } catch (e) {
      print("Error saving shard locally: $e");
      throw Exception("Failed to save shard locally.");
    }
  }

  Future<void> authenticateUser() async {
    try {
      String? storedDID = await storage.read(key: 'user_did');
      if (storedDID == null) {
        setState(() {
          statusMessage = "No DID found, generate DID first.";
        });
        return;
      }

      print("Stored DID: $storedDID");

      String reassembledEncryptedData = shards.join();
      print("Reassembled Encrypted Data: $reassembledEncryptedData");

      String userInputKey = keyController.text;

      print("User Input Key: $userInputKey");
      print("Original Encryption Key: $encryptionKey");

      try {
        String decryptedData = decryptData(reassembledEncryptedData, userInputKey);

        setState(() {
          statusMessage = "Reassembled and decrypted data: $decryptedData";
        });

        bool isAuthenticated = verifyUser(storedDID, decryptedData);
        setState(() {
          statusMessage = isAuthenticated
              ? "Authentication successful!"
              : "Authentication failed!";
        });

        if (isAuthenticated) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SuccessPage()),
          );
        }
      } catch (e) {
        print("Decryption failed: $e");
        setState(() {
          statusMessage = "Decryption failed. Incorrect key.";
        });
      }
    } catch (e) {
      print("Error during authentication: $e");
      setState(() {
        statusMessage = "Error during authentication.";
      });
    }
  }

  bool verifyUser(String did, String data) {
    return data.contains(did);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'DID Authentication',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white
            ),
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 600,
              padding: EdgeInsets.symmetric(vertical: 50, horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Decentralized Authentication",
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: generateDID,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Generate DID",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          String? storedDID = await storage.read(key: 'user_did');
                          if (storedDID == null) {
                            setState(() {
                              statusMessage = "No DID found. Please generate DID first.";
                            });
                            return;
                          }

                          String userData = "Sensitive user authentication data. DID: $storedDID";

                          encryptionKey = generateEncryptionKey();
                          String encryptedData = encryptData(userData, encryptionKey!);

                          shards = shardData(encryptedData, 3);
                          setState(() {
                            statusMessage = "Data encrypted and sharded into 3 parts.\nEncryption Key: $encryptionKey";
                          });

                          for (int i = 0; i < shards.length; i++) {
                            String filePath = await saveShardLocally(shards[i], i);
                            print("Shard saved locally at: $filePath");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Encrypt, Shard, and Save Data Locally",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 30),
                      Container(
                        width: 400,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 5,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: keyController,
                          decoration: InputDecoration(
                            labelText: "Enter Encryption Key",
                            labelStyle: TextStyle(color: Colors.black54, fontSize: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: authenticateUser,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Authenticate User",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        statusMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: statusMessage.contains('Error') ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF743ac5), Color(0xFF4a00e0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Authentify',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 50),
                      Text(
                        'A Robust and Secure Decentralized Authentication System for the Next Generation of Digital Identity Verification',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
