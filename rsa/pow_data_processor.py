import hashlib

def process_data_with_pow(nickname):
    nonce = 0
    while True:
        data = f"{nickname}{nonce}"
        hash_hex = hashlib.sha256(data.encode("utf-8")).hexdigest()
        if hash_hex.startswith("0000"):
            return data, hash_hex
        nonce += 1

if __name__ == "__main__":
    nickname = "user123"
    data, data_hash = process_data_with_pow(nickname)
    print(f"待签名数据: {data}")
    print(f"数据哈希（前四位0000）: {data_hash}")