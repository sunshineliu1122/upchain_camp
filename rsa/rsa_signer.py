from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization

def sign_data(private_key_path, data_hash):
    with open(private_key_path, "rb") as f:
        private_key = serialization.load_pem_private_key(
            f.read(),
            password=None
        )
    signature = private_key.sign(
        data_hash.encode("utf-8"),
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH
        ),
        hashes.SHA256()
    )
    print(f"签名（Base64）: {signature.hex()}")
    return signature

if __name__ == "__main__":
    private_key_path = "private.pem"
    data_hash = "0000a1b2c3d4..." 
    sign_data(private_key_path, data_hash)