// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9; 

// 定义一个名为Bank的智能合约
contract Bank {
    // 1. 状态变量：存储合约核心数据
    address public immutable admin; 
    mapping(address => uint) public deposits; // 
    address[3] public topDepositors; 
    
    // 2. 构造函数：合约部署时自动执行，初始化管理员
    constructor() {
        admin = msg.sender; 
    }

    // 3. 存款函数：接收ETH并存入用户账户
    // receive()是Solidity的特殊函数，用于接收直接发送到合约的ETH（无参数）
    receive() external payable {
        _addDeposit(); 
    }

    // 显式存款函数：用户主动调用存入ETH
    function deposit() external payable {
        _addDeposit(); 
    }

    // 内部函数：处理存款逻辑（封装重复代码，提高可维护性）
    function _addDeposit() internal {
        // 更新用户存款金额（原金额 + 本次转入金额）
        deposits[msg.sender] += msg.value;
        
        // 更新前3名存款人列表（调用单独的函数，分离核心逻辑）
        _updateTop3Depositors(msg.sender);
    }

    // 更新前3名存款人：核心逻辑（新手可重点看这里）
    function _updateTop3Depositors(address newUser) internal {
        uint newUserBalance = deposits[newUser]; 
        
        // 步骤1：如果用户已在Top3中，直接调整排名（简化版：先移除再插入）
        for (uint8 i = 0; i < 3; i++) {
            if (topDepositors[i] == newUser) {
                // 将该用户从当前位置移除（用最后一个元素填充空位）
                for (uint8 j = i; j < 2; j++) {
                    topDepositors[j] = topDepositors[j + 1];
                }
                topDepositors[2] = address(0); 
                
                // 插入到正确位置（从后往前比较，确保顺序）
                for (uint8 j = 2; j > 0; j--) {
                    if (newUserBalance > deposits[topDepositors[j - 1]]) {
                        topDepositors[j] = topDepositors[j - 1];
                    } else {
                        break;
                    }
                }
                topDepositors[j] = newUser; 
                return; 
            }
        }
        
        // 步骤2：如果用户不在Top3中，检查是否需要加入（替换第3名）
        for (uint8 i = 0; i < 3; i++) {
            if (topDepositors[i] == address(0) || // 如果位置为空
                newUserBalance > deposits[topDepositors[i]]) { // 或新用户金额更大
                // 将新用户插入到当前位置，并将后面的元素向后移动
                for (uint8 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j - 1];
                }
                topDepositors[i] = newUser;
                return; 
            }
        }
    }

    // 获取前3名存款人及金额：视图函数（不消耗gas，仅读取数据）
    function getTopDepositors() external view returns (address[3] memory, uint[3] memory) {
        uint[3] memory amounts; 
        for (uint8 i = 0; i < 3; i++) {
            amounts[i] = deposits[topDepositors[i]]; 
        }
        return (topDepositors, amounts); 
    }

    // 提现函数：仅管理员可调用，提取合约中的所有ETH
    function withdraw() external {
        // 1. 检查调用者是否为管理员（权限控制）
        require(msg.sender == admin, "只有管理员可以提现");
        
        // 2. 获取合约余额（当前存储的ETH总额）
        uint balance = address(this).balance;
        
        // 3. 检查是否有余额可提（避免无效操作）
        require(balance > 0, "合约中没有ETH可提现");
        
        // 4. 将ETH转给管理员（call方式发送，兼容所有情况）
        (bool success, ) = admin.call{value: balance}(""); 
        require(success, "提现失败，请检查管理员地址或网络状态");
    }
}
