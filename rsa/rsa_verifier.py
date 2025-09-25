from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization
from cryptography.exceptions import InvalidSignature

def verify_signature(public_key_path, data_to_verify, data_hash, signature):
    """使用公钥验证签名"""
    with open(public_key_path, "rb") as f:
        public_key = serialization.load_pem_public_key(f.read())
    try:
        public_key.verify(
            signature,
            data_hash.encode("utf-8"),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        print("✅ 签名验证成功：数据未被篡改！")
        return True
    except InvalidSignature:
        print("❌ 签名验证失败：数据可能被篡改！")
        return False

if __name__ == "__main__":
    public_key_path = "public.pem"
    data_to_verify = "user12312345"  
    data_hash = "0000a1b2c3d4..."    
    signature = bytes.fromhex("ABC123...")  
    verify_signature(public_key_path, data_to_verify, data_hash, signature)