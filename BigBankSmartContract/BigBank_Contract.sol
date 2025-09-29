// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/​**​
 * @title IBank - 银行基础功能接口
 * @notice 定义了银行合约的核心操作：存款、查询前3名存款人、取款
 */
interface IBank {
    // 用户存钱（外部调用，可发送ETH）
    function deposit() external payable;
    // 查看前3名存款人及金额（只读，不消耗gas）
    function getTopDepositors() external view returns (address[3] memory, uint[3] memory);
    // 用户取回自己的钱（外部调用）
    function withdraw() external;
}

import "./IBank.sol";

/​**​
 * @title Bank - 基础银行合约
 * @notice 实现IBank接口，提供存款、取款、前3名查询功能
 */
contract Bank is IBank {
    // 管理员地址（部署者默认是管理员）
    address public admin; 
    // 记录每个用户的存款金额（地址 => 金额）
    mapping(address => uint) public deposits;
    // 存储前3名存款人的地址（固定长度数组，索引0为最高）
    address[3] public topDepositors;
    // 前3名的数量（常量，不可修改）
    uint8 private constant TOP_COUNT = 3;
    
    /​**​
     * @dev 构造函数：部署时设置部署者为管理员
     */
    constructor() {
        admin = msg.sender; // msg.sender是当前调用者（部署者）的地址
    }

    /​**​
     * @dev 接收ETH并记录存款（自动调用，如他人直接转账给合约）
     */
    receive() external payable virtual { 
        _handleDeposit();
    }

    /​**​
     * @dev 用户主动调用存钱函数（需发送ETH）
     */
    function deposit() external payable virtual {
        _handleDeposit();
    }

    /​**​
     * @dev 内部函数：统一处理存款逻辑（避免重复代码）
     */
    function _handleDeposit() internal {
        deposits[msg.sender] += msg.value; // 更新用户存款（当前用户地址的余额 += 转入金额）
        updateTopDepositors(msg.sender);   // 检查是否需要更新前3名
    }

    /​**​
     * @dev 内部函数：更新前3名存款人列表
     * @param depositor 当前存款用户地址
     */
    function updateTopDepositors(address depositor) internal {
        uint userBalance = deposits[depositor];
        
        // 情况1：用户已在Top3中，调整位置（冒泡排序简化版）
        for (uint8 i = 0; i < TOP_COUNT; i++) {
            if (topDepositors[i] == depositor) {
                _reorderTop(i, userBalance); // 调用内部函数重新排序
                return;
            }
        }
        
        // 情况2：用户不在Top3中，检查是否需要加入（从后往前找空位）
        for (uint8 i = 0; i < TOP_COUNT; i++) {
            // 如果当前位置为空（address(0)）或用户金额更大，则插入
            if (topDepositors[i] == address(0) || userBalance > deposits[topDepositors[i]]) {
                _insertIntoTop(i, depositor, userBalance); // 调用内部函数插入
                break;
            }
        }
    }

    /​**​
     * @dev 内部函数：将用户插入Top3并调整顺序（从后往前移动元素）
     * @param index 插入位置索引
     * @param depositor 用户地址
     * @param balance 用户存款金额
     */
    function _insertIntoTop(uint8 index, address depositor, uint balance) internal {
        // 从后往前移动元素，为新用户腾位置（如index=1，则topDepositors[2]移到topDepositors[1]）
        for (uint8 j = TOP_COUNT - 1; j > index; j--) {
            topDepositors[j] = topDepositors[j - 1];
        }
        topDepositors[index] = depositor; // 插入新用户到指定位置
    }

    /​**​
     * @dev 内部函数：重新排序Top3（冒泡排序简化版）
     * @param startIndex 开始排序的索引
     * @param newBalance 新用户的存款金额
     */
    function _reorderTop(uint8 startIndex, uint newBalance) internal {
        for (uint8 i = startIndex + 1; i < TOP_COUNT; i++) {
            // 如果后面的用户金额更大，则交换位置（保持Top3降序）
            if (deposits[topDepositors[i]] > newBalance) {
                address temp = topDepositors[i];
                topDepositors[i] = topDepositors[startIndex];
                topDepositors[startIndex] = temp;
                startIndex = i; // 继续向后检查（可能还有更大的金额）
            } else {
                break; // 如果后面的金额更小，停止排序
            }
        }
    }

    /​**​
     * @dev 查看前3名存款人及金额（只读函数，不消耗gas）
     * @return addresses 前3名存款人地址数组
     * @return amounts 前3名存款人金额数组（与addresses一一对应）
     */
    function getTopDepositors() external view returns (address[3] memory addresses, uint[3] memory amounts) {
        // 遍历Top3数组，获取每个地址的存款金额
        for (uint8 i = 0; i < TOP_COUNT; i++) {
            amounts[i] = deposits[topDepositors[i]]; // 获取topDepositors[i]对应的存款金额
        }
        return (topDepositors, amounts); // 返回地址数组和金额数组
    }

    /​**​
     * @dev 管理员提取合约中的所有ETH（仅管理员可调用）
     */
    function withdraw() external {
        require(msg.sender == admin, "只有管理员能取款"); // 权限检查（确保调用者是管理员）
        uint balance = address(this).balance; // 获取合约当前余额（ETH数量）
        require(balance > 0, "合约没有余额可取"); // 防止无效操作（余额为0时不执行）
        
        // 调用call方法转账（最通用的转账方式，支持ETH转账）
        (bool success, ) = admin.call{value: balance}("");
        require(success, "转账失败"); // 确保转账成功（call返回true表示成功）
    }
}

import "./Bank.sol";

/​**​
 * @title BigBank - 升级版银行合约
 * @notice 继承Bank合约，添加最低存款金额限制和管理员变更功能
 */
contract BigBank is Bank {
    // 合约的真正所有者（不可修改，部署者默认是owner）
    address public immutable owner;

    /​**​
     * @dev 构造函数：部署时设置部署者为owner
     */
    constructor() {
        owner = msg.sender; // msg.sender是当前调用者（部署者）的地址
    }

    /​**​
     * @dev 存款金额限制（Modifier）：确保存款金额大于0.001 ETH
     * @notice 使用modifier简化权限检查，避免重复代码
     */
    modifier depositAmountGreaterThan001() {
        require(msg.value > 0.001 ether, "存款金额必须大于0.001 ETH"); // ETH单位用ether表示（1 ETH = 10^18 wei）
        _; // 继续执行后续代码（即调用deposit函数）
    }

    /​**​
     * @dev 重写deposit函数，添加金额限制（用户主动调用）
     */
    function deposit() external payable override depositAmountGreaterThan001 {
        _handleDeposit(); // 调用父合约的存款逻辑（继承自Bank）
    }

    /​**​
     * @dev 重写receive函数，添加金额限制（接收转账）
     */
    receive() external payable override {
        require(msg.value > 0.001 ether, "存款金额必须大于0.001 ETH");
        _handleDeposit(); // 调用父合约的存款逻辑
    }

    /​**​
     * @dev 变更管理员（只有owner可以调用）
     * @param newAdmin 新管理员地址
     */
    function changeAdmin(address newAdmin) external {
        require(msg.sender == owner, "只有owner能变更管理员"); // 权限检查（确保调用者是owner）
        require(newAdmin != address(0), "新管理员不能是零地址"); // 防止无效地址（address(0)是无效地址）
        admin = newAdmin; // 更新管理员地址
    }
}

import "./IBank.sol";

/​**​
 * @title Admin - 银行管理员合约
 * @notice 用于安全地管理Bank合约的资金，避免直接调用Bank的withdraw函数
 */
contract Admin {
    // 合约的真正管理员（不可修改，部署者默认是admin）
    address public immutable admin;
    
    /​**​
     * @dev 构造函数：部署时设置部署者为管理员
     */
    constructor() {
        admin = msg.sender; // msg.sender是当前调用者（部署者）的地址
    }

    /​**​
     * @dev 接收ETH（用于接收Bank合约转来的资金）
     */
    receive() external payable {}

    /​**​
     * @dev 管理员调用此函数，让Bank合约提取自己的资金
     * @param bank Bank合约地址（需实现IBank接口）
     */
    function adminWithdraw(IBank bank) external {
        require(msg.sender == admin, "只有管理员能操作"); // 权限检查（确保调用者是admin）
        bank.withdraw(); // 调用Bank合约的withdraw函数（通过接口调用）
    }

    /​**​
     * @dev Admin合约的管理员提取自己的ETH（从Admin合约余额中转出）
     */
    function withdrawToOwner() external {
        require(msg.sender == admin, "只有管理员能取款");
        uint balance = address(this).balance; // 获取Admin合约当前余额
        require(balance > 0, "合约没有余额可取");
        (bool success, ) = admin.call{value: balance}("");
        require(success, "转账失败"); // 确保转账成功
    }
}
