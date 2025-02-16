# 💰 SmartContractCaPay - Salary Payment Management via Blockchain

This project is a Solidity smart contract that allows a company to schedule and execute employee salary payments using blockchain technology. It also ensures transaction tracking through an audit system.

## 🚀 Main Features

- Schedule salary payments for multiple employees.
- Automatically execute scheduled payments.
- Allow companies to supply funds.
- Track company and employee transactions.
- Verify and audit completed payments.

## 🛠️ Technologies Used

- **Language**: Solidity (`^0.8.26`)
- **IDE**: [Remix](https://remix.ethereum.org/)
- **Frameworks & Libraries**: No external dependencies
- **Blockchain**: Ethereum (or any EVM-compatible blockchain)

## 📂 Code Structure

- `SmartContractCaPay.sol`: Main contract for managing payments.
- `Employee.sol`: Imported file defining the employee structure.

## 📌 Prerequisites

Before running this project, make sure you have:

1. **A web browser** with **[Remix](https://remix.ethereum.org/)** to write, compile, and deploy the contract.
2. **An Ethereum wallet** like [MetaMask](https://metamask.io/) to interact with the contract.
3. **Testnet ETH funds** (if deployed on a testnet like Sepolia or Goerli).

## 🔧 Installation and Deployment

1. **Open Remix**: Go to [Remix Ethereum](https://remix.ethereum.org/).
2. **Create a new file** `SmartContractCaPay.sol` and copy the contract code.
3. **Compile the contract**:
   - In Remix, go to the `Solidity Compiler` tab.
   - Select version **0.8.26**.
   - Click `Compile SmartContractCaPay.sol`.
4. **Deploy the contract**:
   - Go to the `Deploy & Run Transactions` tab.
   - Select the environment `Injected Provider - MetaMask` or `Remix VM (London)`.
   - Deploy `SmartContractCaPay`.

## 🏗️ How to Use the Contract

### 1️⃣ Supply Funds to a Company
The company administrator can send funds to the contract using `supplyFunds(address _companyAddress)`.  
**Example**: Send `10 ETH` to `_companyAddress`.

### 2️⃣ Schedule Salary Payments
Use `schedulePayroll(address _companyAddress, address[] memory _employeeAddresses, uint _scheduledDate)`.  
**Example**: Schedule employee salary payments for a given date.

### 3️⃣ Execute Scheduled Payments
The administrator can trigger `executeScheduledPayments(address _companyAddress)`.  
**Effect**: All payments that have reached their due date will be executed.

### 4️⃣ Track Transactions
- `getCompanyTransactions(address _companyAddress)`: Returns the company's transaction history.
- `getEmployeeTransactions(address _employeeAddress)`: Returns an employee's transaction history.

## 🛡️ Security & Limitations

- **Access Control**: Only administrators can manage payments.
- **Contract Funds**: The company must ensure sufficient ETH balance for payments.
- **Testnet Deployment**: It is recommended to test on Sepolia before a real deployment.

## 📜 License

This project is licensed under the **MIT** License.

---

✨ **Developed with Solidity on Remix** ✨
