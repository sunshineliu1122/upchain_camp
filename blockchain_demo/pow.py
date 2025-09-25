import hashlib
import time

def mine_pow(nickname, difficulty):
    target = '0' * difficulty  
    nonce = 0  
    start_time = time.time()  

    while True:
        content = f"{nickname}{nonce}"
        encoded_content = content.encode()
        hash_result = hashlib.sha256(encoded_content).hexdigest()
        if hash_result.startswith(target):
            end_time = time.time() 
            elapsed_time = end_time - start_time  
            print (f"找到{difficulty}个0开头的哈希值！")
            print (f"哈希值: {hash_result}")
            print (f"花费时间: {elapsed_time:.4f}秒")  
            return

        nonce += 1  

def main():
    nickname = input("请输入你的昵称（英文或中文都可以）: ").strip() 
    if not nickname:  
        print("昵称不能为空，请重新运行程序！")
        return

    print("\n=== 开始4个0开头的POW挑战 ===")
    mine_pow(nickname, 4)  

    print("\n=== 开始5个0开头的POW挑战 ===")
    mine_pow(nickname, 5) 

if __name__ == "__main__":
    main()