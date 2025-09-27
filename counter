// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint public counter; // 状态变量：存储计数值

    // 构造函数：合约部署时初始化counter为0
    constructor() {
        counter = 0;
    }

    // get()方法：读取counter当前值（只读函数，无需消耗gas）
    function get() public view returns (uint) {
        return counter;
    }

    // add(x)方法：给counter加上x（修改状态，需消耗gas）
    function add(uint x) public {
        counter += x;
    }
}
