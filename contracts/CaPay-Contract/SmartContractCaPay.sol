// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Employee.sol";

contract SmartContractCaPay is Employee {
    // Constantes pour les conversions

    // Constructeur du contrat SmartContractCaPay
    constructor() Employee() { 
    }

    struct ScheduledPayment {
        address employeeAddress;
        uint scheduleDate;
    }

    struct AuditInfo {
        uint transactionId;
        uint amount;
        string status;
        string paymentType;
        uint timestamp;
    }

    // Mappings pour stocker les informations d'audit par l'entreprise et les employés
    mapping(address => ScheduledPayment[]) internal companyScheduledPayments;
    mapping(address => AuditInfo[]) internal companyAudit;
    mapping(address => AuditInfo[]) internal employeeAudit;
    mapping(address => bool) internal validCompanies;
    mapping(address => uint) internal companyBalances;
    address[] internal validCompanyList;

    // Événements pour suivre les actions importantes
    event PaymentSent(address indexed companyAddress, address indexed employeeAddress, uint amount);
    event PaymentScheduled(address indexed companyAddress, uint totalAmount, uint scheduledDate);
    event CompanyFundsSupplied(address indexed companyAddress, uint amount);
    event PaymentAudited(address indexed entity, uint transactionId, uint amount, string status, string paymentType, uint timestamp);

    // Fonction pour programmer des paiements multiples pour plusieurs employés
    function schedulePayroll(address _companyAddress, address[] memory _employeeAddresses, uint _scheduledDate) public virtual onlyAdmin(_companyAddress){
        uint totalAmount = 0;

        // Vérifier que l'entreprise existe
        require(companies[_companyAddress].existsCompany, "L'entreprise n'existe pas.");
        require(_employeeAddresses.length > 0, "Aucun employe fourni.");

        // Calculer le montant total des salaires pour tous les employés
        for (uint i = 0; i < _employeeAddresses.length; i++) {
            require(isEmployee[_employeeAddresses[i]], "L'adresse fournie n'est pas un employe.");
            totalAmount += employees[_employeeAddresses[i]].salaryAmount; // Utilisation du salaire enregistré
        }

        // Programmer les paiements pour chaque employé
        for (uint i = 0; i < _employeeAddresses.length; i++) {
            ScheduledPayment memory newPayment = ScheduledPayment({
                employeeAddress: _employeeAddresses[i],
                scheduleDate: _scheduledDate // Corrected here
            });
            companyScheduledPayments[_companyAddress].push(newPayment);
        }

        // Émettre un événement pour notifier que le paiement a été programmé
        emit PaymentScheduled(_companyAddress, totalAmount, _scheduledDate);
    }

    // Exécution des paiements programmés avec mise à jour du statut de confirmation
    function executeScheduledPayments(address _companyAddress) public virtual onlyAdmin(_companyAddress){
        uint currentTime = block.timestamp;

        // Vérifier que l'entreprise existe
        require(companies[_companyAddress].existsCompany, "L'entreprise n'existe pas.");
        // Vérifier que l'entreprise a des paiements programmés
        ScheduledPayment[] storage payments = companyScheduledPayments[_companyAddress];
        require(payments.length > 0, "Aucun paiement programme pour cette entreprise.");

        for (uint j = 0; j < payments.length;) {
            if (payments[j].scheduleDate <= currentTime) {
                uint totalPayment = employees[payments[j].employeeAddress].salaryAmount;
                uint totalPaymentInWei = totalPayment; // Already stored in Wei

                require(address(this).balance >= totalPaymentInWei, "Fonds insuffisants dans le contrat.");

                // Initiation du paiement et récupération de l'ID de la transaction
                uint transactionId = initiatePayment(
                    totalPaymentInWei,
                    payments[j].employeeAddress,
                    "SALARY"
                );

                // Transfert des fonds à l'employé
                payable(payments[j].employeeAddress).transfer(totalPaymentInWei);

                // Mise à jour du statut de confirmation de paiement
                employees[payments[j].employeeAddress].isPaymentConfirmed = true;

                // Création de l'audit
                AuditInfo memory newAudit = AuditInfo({
                    transactionId: transactionId,
                    amount: totalPaymentInWei,
                    status: "Executed",
                    paymentType: "SALARY",
                    timestamp: block.timestamp
                });

                // Enregistrer l'audit
                companyAudit[_companyAddress].push(newAudit);
                employeeAudit[payments[j].employeeAddress].push(newAudit);

                // Émettre un événement pour notifier l'exécution
                emit PaymentSent(_companyAddress, payments[j].employeeAddress, totalPaymentInWei);

                // Supprimer le paiement programmé
                payments[j] = payments[payments.length - 1];
                payments.pop();
            } else {
                j++; // Incrémenter si non exécuté
            }
        }
    }

    // Fonction pour initier un paiement et générer un ID de transaction unique
    function initiatePayment(uint _amount, address _employeeAddress, string memory _paymentType) 
        internal view returns (uint) {
        // Générer un ID de transaction unique basé sur les paramètres et le timestamp
        uint transactionId = uint(keccak256(abi.encodePacked(block.timestamp, _employeeAddress, _amount, _paymentType)));
        return transactionId;
    }

    // Fonction pour approvisionner les fonds d'une entreprise (par l'administrateur de l'entreprise)
    function supplyFunds(address _companyAddress) public payable onlyAdmin(_companyAddress) {
        require(companies[_companyAddress].existsCompany, "L'entreprise n'existe pas.");
        require(msg.value > 0, "Le montant doit etre superieur a zero.");

        // Enregistrer les fonds dans le solde de l'entreprise
        companyBalances[_companyAddress] += msg.value;

        // Émettre un événement pour notifier que des fonds ont été fournis
        emit CompanyFundsSupplied(_companyAddress, msg.value);
    }

    // Fonction pour formater une transaction en chaîne de caractères
    function formatTransaction(AuditInfo memory transaction) internal pure returns (string memory) {
        return string(abi.encodePacked(
            ", Montant: ", uint2str(transaction.amount), 
            " FCFA, Statut: ", transaction.status,
            ", Date: ", uint2str(transaction.timestamp)
        ));
    }

    // Fonction pour obtenir toutes les transactions d'une entreprise
    function getCompanyTransactions(address _companyAddress) public view returns (string[] memory) {
        require(companies[_companyAddress].existsCompany, "L'entreprise n'existe pas.");

        AuditInfo[] memory transactions = companyAudit[_companyAddress];
        string[] memory formattedTransactions = new string[](transactions.length);
    
        for (uint i = 0; i < transactions.length; i++) {
            formattedTransactions[i] = formatTransaction(transactions[i]);
        }
    
        return formattedTransactions;
    }

    // Fonction pour obtenir toutes les transactions d'un employé spécifique
    function getEmployeeTransactions(address _employeeAddress) public view returns (string[] memory) {
        require(isEmployee[_employeeAddress], "L'employe n'est pas valide.");

        AuditInfo[] memory transactions = employeeAudit[_employeeAddress];
        string[] memory formattedTransactions = new string[](transactions.length);

        for (uint i = 0; i < transactions.length; i++) {
            formattedTransactions[i] = formatTransaction(transactions[i]);
        }

        return formattedTransactions;
    }

    // Fonction pour convertir une adresse en chaîne de caractères
    function toString(address x) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(x);
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            bytes1 b = data[i];
            uint8 hi = uint8(b) / 16;
            uint8 lo = uint8(b) - 16 * hi;
            str[2 * i + 2] = char(hi);
            str[2 * i + 3] = char(lo);
        }
       return string(str);
    }

    // Fonction pour convertir un entier en chaîne de caractères
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Fonction pour convertir un nombre hexadécimal en caractère
    function char(uint8 b) internal pure returns (bytes1 c) {
        if (b < 10) {
            return bytes1(b + 0x30);
        } else {
            return bytes1(b + 0x57);
    }
}


    


}
